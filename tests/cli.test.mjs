import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { run } from '../dist/engine.mjs';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const cli = (...args) => spawnSync(process.execPath, ['bin/warpfit.mjs', ...args], { cwd: root, encoding: 'utf8' });
const input = source => spawnSync(process.execPath, ['bin/warpfit.mjs', '-'], { cwd: root, input: source, encoding: 'utf8' });
const request = { schema: 'warpfit.request/1', operation: 'loss', x: [2], y: [5], options: { gamma: 1 } };
const close = (a, b, tol = 1e-9) => assert.ok(Math.abs(a - b) <= tol, `${a} != ${b}`);

test('file workflow fits a template with strictly descending accepted objectives', () => {
  const r = cli('examples/prototype.json'); assert.equal(r.status, 0, r.stderr);
  const out = JSON.parse(r.stdout); assert.equal(out.ok, true);
  assert.ok(out.history.at(-1) < out.history[0] / 10);
  for (let i = 1; i < out.history.length; i++) assert.ok(out.history[i] < out.history[i - 1]);
  assert.equal(out.history.length, out.accepted_steps + 1);
  assert.equal(out.prototype.length, 4);
});
test('stdin workflow returns analytically known one-point value and both derivatives', () => {
  const r = input(JSON.stringify(request)); assert.equal(r.status, 0);
  const out = JSON.parse(r.stdout); close(out.value, 9);
  close(out.gradient_x[0][0], -6); close(out.gradient_y[0][0], 6);
  close(out.alignment[0][0], 1);
});
test('multivariate training gradient agrees with independent central differences', () => {
  const source = JSON.parse(readFileSync(join(root, 'examples/training.json')));
  const out = JSON.parse(run(JSON.stringify(source)));
  for (const side of ['x', 'y']) for (let i = 0; i < source[side].length; i++) for (let k = 0; k < 2; k++) {
    const h = 1e-5; const original = source[side][i][k];
    source[side][i][k] = original + h; const hi = JSON.parse(run(JSON.stringify(source))).value;
    source[side][i][k] = original - h; const lo = JSON.parse(run(JSON.stringify(source))).value;
    source[side][i][k] = original;
    close(out[`gradient_${side}`][i][k], (hi - lo) / (2 * h), 2e-7);
  }
});
test('retrieval evaluates the whole candidate set and ranks exact match first', () => {
  const r = cli('examples/retrieval.json'); assert.equal(r.status, 0);
  const out = JSON.parse(r.stdout); assert.equal(out.candidates_evaluated, 3);
  assert.equal(out.matches[0].id, 'same'); close(out.matches[0].value, 0);
  assert.ok(out.matches[1].value < out.matches[2].value);
});
test('raw Soft-DTW can be negative; corrected equal sequences are zero', () => {
  const data = { ...request, x: [0, 1], y: [0, 1], objective: 'raw' };
  assert.ok(JSON.parse(run(JSON.stringify(data))).value < 0);
  data.objective = 'corrected'; close(JSON.parse(run(JSON.stringify(data))).value, 0);
});
test('duplicate keys, lexical integer errors, invalid UTF-8 and missing files fail explicitly', () => {
  for (const source of [JSON.stringify(request).replace('"loss"', '"loss","operation":"fit"'),
    '{"schema":"warpfit.request/1","operation":"fit","seed":[0],"examples":[[1]],"options":{"max_steps":1e1}}',
    Buffer.from([0xff])]) {
    const r = input(source); assert.equal(r.status, 2); assert.equal(JSON.parse(r.stdout).ok, false);
  }
  assert.equal(cli('nonexistent-warpfit-input.json').status, 2);
});
test('budget stop returns the last evaluated iterate and uses exit 3', () => {
  const source = { schema: 'warpfit.request/1', operation: 'fit', seed: [0], examples: [[2]], options: { max_evaluations: 1 } };
  const r = input(JSON.stringify(source)); assert.equal(r.status, 3);
  const out = JSON.parse(r.stdout); assert.equal(out.stop, 'evaluation_budget');
  assert.equal(out.history.length, 1); close(out.prototype[0][0], 0);
});
test('output file contains the same schema and stdout stays empty', () => {
  const dir = mkdtempSync(join(tmpdir(), 'warpfit-'));
  try {
    const target = join(dir, 'result.json');
    const r = cli('examples/training.json', '--out', target);
    assert.equal(r.status, 0); assert.equal(r.stdout, '');
    assert.equal(JSON.parse(readFileSync(target)).schema, 'warpfit.response/1');
  } finally { rmSync(dir, { recursive: true }); }
});
test('help and version are available', () => {
  assert.match(cli('--help').stdout, /REQUEST/);
  const metadata = JSON.parse(readFileSync(new URL('../package.json', import.meta.url)));
  assert.equal(cli('--version').stdout.trim(), `WarpFit ${metadata.version}`);
});
