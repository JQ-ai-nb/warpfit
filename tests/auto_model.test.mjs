import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, writeFile, readdir, unlink, rmdir } from 'node:fs/promises';
import { join } from 'node:path';
import { run } from '../dist/engine.mjs';

const call = request => JSON.parse(run(JSON.stringify(request)));
const base = { schema:'warpfit.request/1', operation:'auto_train_model',
  data:[[0],[2],[9],[11]], cluster_count:2, options:{normalize:false} };

test('farthest-first initialization, training and prediction preserve reproducible centers and budgets', () => {
  for (const [data, first, count, expected] of [
    [[[0],[2],[9],[11]],0,2,[0,3]],
    [[[0],[2],[9],[11]],0,3,[0,3,1]],
    [[[0],[2],[9],[11]],3,3,[3,0,1]],
    [[[0],[2],[4]],1,2,[1,0]],
  ]) {
    const request={...base,data,first_index:first,cluster_count:count};
    const auto=call(request);
    assert.equal(auto.ok,true,JSON.stringify(auto));
    assert.deepEqual(auto.seed_indices,expected);
    assert.deepEqual(call(request),auto);
    assert.equal(auto.total_work_units,auto.seed_work_units+auto.clustering.work_units);
    assert.ok(auto.total_work_units <= 20_000_000);
    const manual=call({schema:base.schema,operation:'train_model',data,seed_indices:expected,
      options:{...base.options,max_work_units:20_000_000-auto.seed_work_units}});
    assert.deepEqual(auto.model,manual.model);
    assert.deepEqual(auto.clustering,manual.clustering);
    const inferred=call({schema:base.schema,operation:'predict',model:auto.model,data});
    assert.deepEqual(inferred.labels,auto.clustering.labels);
  }
});

test('automatic initialization rejects indistinguishable samples and checks the whole shared budget', () => {
  assert.equal(call({...base,data:[[2,2],[9,9]],options:{normalize:true}}).error.code,'seed_distinct');
  assert.equal(call({...base,cluster_count:5}).error.code,'seed_indices');
  assert.equal(call({...base,first_index:4}).error.code,'seed_indices');
  assert.equal(call({...base,options:{normalize:false,max_work_units:2}}).error.code,'work_budget');
  assert.equal(call({...base,options:{normalize:false,max_work_units:10}}).error.code,'work_budget');
  const stopped=call({...base,options:{normalize:false,max_work_units:11}});
  assert.equal(stopped.ok,true);
  assert.equal(stopped.clustering.stop,'work_budget');
  assert.equal(stopped.total_work_units,11);
  assert.equal(stopped.seed_work_units,3);
  assert.equal(call({...base,cluster_count:1,data:[[2,2]]}).ok,true);
});

test('model CLI never writes a model from budget-interrupted training', async () => {
  await mkdir('work',{recursive:true});
  const dir=await mkdtemp(join('work','model-budget-'));
  const input=join(dir,'input.json'), output=join(dir,'model.json');
  try {
    await writeFile(input,JSON.stringify({...base,options:{normalize:false,max_work_units:11}}));
    const result=spawnSync(process.execPath,['bin/warpfit-model.mjs','train',input,output],{encoding:'utf8'});
    assert.equal(result.status,3,result.stdout+result.stderr);
    const report=JSON.parse(result.stdout);
    assert.equal(report.clustering.stop,'work_budget');
    assert.deepEqual(await readdir(dir),['input.json']);
  } finally {
    await unlink(input);
    await rmdir(dir);
  }
});
