import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

test('six attributed real-sensor windows run through preprocessing and clustering', () => {
  const request = JSON.parse(readFileSync('examples/uci-room.json', 'utf8'));
  assert.equal(request.data.length, 6);
  assert.ok(request.data.every(series => series.length === 60 && series.every(row => row.length === 3)));
  const response = JSON.parse(execFileSync(process.execPath,
    ['bin/warpfit.mjs', 'examples/uci-room.json'], { encoding: 'utf8' }));
  assert.equal(response.ok, true);
  assert.equal(response.prepared.length, 6);
  assert.ok(response.prepared.every(item => item.series.length === 48));
  assert.deepEqual(response.clustering.labels, [0, 1, 0, 1, 1, 1]);
  assert.ok(Math.abs(response.clustering.inertia - 47.72708169290795) < 1e-7);
  assert.ok(response.clustering.history.every((value, index, history) =>
    index === 0 || value <= history[index - 1] + 1e-9));
  assert.equal(response.clustering.stop, 'improvement_tolerance');
  assert.deepEqual(response.prepared[4].constant_features, [false, true, true]);
});
