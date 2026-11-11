import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { run } from '../dist/engine.mjs';

const call = name => {
  const processResult = spawnSync(process.execPath, ['bin/warpfit.mjs', `examples/${name}.json`], { encoding: 'utf8' });
  assert.equal(processResult.status, 0, processResult.stderr);
  return JSON.parse(processResult.stdout);
};
const close = (a,b,tol=1e-9) => assert.ok(Math.abs(a-b)<=tol*(1+Math.abs(b)),`${a} != ${b}`);
const req = value => JSON.parse(run(JSON.stringify(value)));
const schema = 'warpfit.request/1';

test('bounded DTW file produces a valid zero-cost path; the diagonal-only path costs more', () => {
  const out=call('align'); assert.equal(out.ok,true); close(out.distance,0);
  assert.deepEqual(out.path[0],[0,0]); assert.deepEqual(out.path.at(-1),[3,3]);
  for (let i=1;i<out.path.length;i++) {
    const [x,y]=out.path[i], [px,py]=out.path[i-1];
    assert.ok(x-px>=0&&x-px<=1&&y-py>=0&&y-py<=1&&(x-px+y-py)>0);
    assert.ok(Math.abs(x-y)<=1);
  }
  const input=JSON.parse(readFileSync('examples/align.json'));input.options.window=0;
  close(req(input).squared_cost,2);
});
test('DBA file yields a learned template and a nonincreasing objective', () => {
  const out=call('dba'); assert.equal(out.ok,true); assert.equal(out.prototype.length,4);
  assert.ok(out.history.at(-1)<out.history[0]);
  assert.equal(out.history.length,out.accepted_steps+1);
  for(let i=1;i<out.history.length;i++) assert.ok(out.history[i]<=out.history[i-1]);
});
test('DTW k-means file assigns different shapes and learns both group centers', () => {
  const out=call('clusters'); assert.equal(out.ok,true);
  assert.deepEqual(out.labels,[0,0,0,1,1,1]); assert.equal(out.centers.length,2);
  assert.ok(out.inertia<=out.history[0]);
  assert.equal(out.history.length,out.iterations+1);
  const request=JSON.parse(readFileSync('examples/clusters.json'));
  for(let i=0;i<request.data.length;i++) {
    const costs=out.centers.map(center=>req({schema,operation:'dtw',x:center,y:request.data[i],options:{window:1}}).squared_cost);
    assert.ok(costs[out.labels[i]]<=Math.min(...costs)+1e-10);
  }
});
test('new input errors identify duplicate centers and strict option names', () => {
  const empty=req({schema,operation:'cluster',data:[[0],[0]],centers:[[0],[0]]});
  assert.equal(empty.ok,false); assert.equal(empty.error.code,'empty_cluster');
  const unknown=req({schema,operation:'dtw',x:[0],y:[0],options:{radius:1}});
  assert.equal(unknown.ok,false); assert.equal(unknown.error.code,'unknown_field');
});
test('pipeline resamples, normalizes per series and groups by shape despite scale', () => {
  const out=call('pipeline');assert.equal(out.ok,true);
  assert.deepEqual(out.clustering.labels,[0,0,1,1]);close(out.clustering.inertia,0);
  assert.equal(out.prepared[0].series.length,5);close(out.prepared[0].means[0],4);
  close(out.prepared[1].means[0],300);assert.equal(out.prepared[0].normalized,true);
  const raw=req({schema,operation:'preprocess',series:[1,2,3],options:{target_count:5,normalize:false}});
  assert.deepEqual(raw.prepared.series.map(x=>x[0]),[1,1.5,2,2.5,3]);
  assert.deepEqual(raw.prepared.means,[]);
});
test('DBA and clustering CLI expose budget exhaustion without partial output', () => {
  for(const value of [
    {schema,operation:'dba',seed:[2],examples:[[0]],options:{max_work_units:1}},
    {schema,operation:'cluster',data:[[0],[2],[9],[11]],centers:[[0],[10]],options:{max_work_units:8}},
    {schema,operation:'pipeline',data:[[0],[2],[9],[11]],seed_indices:[0,2],options:{normalize:false,max_work_units:8}}
  ]) {
    const p=spawnSync(process.execPath,['bin/warpfit.mjs','-'],{input:JSON.stringify(value),encoding:'utf8'});
    assert.equal(p.status,3); const out=JSON.parse(p.stdout);
    assert.equal(out.ok,true);
    const result=out.clustering??out;
    assert.equal(result.stop,'work_budget'); assert.equal(result.history.length,1);
  }
});
