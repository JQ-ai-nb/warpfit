"""Compare subsequence DTW with tslearn; optional independent test dependency."""
import json
import math
import os
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone

deps = os.environ.get("WARPFIT_REFERENCE_DEPS")
if deps:
    sys.path.insert(0, deps)
import numpy as np
import tslearn
from tslearn.metrics import dtw_subsequence_path

root = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(20261113)
requests = []
reference = []
for _ in range(120):
    n = int(rng.integers(1, 9))
    m = int(rng.integers(1, 13))
    dimensions = int(rng.integers(1, 4))
    query = rng.normal(size=(n, dimensions))
    target = rng.normal(size=(m, dimensions))
    weights = rng.choice([0.0, 0.5, 2.0], size=dimensions)
    if not np.any(weights):
        weights[0] = 1.0
    path, distance = dtw_subsequence_path(query * np.sqrt(weights), target * np.sqrt(weights))
    requests.append(dict(schema="warpfit.request/1", operation="subsequence",
                         query=query.tolist(), target=target.tolist(),
                         options=dict(feature_weights=weights.tolist())))
    reference.append((float(distance), int(path[-1][1])))
driver = """import {readFileSync} from 'node:fs';
import {run} from './dist/engine.mjs';
const rows=JSON.parse(readFileSync(0,'utf8'));
for (const row of rows) console.log(run(JSON.stringify(row)));"""
process = subprocess.run(['node','--input-type=module','-e',driver], cwd=root,
                         input=json.dumps(requests), capture_output=True, text=True,
                         encoding='utf-8', check=True, timeout=120)
actual = [json.loads(line) for line in process.stdout.splitlines()]
assert len(actual) == len(reference)
maximum = 0.0
for result, (distance, end) in zip(actual, reference):
    assert result['ok'], result
    error = abs(result['distance'] - distance)
    maximum = max(maximum, error)
    assert math.isclose(result['distance'], distance, rel_tol=1e-9, abs_tol=1e-9), (result, distance)
    assert result['end'] == end, (result['end'], end)
report = dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(),
              reference='tslearn', reference_version=tslearn.__version__,
              cases=len(reference), max_absolute_distance_error=maximum,
              checked='distance and earliest end; tied predecessor paths may differ',
              status='passed')
(root/'artifacts').mkdir(exist_ok=True)
(root/'artifacts/subsequence-reference.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
