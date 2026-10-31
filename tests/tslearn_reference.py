"""Optional reference validation, not a runtime dependency. No upstream code copied.

Install isolated: python -m pip install --target work/reference-deps tslearn==0.6.4
Run: python tests/tslearn_reference.py
"""
import json
import os
import random
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parent.parent
if (root/'work/reference-deps').exists(): sys.path.insert(0,str(root/'work/reference-deps'))
import numpy as np
import tslearn
from tslearn.metrics import soft_dtw_alignment

rng = random.Random(1031)
requests, references = [], []
def raw(x,y,gamma,w):
    # Weighted Euclidean cost is Euclidean after scaling axes by sqrt(w).
    sx, sy = x*np.sqrt(w), y*np.sqrt(w)
    occupancy, value = soft_dtw_alignment(sx,sy,gamma=gamma)
    delta = x[:,None,:] - y[None,:,:]
    gx = (2*occupancy[:,:,None]*delta*w).sum(axis=1)
    gy = -(2*occupancy[:,:,None]*delta*w).sum(axis=0)
    return value,gx,gy,occupancy

for _ in range(60):
    n,m,d = rng.randint(1,14),rng.randint(1,14),rng.randint(1,4)
    x = np.array([[rng.uniform(-2,2) for _ in range(d)] for _ in range(n)])
    y = np.array([[rng.uniform(-2,2) for _ in range(d)] for _ in range(m)])
    w = np.array([rng.choice([.2,1,2]) for _ in range(d)]); gamma = rng.choice([.1,.4,1,3])
    xy,xx,yy = raw(x,y,gamma,w),raw(x,x,gamma,w),raw(y,y,gamma,w)
    for objective in ['raw','corrected']:
        requests.append(json.dumps(dict(schema='warpfit.request/1',operation='loss',objective=objective,x=x.tolist(),y=y.tolist(),options=dict(gamma=gamma,feature_weights=w.tolist()))))
        references.append(xy if objective=='raw' else (xy[0]-.5*xx[0]-.5*yy[0],xy[1]-.5*(xx[1]+xx[2]),xy[2]-.5*(yy[1]+yy[2]),xy[3]))
process = subprocess.run(['node','scripts/reference.mjs'],input='\n'.join(requests)+'\n',cwd=root,capture_output=True,text=True,timeout=120,check=True)
actual = [json.loads(line) for line in process.stdout.splitlines()]
assert len(actual)==len(references)==120
maximum = 0.0
for out, expected in zip(actual,references):
    assert out['ok'],out
    for value,reference in zip([out['value'],out['gradient_x'],out['gradient_y'],out['alignment']],expected):
        error=float(np.max(np.abs(np.asarray(value)-np.asarray(reference))))
        maximum=max(maximum,error)
        np.testing.assert_allclose(value,reference,rtol=2e-8,atol=2e-8)
report = dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(), reference='tslearn',reference_version=tslearn.__version__, numpy_version=np.__version__, cases=60,objectives=120,fields=['value','gradient_x','gradient_y','alignment'],max_absolute_difference=maximum,status='passed')
(root/'artifacts').mkdir(exist_ok=True)
(root/'artifacts/tslearn.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
