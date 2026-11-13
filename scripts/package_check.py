"""Inspect the actual Mooncakes archive, including accidentally included files."""
import json
import re
import subprocess
from pathlib import Path
from zipfile import ZipFile

root = Path(__file__).resolve().parent.parent
subprocess.run(['moon','package','--list'],cwd=root,check=True,capture_output=True)
metadata = (root/'moon.mod').read_text(encoding='utf-8')
version = re.search(r'^version\s*=\s*"([^"]+)"',metadata,re.M)[1]
archive = root/'_build/publish'/f'JQ-ai-nb-warpfit-{version}.zip'
with ZipFile(archive) as package:
    names = package.namelist()
    required = {'moon.mod','README.md','LICENSE','THIRD_PARTY_NOTICES.md',
        'core/soft.mbt','core/dtw.mbt','core/dba.mbt','core/cluster.mbt',
        'core/model.mbt','core/subsequence.mbt','core/pkg.generated.mbti',
        'cmd/consumer/main.mbt','cmd/consumer/moon.pkg',
        'docs/REAL_DATA.md','examples/uci-model-split.json',
        'examples/uci-model-train.json','examples/uci-model-test-data.json'}
    assert required <= set(names),sorted(required-set(names))
    for name in names:
        parts = Path(name.replace('\\','/')).parts
        assert not set(parts)&{'work','deliverables','artifacts','.git','node_modules'},name
        assert not any(p.lower() in {'credentials.json','hosts.yml'} for p in parts),name
        assert not any(p.lower().endswith(('.pem','.key','.env')) for p in parts),name
        data = package.read(name)
        assert not re.search(rb'\b[0-9]{5,12}@qq\.com\b',data), name
    (root/'artifacts').mkdir(exist_ok=True)
    (root/'artifacts/package.json').write_text(json.dumps(dict(module='JQ-ai-nb/warpfit',version=version,archive=archive.name,file_count=len(names),required_files=sorted(required),files=names,status='passed'),indent=2),encoding='utf-8')
print(f'Package checked: {len(names)} files, private work and contact fields excluded.')
