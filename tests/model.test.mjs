import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile, unlink } from 'node:fs/promises';
import { join } from 'node:path';
import { run } from '../dist/engine.mjs';

const call = input => JSON.parse(run(JSON.stringify(input)));
const schema = 'warpfit.request/1';

test('trained model survives a JSON file roundtrip and predicts a new batch', async () => {
  const trained = call({ schema, operation: 'train_model',
    data: [[2,4,6],[100,200,300,400,500],[6,4,2],[500,400,300,200,100]],
    seed_indices: [0,2], options: { target_count: 5, window: 0, feature_weights: [2] } });
  assert.equal(trained.ok, true);
  assert.equal(trained.model.schema, 'warpfit.cluster-model/1');
  assert.equal(trained.model.preprocessing.target_count, 5);
  assert.equal(trained.model.alignment.window, 0);
  await mkdir('work', { recursive: true });
  const file = join('work', `model-roundtrip-${process.pid}.json`);
  await writeFile(file, JSON.stringify(trained.model), 'utf8');
  try {
    const saved = JSON.parse(await readFile(file, 'utf8'));
    const predicted = call({ schema, operation: 'predict', model: saved,
      data: [[10,20,30], Array.from({length:600}, (_, i) => i)] });
    assert.equal(predicted.ok, true);
    assert.deepEqual(predicted.labels, [0,0]);
    assert.equal(predicted.distances_to_centers.length, 2);
    assert.ok(predicted.distances.every(x => x < 1e-10));
    assert.equal(predicted.work_units, 100);
    const exhausted = call({ schema, operation: 'predict', model: saved,
      data: [[10,20,30]], options: { max_work_units: 49 } });
    assert.equal(exhausted.error.code, 'work_budget');
    const missing = structuredClone(saved); delete missing.alignment.max_cells;
    assert.equal(call({ schema, operation:'predict', model:missing, data:[[1,2,3]] }).error.code, 'missing_field');
    const tampered = structuredClone(saved); tampered.alignment.extra = 1;
    assert.equal(call({ schema, operation:'predict', model:tampered, data:[[1,2,3]] }).error.code, 'unknown_field');
  } finally { await unlink(file); }
});
