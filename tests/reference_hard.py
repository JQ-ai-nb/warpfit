"""Optional independent tslearn cross-check; not a package runtime dependency.

Set WARPFIT_REFERENCE_DEPS to a directory with tslearn==0.6.4, or install it in
the current Python environment. Values are generated here, not copied fixtures.
"""
import json
import os
import random
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root=Path(__file__).resolve().parent.parent
reference_deps=os.environ.get('WARPFIT_REFERENCE_DEPS')
if reference_deps: sys.path.insert(0,reference_deps)
os.environ.setdefault('NUMBA_NUM_THREADS','1')
os.environ.setdefault('OPENBLAS_NUM_THREADS','1')
import numpy as np
import tslearn
from tslearn.metrics import dtw_path
from tslearn.barycenters import dtw_barycenter_averaging
from tslearn.clustering import TimeSeriesKMeans
from tslearn.utils import to_time_series_dataset

rng=random.Random(20261111)
requests=[]
checks=[]
schema='warpfit.request/1'
def sequence(n,d):return np.array([[rng.uniform(-2,2) for _ in range(d)] for _ in range(n)])
def submit(request,reference,kind):
    requests.append(json.dumps(request,separators=(',',':')))
    checks.append((kind,reference))

for trial in range(160):
    n,m,d=rng.randint(1,12),rng.randint(1,12),rng.randint(1,3)
    x,y=sequence(n,d),sequence(m,d)
    weights=np.array([rng.choice([.2,1.,2.]) for _ in range(d)])
    window=[None,0,1,2][trial%4]
    params={} if window is None else dict(global_constraint='sakoe_chiba',sakoe_chiba_radius=window)
    path,distance=dtw_path(x*np.sqrt(weights),y*np.sqrt(weights),**params)
    opts=dict(feature_weights=weights.tolist())
    if window is not None:opts['window']=window
    submit(dict(schema=schema,operation='dtw',x=x.tolist(),y=y.tolist(),options=opts),float(distance),'dtw')

for trial in range(40):
    n=rng.randint(2,7); d=rng.randint(1,2); count=rng.randint(2,4)
    seed=sequence(n,d); examples=[sequence(n,d) for _ in range(count)]
    weights=np.array([rng.choice([.5,1.,2.]) for _ in range(count)])
    # One exact DBA update isolates alignment and weighted averaging; limiting
    # iterations avoids conflating different convergence/tie policies.
    expected=dtw_barycenter_averaging(examples,barycenter_size=n,init_barycenter=seed,max_iter=1,weights=weights)
    submit(dict(schema=schema,operation='dba',seed=seed.tolist(),examples=[x.tolist() for x in examples],
        options=dict(max_steps=1,example_weights=weights.tolist())),expected.tolist(),'dba')

series=[[0,1,2,1,0],[0,0,1,2,1,0],[0,.9,2,1,0],[3,2,1,2,3],[3,3,2,1,2,3],[3,2,1.1,2,3]]
centers=[[0,1,2,1,0],[3,2,1,2,3]]
model=TimeSeriesKMeans(n_clusters=2,metric='dtw',init=np.array(centers)[:,:,None],n_init=1,
    max_iter=10,max_iter_barycenter=20,tol=1e-8,random_state=0,
    metric_params=dict(global_constraint='sakoe_chiba',sakoe_chiba_radius=1))
model.fit(to_time_series_dataset(series))
submit(dict(schema=schema,operation='cluster',data=series,centers=centers,
    options=dict(window=1,max_iterations=10,max_dba_steps=20,tolerance=1e-8)),
    dict(labels=model.labels_.tolist(),centers=model.cluster_centers_.tolist(),inertia=float(model.inertia_)),'cluster')

process=subprocess.run(['node','scripts/reference.mjs'],input='\n'.join(requests)+'\n',cwd=root,
    capture_output=True,text=True,timeout=180,check=True)
actual=[json.loads(line) for line in process.stdout.splitlines()]
assert len(actual)==len(checks)
max_errors=dict(dtw=0.,dba=0.,cluster=0.)
def check(actual,expected,kind):
    error=float(np.max(np.abs(np.asarray(actual)-np.asarray(expected))))
    max_errors[kind]=max(max_errors[kind],error)
    np.testing.assert_allclose(actual,expected,rtol=1e-8,atol=1e-8)
for out,(kind,reference) in zip(actual,checks):
    assert out['ok'],out
    if kind=='dtw': check(out['distance'],reference,kind)
    elif kind=='dba':check(out['prototype'],reference,kind)
    else:
        assert out['labels']==reference['labels'],(out['labels'],reference['labels'])
        check(out['centers'],reference['centers'],kind)
        check(out['inertia'],reference['inertia'],kind)
report=dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(),reference='tslearn',
    reference_version=tslearn.__version__,numpy_version=np.__version__,
    cases=dict(weighted_dtw=160,weighted_one_step_dba=40,cluster_workflow=1),
    max_absolute_error=max_errors,tolerance='rtol=atol=1e-8',status='passed')
(root/'artifacts').mkdir(exist_ok=True)
(root/'artifacts/hard-reference.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
