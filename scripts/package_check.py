"""Inspect the actual Mooncakes archive, including accidentally included files."""
import json
import re
import subprocess
from pathlib import Path
from zipfile import ZipFile

root = Path(__file__).resolve().parent.parent
subprocess.run(['moon','package','--list'],cwd=root,check=True,capture_output=True)
archives = list((root/'_build/publish').glob('JQ-ai-nb-warpfit-*.zip'))
archive = max(archives,key=lambda p:p.stat().st_mtime)
with ZipFile(archive) as package:
    names = package.namelist()
    assert any(n.endswith('core/soft.mbt') for n in names),names
    assert any(n.endswith('LICENSE') for n in names),names
    assert any(n.endswith('README.md') for n in names),names
    for name in names:
        parts = Path(name.replace('\\','/')).parts
        assert not set(parts)&{'work','deliverables','artifacts','.git','node_modules'},name
        assert not any(p.lower().endswith(('.pem','.key','.env')) for p in parts),name
        data = package.read(name)
        assert not re.search(rb'\b[0-9]{5,12}@qq\.com\b',data), name
    (root/'artifacts').mkdir(exist_ok=True)
    (root/'artifacts/package.json').write_text(json.dumps(dict(archive=archive.name,file_count=len(names),files=names,status='passed'),indent=2),encoding='utf-8')
print(f'Package checked: {len(names)} files, private work and contact fields excluded.')
