import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).parent
commands = [
    ['moon', 'version', '--all'],
    ['moon', 'check', '--target', 'all', '--deny-warn'],
    ['moon', 'fmt', '--check'],
    ['moon', 'test', '--target', 'wasm-gc', '--deny-warn'],
    ['moon', 'test', '--target', 'js', '--deny-warn'],
    ['moon', 'run', 'cmd/demo', '--target', 'js'],
]
results = []
for command in commands:
    result = subprocess.run(command, cwd=root, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60)
    entry = {'command': command, 'returncode': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}
    results.append(entry)
    print(' '.join(command), '=>', result.returncode)
    if result.returncode:
        break
out = root / 'artifacts'
out.mkdir(exist_ok=True)
(out / 'validation.json').write_text(json.dumps({'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'status': 'local feasibility only', 'results': results}, ensure_ascii=False, indent=2), encoding='utf-8')
sys.exit(0 if len(results) == len(commands) and all(x['returncode'] == 0 for x in results) else 1)
