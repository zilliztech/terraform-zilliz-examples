"""Offline tests for environment-aware BYOC booter image selection."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1]
LOCALS = MODULE / "locals.tf"


def local_expression(source, name):
    match = re.search(rf"^\s*{name}\s*=\s*(.+)$", source, re.MULTILINE)
    if not match:
        raise AssertionError(f"local {name} not found")
    return match.group(1)


class BooterEnvironmentTest(unittest.TestCase):
    def test_default_repository_tracks_environment_and_allows_override(self):
        terraform = shutil.which("terraform")
        self.assertIsNotNone(terraform, "terraform is required")
        source = LOCALS.read_text()
        default_expression = local_expression(source, "default_booter_ecr_image")
        selected_expression = local_expression(source, "booter_ecr_image")
        default_expression = default_expression.replace("var.env", "local.env")
        selected_expression = selected_expression.replace("var.booter.image", "local.booter_image")

        cases = [
            ("UAT", "", "infra/uat-byoc-booter"),
            (" uat ", "", "infra/uat-byoc-booter"),
            ("Production", "", "infra/byoc-booter"),
            ("PROD", "", "infra/byoc-booter"),
            ("", "", "infra/byoc-booter"),
            ("UAT", "infra/custom-booter", "infra/custom-booter"),
            ("Production", "infra/custom-booter", "infra/custom-booter"),
        ]
        for env, override, expected in cases:
            with self.subTest(env=env, override=override), tempfile.TemporaryDirectory() as directory:
                config = f'''locals {{
  env = {json.dumps(env)}
  booter_image = {json.dumps(override)}
  default_booter_ecr_image = {default_expression}
  booter_ecr_image = {selected_expression}
}}
'''
                Path(directory, "main.tf").write_text(config)
                result = subprocess.run(
                    [terraform, "console"],
                    cwd=directory,
                    input="jsonencode(local.booter_ecr_image)\n",
                    text=True,
                    capture_output=True,
                    check=True,
                )
                self.assertEqual(json.loads(json.loads(result.stdout)), expected)

    def test_both_bootstrap_paths_use_environment_default(self):
        source = LOCALS.read_text()
        self.assertEqual(
            source.count("--repository-name zilliz-byoc/${local.default_booter_ecr_image}"),
            2,
        )
        self.assertEqual(
            source.count("amazonaws.com/zilliz-byoc/${local.default_booter_ecr_image}:$DEFAULT_TAG"),
            2,
        )
        self.assertNotIn("${local.booter_ecr_account_id} == \"965570967084\"", source)


if __name__ == "__main__":
    unittest.main()
