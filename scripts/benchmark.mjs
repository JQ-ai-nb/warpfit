import { performance } from 'node:perf_hooks';
import { cpus, platform, arch } from 'node:os';
import { mkdir, writeFile } from 'node:fs/promises';
import { run } from '../dist/engine.mjs';
const results = [];
for (const count of [32,128,512]) for (const dimensions of [1,3]) {
  const make = shift => Array.from({length:count},(_,i)=>Array.from({length:dimensions},(_,k)=>Math.sin(i*.09+k+shift)));
  const request = JSON.stringify({schema:'warpfit.request/1',operation:'loss',x:make(0),y:make(.1),options:{gamma:.4}});
  for(let i=0;i<2;i++) JSON.parse(run(request));
  const times=[]; let output;
  for(let i=0;i<7;i++) {const before=performance.now(); output=JSON.parse(run(request)); times.push(performance.now()-before); if(!output.ok)throw new Error(JSON.stringify(output));}
  times.sort((a,b)=>a-b);
  results.push({samples:count,dimensions,repeats:7,median_ms:times[3],min_ms:times[0],max_ms:times[6],value:output.value});
}
const report={recorded_at_utc:new Date().toISOString(),node:process.version,platform:platform(),arch:arch(),cpu:cpus()[0].model,description:'Single-process JS engine, corrected loss incl. both gradients/occupancy and JSON parse/serialization. Two warmups, seven timed calls. Informational, no cross-machine guarantee.',results};
await mkdir('artifacts',{recursive:true});await writeFile('artifacts/benchmark.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report));
