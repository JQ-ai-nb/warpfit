"""Integration boundaries for the external-package validation command."""
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT/"work"
WORK.mkdir(exist_ok=True)
VERSION = re.search(r'^version\s*=\s*"([^"]+)"', (ROOT/"moon.mod").read_text(encoding="utf-8"), re.M)[1]


def call(*args):
    return subprocess.run([sys.executable, "scripts/registry_consumer.py", *args],
                          cwd=ROOT, capture_output=True, text=True, encoding="utf-8", timeout=30)


class ConsumerBoundaries(unittest.TestCase):
    def test_manifest_fragment_is_rejected_before_any_consumer_is_created(self):
        before = set(WORK.glob("consumer-*"))
        result = call("--version", '0.2.0"\nname = "unexpected/module"')
        self.assertEqual(result.returncode, 2)
        self.assertIn("Version must be a semantic version", result.stderr)
        self.assertEqual(set(WORK.glob("consumer-*")), before)

    def test_archive_version_must_match_even_when_workspace_ignores_selector(self):
        archive = ROOT/"_build/publish"/f"JQ-ai-nb-warpfit-{VERSION}.zip"
        self.assertTrue(archive.is_file(), "Run scripts/package_check.py first")
        result = call("--archive", str(archive), "--version", "999.0.0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Archive version differs", result.stderr)
        self.assertNotIn("warpfit_consumer_ok:", result.stdout)

    def test_archive_cannot_write_outside_its_extraction_directory(self):
        folder = Path(tempfile.mkdtemp(prefix="consumer-negative-", dir=WORK))
        self.assertTrue(folder.resolve().is_relative_to(WORK.resolve()))
        archive = folder/"traversal.zip"
        with ZipFile(archive, "w") as package:
            package.writestr("../outside-extraction.txt", "must not be extracted")
        before = set(WORK.glob("consumer-package_archive-*"))
        result = call("--archive", str(archive))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsafe archive entry", result.stderr)
        for session in set(WORK.glob("consumer-package_archive-*")) - before:
            self.assertFalse((session/"outside-extraction.txt").exists())
        archive.unlink()
        folder.rmdir()


if __name__ == "__main__":
    unittest.main()
