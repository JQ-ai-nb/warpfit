"""Build a local runtime ZIP, then verify only the extracted files with no SDK on PATH."""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent.parent
EXAMPLES = [
    'align', 'dba', 'clusters', 'pipeline', 'model_train', 'model_predict_data',
    'subsequence', 'prototype', 'training', 'retrieval', 'uci-room',
    'uci-model-train', 'uci-model-test-data', 'uci-model-split', 'knn', 'select-k',
]
WEB_EXAMPLES = ['prototype', 'training', 'retrieval', 'align', 'dba', 'clusters',
                'pipeline', 'uci-room', 'model_train', 'subsequence', 'knn', 'select-k']
NOTICES = ['MOONBIT_CORE_LICENSE', 'MOONBIT_CORE_NOTICE', 'WARPFIT_LICENSE']


def run(command, **kwargs):
    return subprocess.run(command, cwd=ROOT, check=True, capture_output=True,
                          text=True, encoding='utf-8', errors='replace', timeout=180, **kwargs)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    metadata = json.loads((ROOT / 'package.json').read_text(encoding='utf-8'))
    version = metadata['version']
    assert re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version), 'Unexpected version'
    module = (ROOT / 'moon.mod').read_text(encoding='utf-8')
    assert re.search(r'^name\s*=\s*"JQ-ai-nb/warpfit"\s*$', module, re.M)
    assert re.search(r'^version\s*=\s*"' + re.escape(version) + r'"\s*$', module, re.M)
    # The workbench and the bundle must expose the same scenarios: stop with a
    # non-zero exit instead of silently shipping a subset of web/examples.
    on_disk = sorted(path.stem for path in (ROOT / 'web/examples').glob('*.json'))
    declared = sorted(WEB_EXAMPLES)
    if on_disk != declared:
        raise SystemExit('web/examples mismatch: missing={} unexpected={}'.format(
            sorted(set(declared) - set(on_disk)), sorted(set(on_disk) - set(declared))))
    node = shutil.which('node')
    if node is None:
        raise RuntimeError('Node.js >=22 is required.')
    node = str(Path(node).resolve())
    node_version = run([node, '--version']).stdout.strip()
    assert int(node_version.removeprefix('v').split('.')[0]) >= 22, node_version
    run([node, 'scripts/build.mjs'])

    paths = [
        'LICENSE', 'THIRD_PARTY_NOTICES.md', 'docs/REAL_DATA.md', 'docs/SEMANTICS.md',
        'bin/warpfit.mjs', 'bin/warpfit-model.mjs', 'scripts/serve.mjs',
        'scripts/evaluate_holdout.mjs', 'scripts/check_demo.mjs',
        'dist/engine.mjs', 'web/index.html', 'web/style.css', 'web/app.mjs',
        'web/worker.mjs', 'web/engine.mjs', 'web/UCI_ROOM_DATA_NOTICE.md',
    ]
    paths += [f'{directory}/{name}' for directory in ['dist', 'web'] for name in NOTICES]
    paths += [f'examples/{name}.json' for name in EXAMPLES]
    paths += [f'web/examples/{name}.json' for name in WEB_EXAMPLES]
    files = {}
    for name in paths:
        path = ROOT / name
        assert path.is_file() and not path.is_symlink(), name
        assert path.resolve().is_relative_to(ROOT), name
        files[name] = path.read_bytes()
    files['README.md'] = (ROOT / 'docs/DEMO.md').read_bytes()
    files['package.json'] = (json.dumps({
        'name': 'warpfit-local-demo', 'version': version, 'private': True,
        'type': 'module', 'engines': {'node': '>=22'},
        'scripts': {'test': 'node scripts/check_demo.mjs', 'start': 'node scripts/serve.mjs'},
    }, indent=2) + '\n').encode()
    for name, data in files.items():
        assert not re.search(rb'\b[0-9]{5,12}@qq\.com\b', data), name
        assert not re.search(rb'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b', data), name
    manifest = {
        'schema': 'warpfit.demo-bundle/1', 'kind': 'local_preview_not_published_release',
        'module': 'JQ-ai-nb/warpfit', 'version': version,
        'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
        'source_commit': run(['git', 'rev-parse', 'HEAD']).stdout.strip(),
        'source_dirty': bool(run(['git', 'status', '--porcelain']).stdout.strip()),
        'build_node': node_version,
        'build_moon': run(['moon', 'version', '--all']).stdout.strip(),
        'files': [{'path': name, 'bytes': len(data), 'sha256': digest(data)}
                  for name, data in sorted(files.items())],
    }
    files['DEMO_MANIFEST.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
    output = ROOT / 'deliverables'
    output.mkdir(exist_ok=True)
    prefix = f'WarpFit-demo-{version}'
    archive = output / f'{prefix}.zip'
    # Create a new archive beside the target and replace only our own ZIP.
    fd, temporary_name = tempfile.mkstemp(prefix='demo-build-', suffix='.zip', dir=output)
    os.close(fd)
    temporary = Path(temporary_name)
    try:
        with ZipFile(temporary, 'w', compression=ZIP_DEFLATED) as package:
            for name, data in sorted(files.items()):
                package.writestr(f'{prefix}/{name}', data)
        temporary.replace(archive)
    finally:
        temporary.unlink(missing_ok=True)

    work = ROOT / 'work'
    work.mkdir(exist_ok=True)
    extracted = Path(tempfile.mkdtemp(prefix='demo-extracted-', dir=work))
    with ZipFile(archive) as package:
        package.extractall(extracted)  # Names were constructed only from the explicit allowlist above.
    runtime = extracted / prefix
    empty_path = extracted / 'empty-path'
    empty_path.mkdir()
    environment = {**os.environ, 'PATH': str(empty_path), 'WARPFIT_REQUIRE_NO_SDK': '1'}
    checked = subprocess.run([node, 'scripts/check_demo.mjs'], cwd=runtime, env=environment,
                             capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
    check_path = runtime / 'artifacts/demo-check.json'
    verification = json.loads(check_path.read_text(encoding='utf-8')) if check_path.exists() else None
    report = {
        'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
        'status': 'passed' if checked.returncode == 0 and verification and verification['status'] == 'passed' else 'failed',
        'module': manifest['module'], 'version': version, 'archive': str(archive),
        'archive_sha256': digest(archive.read_bytes()), 'archive_bytes': archive.stat().st_size,
        'file_count': len(files), 'source_commit': manifest['source_commit'],
        'source_dirty': manifest['source_dirty'], 'extracted_directory': str(runtime),
        'command': [node, 'scripts/check_demo.mjs'], 'returncode': checked.returncode,
        'path_is_empty_directory': True, 'verification': verification, 'stderr': checked.stderr,
        'publication_performed': False, 'registry_install_verified': False,
    }
    (ROOT / 'artifacts').mkdir(exist_ok=True)
    (ROOT / 'artifacts/demo-package.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f"Demo bundle: {report['status']}; {len(files)} files; {len(verification['checks']) if verification else 0} check groups; Node {node_version}")
    print(f'Archive: {archive}')
    print(f'SHA256: {report["archive_sha256"]}')
    if report['status'] != 'passed':
        print(checked.stdout, checked.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
