"""Run real local checks and retain complete command results outside source."""
import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--native', action='store_true', help='Also test/build native; needs a configured C compiler')
args = parser.parse_args()
targets = ['wasm', 'wasm-gc', 'js'] + (['native'] if args.native else [])
commands = [
    ['moon', 'version', '--all'],
    ['moon', 'check', '--target', 'all', '--deny-warn'],
    ['moon', 'fmt', '--check'],
    ['moon', 'info'],
    ['git', 'diff', '--exit-code', '--', '*.mbti'],
]
for target in targets:
    commands += [['moon', 'test', '--target', target, '--deny-warn'],
                 ['moon', 'build', '--target', target, '--deny-warn']]
commands += [
    ['moon', 'run', 'cmd/demo', '--target', 'js'],
    ['moon', 'run', 'cmd/calibrate', '--target', 'js'],
    ['moon', 'run', 'cmd/series_pipeline', '--target', 'js'],
    ['node', 'scripts/build.mjs'],
    ['node', '--test', 'tests/cli.test.mjs', 'tests/numerical.test.mjs',
     'tests/extended.test.mjs', 'tests/exhaustive_hard.test.mjs', 'tests/properties_hard.test.mjs',
     'tests/uci_room.test.mjs', 'tests/long_input.test.mjs', 'tests/model.test.mjs',
     'tests/model_cli.test.mjs', 'tests/subsequence.test.mjs', 'tests/distance_only.test.mjs',
     'tests/auto_model.test.mjs'],
    [sys.executable, 'scripts/package_check.py'],
]
results = []
for command in commands:
    result = subprocess.run(command, cwd=root, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
    entry = {'command': command, 'returncode': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}
    results.append(entry)
    print(' '.join(command), '=>', result.returncode, flush=True)
    if result.returncode:
        print(result.stdout, result.stderr)
        break
out = root / 'artifacts'
out.mkdir(exist_ok=True)
passed = len(results) == len(commands) and all(x['returncode'] == 0 for x in results)
(out / 'validation.json').write_text(json.dumps({'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'status': 'passed' if passed else 'failed', 'runtime_targets': targets,
    'not_checked': [] if args.native else ['native runtime: C toolchain required; use --native'],
    'results': results}, ensure_ascii=False, indent=2), encoding='utf-8')
sys.exit(0 if passed else 1)
