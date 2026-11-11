import { performance } from 'node:perf_hooks';
import { cpus, platform, arch } from 'node:os';
import { mkdir, writeFile } from 'node:fs/promises';
import { run } from '../dist/engine.mjs';

const engine = request => {
  const out=JSON.parse(run(JSON.stringify(request)));
  if(!out.ok) throw new Error(JSON.stringify(out));
  return out;
};
const results=[];
for(const n of [32,128,512]) for(const dimensions of [1,3]) for(const window of [undefined,4]) {
  const seq=offset=>Array.from({length:n},(_,i)=>Array.from({length:dimensions},(_,k)=>Math.sin(i*.09+k+offset)));
  const options={};if(window!==undefined)options.window=window;
  const request={schema:'warpfit.request/1',operation:'dtw',x:seq(0),y:seq(.1),options};
  for(let i=0;i<2;i++)engine(request);
  const times=[];let result;
  for(let i=0;i<7;i++) {const start=performance.now();result=engine(request);times.push(performance.now()-start);}
  times.sort((a,b)=>a-b);
  results.push({operation:'dtw',samples:n,dimensions,window:window??'unbounded',visited_cells:result.visited_cells,
    allocated_cells:n*n,repeats:7,median_ms:times[3],min_ms:times[0],max_ms:times[6]});
}
const data=Array.from({length:16},(_,j)=>Array.from({length:64},(_,i)=>
  50*(j%3)+(1+(j%4)*.1)*(j<8?1:-1)*Math.sin(i/63*Math.PI*2)));
const input={schema:'warpfit.request/1',operation:'pipeline',data,seed_indices:[0,8],
  options:{target_count:64,normalize:true,window:4,max_iterations:5,max_dba_steps:5,max_work_units:100000000}};
engine(input);const times=[];let out;
for(let i=0;i<3;i++) {const start=performance.now();out=engine(input);times.push(performance.now()-start);}
times.sort((a,b)=>a-b);
results.push({operation:'pipeline',series:16,samples:64,dimensions:1,clusters:2,window:4,repeats:3,
  median_ms:times[1],min_ms:times[0],max_ms:times[2],stop:out.clustering.stop,work_units:out.clustering.work_units});
const report={recorded_at_utc:new Date().toISOString(),node:process.version,platform:platform(),arch:arch(),cpu:cpus()[0].model,
  description:'Single-process MoonBit JS engine; includes JSON parsing/serialization and output generation. DTW: 2 warmups, 7 calls. Pipeline: 1 warmup, 3 calls. Not a wall-clock guarantee or a comparison with other implementations.',results};
await mkdir('artifacts',{recursive:true});await writeFile('artifacts/benchmark-hard.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report));
