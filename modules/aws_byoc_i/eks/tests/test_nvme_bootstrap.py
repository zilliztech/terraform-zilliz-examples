"""Offline lifecycle tests; all disk commands and absolute paths are sandboxed."""
import base64
import email
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[1]
SCRIPT = MODULE / "scripts/mount-nvme.sh"

MOCK = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

command = Path(sys.argv[0]).name
state_file = Path(os.environ["NVME_TEST_STATE"])
state = json.loads(state_file.read_text())
state["calls"].append(command)
status = 0
if command == state.get("fail"):
    status = 1
elif command == "lsblk":
    print(json.dumps({"blockdevices": [
        {"name": "nvme0n1", "model": "Amazon Elastic Block Store"},
        *[{"name": f"nvme{i+1}n1", "model": "Amazon EC2 NVMe Instance Storage"}
          for i in range(state["disks"])]]}))
elif command == "blkid":
    if state["filesystem"]:
        print(state["filesystem"])
    else:
        status = 2
elif command == "mkfs.xfs":
    state["filesystem"] = "xfs"
elif command == "mountpoint":
    status = 0 if state["mounted"] else 1
elif command == "mount":
    state["mounted"] = True
elif command == "findmnt":
    print(state.get("source", "/dev/nvme1n1"))
state_file.write_text(json.dumps(state))
sys.exit(status)
'''


class NvmeBootstrapTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nvme-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.data = self.root / "mnt/data"
        self.lib = self.root / "var/lib"
        self.lib.mkdir(parents=True)
        self.state_file = self.root / "state.json"
        self.write_state(disks=1, filesystem="", mounted=False, calls=[])
        commands = self.root / "bin"
        commands.mkdir()
        for name in ("lsblk", "blkid", "mkfs.xfs", "mountpoint", "mount", "findmnt"):
            path = commands / name
            path.write_text(MOCK)
            path.chmod(0o755)
        self.script = self.root / "mount-nvme.sh"
        self.script.write_text(SCRIPT.read_text().replace("/mnt/data", str(self.data))
                               .replace("/var/lib", str(self.lib)))
        self.env = dict(os.environ, PATH=f"{commands}:{os.environ['PATH']}",
                        NVME_TEST_STATE=str(self.state_file))

    def write_state(self, **values):
        state = json.loads(self.state_file.read_text()) if self.state_file.exists() else {}
        state.update(values)
        self.state_file.write_text(json.dumps(state))

    def state(self):
        return json.loads(self.state_file.read_text())

    def boot(self, success=True):
        result = subprocess.run(["bash", str(self.script)], env=self.env,
                                capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((self.data / ".initialized").exists())
        return result

    def test_first_boot_migrates_data_and_marks_success(self):
        (self.lib / "kubelet").mkdir()
        (self.lib / "kubelet/config").write_text("existing kubelet state")
        self.boot()
        self.assertEqual((self.data / "kubelet/config").read_text(), "existing kubelet state")
        for name in ("kubelet", "docker"):
            self.assertTrue((self.lib / name).is_symlink())
            self.assertTrue((self.lib / name).is_dir())
        self.assertTrue((self.data / ".initialized").exists())
        self.assertEqual(self.state()["calls"].count("mkfs.xfs"), 1)

    def test_reboot_mounts_before_marker_without_formatting(self):
        self.boot()
        (self.data / "kubelet/cache").write_text("keep")
        self.write_state(mounted=False, calls=[])
        self.boot()
        self.assertIn("mount", self.state()["calls"])
        self.assertNotIn("mkfs.xfs", self.state()["calls"])
        self.assertEqual((self.data / "kubelet/cache").read_text(), "keep")
        self.write_state(calls=[])
        self.boot()
        self.assertNotIn("mount", self.state()["calls"])

    def test_two_stop_start_cycles_recreate_symlink_targets(self):
        self.boot()
        for cycle in range(2):
            # Move old contents aside to simulate discarded instance storage.
            self.data.rename(self.root / f"discarded-{cycle}")
            self.write_state(filesystem="", mounted=False, calls=[])
            self.boot()
            self.assertEqual(self.state()["calls"].count("mkfs.xfs"), 1)
            self.assertTrue((self.data / ".initialized").exists())
            for name in ("kubelet", "docker"):
                self.assertTrue((self.lib / name).is_dir())

    def test_existing_xfs_without_marker_is_not_formatted(self):
        self.write_state(filesystem="xfs")
        self.boot()
        self.assertNotIn("mkfs.xfs", self.state()["calls"])

    def test_disk_selection_and_filesystem_fail_closed(self):
        for count, filesystem in ((0, ""), (2, ""), (1, "ext4")):
            with self.subTest(count=count, filesystem=filesystem):
                self.write_state(disks=count, filesystem=filesystem, calls=[])
                self.boot(success=False)
                self.assertNotIn("mkfs.xfs", self.state()["calls"])
                self.assertNotIn("mount", self.state()["calls"])

    def test_command_failures_do_not_write_marker_and_can_retry(self):
        for command in ("lsblk", "blkid", "mkfs.xfs", "mount", "findmnt"):
            with self.subTest(command=command):
                self.write_state(filesystem="", mounted=False, fail=command, calls=[])
                self.boot(success=False)
        self.write_state(fail=None, mounted=False)
        self.boot()
        self.assertTrue((self.data / ".initialized").exists())

    def test_unexpected_mount_is_rejected(self):
        self.write_state(filesystem="xfs", mounted=True, source="/dev/nvme0n1")
        self.boot(success=False)

    def test_partial_initialization_can_retry(self):
        self.data.mkdir(parents=True)
        (self.data / "kubelet").mkdir()
        self.write_state(filesystem="xfs", mounted=True)
        self.boot()
        self.assertTrue((self.lib / "kubelet").is_dir())
        self.assertTrue((self.data / ".initialized").exists())

    def test_conflicting_directory_is_not_overwritten(self):
        (self.lib / "kubelet").mkdir()
        (self.data / "kubelet").mkdir(parents=True)
        self.boot(success=False)
        self.assertFalse((self.lib / "kubelet").is_symlink())

    def test_unexpected_symlink_is_rejected(self):
        (self.lib / "kubelet").symlink_to(self.root / "unexpected")
        self.boot(success=False)


class UserDataTest(unittest.TestCase):
    def test_terraform_rendered_mime_and_boot_order(self):
        terraform = shutil.which("terraform")
        self.assertIsNotNone(terraform, "terraform is required to test template rendering")
        source = (MODULE / "eks_nodegroup.tf").read_text()
        diskann = source.split('resource "aws_launch_template" "diskann" {', 1)[1]
        template = diskann.split("<<-USERDATA\n", 1)[1].split("\nUSERDATA", 1)[0]
        with tempfile.TemporaryDirectory(prefix="nvme-render-") as directory:
            path = Path(directory) / "userdata.tftpl"
            path.write_text(template)
            locals_source = (MODULE / "locals.tf").read_text()
            bootstrap = locals_source.split("eks_bootstrap_mime_part = <<-EOF\n", 1)[1].split("\nEOF", 1)[0]
            bootstrap = bootstrap.replace("${local.eks_cluster_name}", "test-cluster")
            for custom_ami in (False, True):
                with self.subTest(custom_ami=custom_ami):
                    variables = {"path": {"module": str(MODULE)},
                                 "local": {"eks_bootstrap": bootstrap if custom_ami else ""}}
                    expression = f"base64encode(templatefile({json.dumps(str(path))}, {json.dumps(variables)}))\n"
                    result = subprocess.run([terraform, "console"], input=expression,
                                            cwd=directory, text=True, capture_output=True, check=True)
                    rendered = base64.b64decode(json.loads(result.stdout)).decode()
                    message = email.message_from_string(rendered)
                    parts = message.get_payload()
                    self.assertEqual(len(parts), 2 if custom_ami else 1)
                    for part in parts:
                        self.assertEqual(part.get_content_type(), "text/x-shellscript")
                        subprocess.run(["bash", "-n"], input=part.get_payload(), text=True, check=True)
                    shell = parts[0].get_payload()
                    self.assertIn(SCRIPT.read_text(), shell)
                    self.assertNotIn("/etc/fstab", shell)
                    self.assertNotIn("$$UUID", shell)
                    self.assertIn("Requires=zilliz-mount-nvme.service", shell)
                    self.assertIn("After=zilliz-mount-nvme.service", shell)
                    self.assertIn("Before=nodeadm-config.service kubelet.service containerd.service docker.service", shell)
                    self.assertIn("systemctl enable --now zilliz-mount-nvme.service", shell)
                    if custom_ami:
                        self.assertIn("/etc/eks/bootstrap.sh 'test-cluster'", parts[1].get_payload())



if __name__ == "__main__":
    unittest.main()
