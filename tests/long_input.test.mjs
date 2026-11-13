import test from 'node:test';
import assert from 'node:assert/strict';
import { run } from '../dist/engine.mjs';

const request = (operation, fields, options = {}) => JSON.parse(run(JSON.stringify({
  schema: 'warpfit.request/1', operation, ...fields, options
})));

test('raw daily sample can be resampled before the bounded analysis stage', () => {
  const raw = Array.from({ length: 2880 }, (_, index) => index);
  const result = request('preprocess', { series: raw }, { target_count: 100, normalize: false });
  assert.equal(result.ok, true);
  assert.equal(result.prepared.series.length, 100);
  assert.equal(result.prepared.series[0][0], 0);
  assert.equal(result.prepared.series[99][0], 2879);
  assert.ok(Math.abs(result.prepared.series[33][0] - 2879 / 3) < 1e-10);
  assert.equal(request('preprocess', { series: raw }).error.code, 'target_count');
  assert.equal(request('dtw', { x: raw.slice(0, 513), y: [0] }).error.code, 'array_limit');
  assert.equal(request('preprocess', { series: Array(8193).fill(0) }, { target_count: 100 }).error.code, 'array_limit');
});

test('pipeline accepts bounded raw inputs and clusters their resampled outputs', () => {
  const rising = Array.from({ length: 600 }, (_, index) => index);
  const falling = [...rising].reverse();
  const result = request('pipeline', { data: [rising, falling], seed_indices: [0, 1] },
    { target_count: 10, normalize: false, window: 0 });
  assert.equal(result.ok, true);
  assert.deepEqual(result.clustering.labels, [0, 1]);
  assert.deepEqual(result.prepared.map(item => item.series.length), [10, 10]);
});
