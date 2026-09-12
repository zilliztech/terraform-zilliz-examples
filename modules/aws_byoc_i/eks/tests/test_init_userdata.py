import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "locals.tf"


class InitUserdataTest(unittest.TestCase):
    def run_userdata(self, subnets):
        source = SOURCE.read_text()
        start = source.index("SUBNET_IDS='")
        end = source.index("--==MYBOUNDARY==--", start)
        script = source[start:end].replace(
            '${join(" ", var.customer_pod_subnet_ids)}', subnets
        ).replace("${var.region}", "us-west-2").replace("${local.boot_config_json}", "{}")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for command in ("aws", "ctr"):
                mock = root / command
                mock.write_text(
                    '#!/bin/bash\nprintf "%s %s\\n" "${0##*/}" "$*" >> "$CALL_LOG"\n'
                    'if [ "$1 $2" = "ec2 describe-subnets" ]; then printf "us-west-2a\\n"; fi\n'
                    'if [ "$1 $2" = "ecr get-login-password" ]; then printf "test-password\\n"; fi\n'
                )
                mock.chmod(0o755)
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                       CALL_LOG=str(root / "calls"), ZILLIZ_BYOC_IMAGE="test-booter:latest")
            result = subprocess.run(["bash", "-c", script], env=env, cwd=root,
                                    capture_output=True, text=True)
            calls = (root / "calls").read_text() if (root / "calls").exists() else ""
            return result, calls

    def test_empty_subnets_still_run_init_booter(self):
        result, calls = self.run_userdata("")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("ec2 describe-subnets", calls)
        self.assertIn("ctr image pull", calls)
        self.assertIn("--env IS_INIT=true", calls)
        self.assertIn("--env POD_SUBNET_IDS=", calls)
        self.assertIn("test-booter:latest zilliz-bootstrap", calls)

    def test_custom_subnets_resolve_azs_and_run_init_booter(self):
        result, calls = self.run_userdata("subnet-a subnet-b")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls.count("ec2 describe-subnets"), 2)
        self.assertIn("--env POD_SUBNET_IDS=subnet-a subnet-b", calls)
        self.assertIn("--env SUBNET_AZS=us-west-2a us-west-2a", calls)
        self.assertIn("test-booter:latest zilliz-bootstrap", calls)


if __name__ == "__main__":
    unittest.main()
