import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rmdir, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { run } from '../dist/engine.mjs';

const cli = (...args) => spawnSync(process.execPath, ['bin/warpfit-model.mjs', ...args], { encoding:'utf8' });

test('model CLI saves once, reloads for prediction and preserves strict JSON validation', async () => {
  await mkdir('work', {recursive:true});
  const dir = await mkdtemp(join('work', 'model-cli-'));
  const model = join(dir, 'model.json'), output = join(dir, 'prediction.json'), bad = join(dir, 'bad.json');
  try {
    const train = cli('train', 'examples/model_train.json', model);
    assert.equal(train.status, 0, train.stdout + train.stderr);
    const summary = JSON.parse(train.stdout);
    assert.equal(summary.cluster_count, 2);
    const original = await readFile(model, 'utf8');
    assert.equal(JSON.parse(original).schema, 'warpfit.cluster-model/1');
    const again = cli('train', 'examples/model_train.json', model);
    assert.equal(again.status, 2);
    assert.equal(await readFile(model, 'utf8'), original);
    const predict = cli('predict', model, 'examples/model_predict_data.json', '--out', output);
    assert.equal(predict.status, 0, predict.stdout + predict.stderr);
    assert.equal(predict.stdout, '');
    assert.deepEqual(JSON.parse(await readFile(output, 'utf8')).labels, [0,1,0]);
    const overwrite = cli('predict', model, 'examples/model_predict_data.json', '--out', model);
    assert.equal(overwrite.status, 2);
    assert.equal(await readFile(model, 'utf8'), original);
    await writeFile(bad, '{"schema":"warpfit.cluster-model/1","schema":"duplicate"}', 'utf8');
    const duplicate = cli('predict', bad, 'examples/model_predict_data.json');
    assert.equal(duplicate.status, 2);
    assert.equal(JSON.parse(duplicate.stdout).error.code, 'json');
  } finally {
    for (const file of [model, output, bad]) await unlink(file).catch(error => { if (error.code !== 'ENOENT') throw error; });
    await rmdir(dir);
  }
});

test('model and data files must each contain a standalone JSON document', async () => {
  await mkdir('work', {recursive:true});
  const dir=await mkdtemp(join('work','model-document-'));
  const modelPath=join(dir,'model.json'), dataPath=join(dir,'data.json');
  const trained=JSON.parse(run(await readFile('examples/model_train.json','utf8')));
  assert.equal(trained.ok,true);
  const model=JSON.stringify(trained.model), data='[[1,2,3]]';
  try {
    for(const [badModel,badData] of [
      [model+',"options":{"max_work_units":1}',data],
      [model,data+',"options":{"max_work_units":1}'],
      [model+' {}',data],
      [model,data+' null'],
    ]) {
      await writeFile(modelPath,badModel,'utf8');
      await writeFile(dataPath,badData,'utf8');
      const result=cli('predict',modelPath,dataPath);
      assert.equal(result.status,2,result.stdout+result.stderr);
      assert.equal(JSON.parse(result.stdout).error.code,'json');
    }
  } finally {
    await unlink(modelPath); await unlink(dataPath); await rmdir(dir);
  }
});
