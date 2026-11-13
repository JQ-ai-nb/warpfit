"""Run the public 0.2 API as a separate consumer module.

Default: install the exact version from Mooncakes (no path dependency).
--packaged / --archive: use the real local package archive before publication.
Archive mode never claims registry installation has been verified.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent.parent
MODULE = "JQ-ai-nb/warpfit"
MARKER = "warpfit_consumer_ok:"
CHECKS = ["dtw", "distance_only", "dba", "cluster_model", "subsequence", "long_preprocess", "soft_gradient", "fit_rank"]


def main() -> int:
    metadata = (ROOT/"moon.mod").read_text(encoding="utf-8")
    source_version = re.search(r'^version\s*=\s*"([^"]+)"', metadata, re.M)[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", default=os.environ.get("WARPFIT_RELEASE_VERSION", source_version))
    parser.add_argument("--native", action="store_true", help="Also run native; needs a C toolchain")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--packaged", action="store_true", help="Use _build/publish archive for the selected version")
    group.add_argument("--archive", type=Path, help="Use this actual package ZIP; no registry installation")
    args = parser.parse_args()
    if not re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?', args.version):
        parser.error("Version must be a semantic version without whitespace or manifest syntax")
    if tuple(map(int, args.version.split("-")[0].split("+")[0].split("."))) < (0, 2, 0):
        parser.error("This consumer checks the 0.2 interfaces; older versions need their historical consumer")
    archive = ROOT/"_build/publish"/f"JQ-ai-nb-warpfit-{args.version}.zip" if args.packaged else args.archive
    mode = "package_archive" if archive else "registry"
    work = ROOT/"work"
    work.mkdir(exist_ok=True)
    session = Path(tempfile.mkdtemp(prefix=f"consumer-{mode}-", dir=work))
    consumer = session/"app"
    consumer.mkdir()
    archive_hash = None
    if archive:
        archive = archive.resolve(strict=True)
        archive_hash = hashlib.sha256(archive.read_bytes()).hexdigest()
        extracted = session/"package"
        extracted.mkdir()
        with ZipFile(archive) as package:
            for entry in package.infolist():
                target = extracted/entry.filename
                if not target.resolve().is_relative_to(extracted.resolve()) or stat.S_ISLNK(entry.external_attr >> 16):
                    raise ValueError("Package contains an unsafe archive entry")
            package.extractall(extracted)
        manifest = extracted/"moon.mod"
        if not manifest.is_file():
            raise ValueError("Package must contain a root moon.mod")
        packaged_metadata = manifest.read_text(encoding="utf-8")
        if re.search(r'^name\s*=\s*"([^"]+)"', packaged_metadata, re.M)[1] != MODULE:
            raise ValueError("Archive module does not match the expected namespace")
        if re.search(r'^version\s*=\s*"([^"]+)"', packaged_metadata, re.M)[1] != args.version:
            raise ValueError("Archive version differs from the requested version")
        # Current MoonBit uses a workspace for local module dependencies.
        # The package metadata above must match before workspace resolution,
        # which otherwise ignores the dependency's registry version selector.
        (session/"moon.work").write_text('members = ["app", "package"]\n', encoding="utf-8")
    (consumer/"moon.mod").write_text(
        'name = "JQ-ai-nb/warpfit-consumer-check"\nversion = "0.0.0"\n'
        f'import {{ "{MODULE}@{args.version}" }}\n', encoding="utf-8")
    if not archive:
        # Stop an enclosing monorepo workspace from replacing the registry
        # dependency with this source checkout. Only the consumer is a member.
        (session/"moon.work").write_text('members = ["app"]\n', encoding="utf-8")
    (consumer/"moon.pkg").write_bytes((ROOT/"cmd/consumer/moon.pkg").read_bytes())
    (consumer/"main.mbt").write_bytes((ROOT/"cmd/consumer/main.mbt").read_bytes())
    targets = ["wasm", "wasm-gc", "js"] + (["native"] if args.native else [])
    # A path-only archive consumer has no registry dependencies to update.
    # Frozen mode prevents it from refreshing registry indexes or downloads.
    frozen = ["--frozen"] if archive else []
    commands = [["moon", "version", "--all"]]
    if not archive:
        commands.append(["moon", "update"])
    commands.append(["moon", "check", "--target", "all", "--deny-warn", *frozen])
    commands += [["moon", "run", ".", "--target", target, "--deny-warn", *frozen] for target in targets]
    results = []
    for command in commands:
        try:
            process = subprocess.run(command, cwd=consumer, capture_output=True, text=True,
                                     encoding="utf-8", errors="replace", timeout=180)
            result = dict(command=command, returncode=process.returncode,
                          stdout=process.stdout, stderr=process.stderr)
        except subprocess.TimeoutExpired:
            result = dict(command=command, returncode=124, stdout="", stderr="Consumer command timed out after 180 seconds")
        except OSError as error:
            result = dict(command=command, returncode=127, stdout="", stderr=str(error))
        results.append(result)
        print(" ".join(command), "=>", result["returncode"], flush=True)
        if result["returncode"]:
            print(result["stdout"].encode("ascii", "backslashreplace").decode(),
                  result["stderr"].encode("ascii", "backslashreplace").decode())
            break
    passed = len(results) == len(commands) and all(row["returncode"] == 0 for row in results)
    passed = passed and all(MARKER in row["stdout"] for row in results if row["command"][:2] == ["moon", "run"])
    report = dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(), module=MODULE,
                  version=args.version, mode=mode, path_dependency=bool(archive),
                  archive_sha256=archive_hash, runtime_targets=targets,
                  registry_install_verified=passed and not archive,
                  source_checkout_dependency=False, checks=CHECKS, results=results,
                  dependency_sync="frozen_local_workspace" if archive else "registry_update",
                  status="passed" if passed else "failed")
    artifacts = ROOT/"artifacts"
    artifacts.mkdir(exist_ok=True)
    (artifacts/f"consumer-{mode}.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(f"{mode} consumer: {report['status']}; registry install verified: {report['registry_install_verified']}", flush=True)
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
