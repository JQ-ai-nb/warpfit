"""Verify the released package from Mooncakes in a fresh, independent module.

No path dependency and no local core files are copied. Run after publication.
"""
import json
from pathlib import Path
import re
import subprocess
import tempfile
from datetime import datetime, timezone

root=Path(__file__).resolve().parent.parent
version=re.search(r'^version\s*=\s*"([^"]+)"', (root/'moon.mod').read_text(), re.M)[1]
folder=root/'work';folder.mkdir(exist_ok=True)
consumer=Path(tempfile.mkdtemp(prefix='registry-consumer-',dir=folder))
(consumer/'moon.mod').write_text(f'name = "warpfit-verification/consumer"\nversion = "0.0.0"\nimport {{ "JQ-ai-nb/warpfit@{version}" }}\n',encoding='utf-8')
(consumer/'moon.pkg').write_text('import { "JQ-ai-nb/warpfit/core" @warpfit, }\npkgtype(kind: "executable")\n',encoding='utf-8')
(consumer/'main.mbt').write_text('''fn main raise {
  let x : @warpfit.Series = { count: 1, dimensions: 1, values: [2.0] }
  let y : @warpfit.Series = { count: 1, dimensions: 1, values: [5.0] }
  let out = @warpfit.divergence(x,y,1.0).unwrap()
  assert_true((out.value-9.0).abs()<1.0e-9)
  assert_true((out.gradient_x[0]+6.0).abs()<1.0e-9)
  let learned = @warpfit.fit(x,[y],0.5,30).unwrap()
  assert_true((learned.prototype.values[0]-5.0).abs()<1.0e-6)
  let ranked = @warpfit.rank_candidates(x,[{id:"exact",series:x},{id:"other",series:y}],@warpfit.alignment_options(0.5),2,100).unwrap()
  assert_true(ranked.matches[0].id=="exact")
  println("registry_consumer: loss=9 gradient_x=-6 learned=5 rank_first=exact")
}
''',encoding='utf-8')
results=[]
for command in [['moon','update'],['moon','check','--target','all','--deny-warn'],['moon','run','.','--target','js'],['moon','run','.','--target','wasm-gc']]:
    p=subprocess.run(command,cwd=consumer,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=180)
    results.append(dict(command=command,returncode=p.returncode,stdout=p.stdout,stderr=p.stderr))
    print(' '.join(command),'=>',p.returncode,flush=True)
    if p.returncode: print(p.stdout,p.stderr);break
passed=len(results)==4 and all(v['returncode']==0 for v in results)
report=dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(),package='JQ-ai-nb/warpfit',version=version,path_dependency=False,local_source_copied=False,status='passed' if passed else 'failed',results=results)
(root/'artifacts').mkdir(exist_ok=True)
(root/'artifacts/registry-consumer.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
raise SystemExit(0 if passed else 1)
