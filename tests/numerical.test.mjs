import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { run } from '../dist/engine.mjs';

const request = (x,y,options = {}, objective = 'corrected') => JSON.parse(run(JSON.stringify({ schema: 'warpfit.request/1', operation: 'loss', x,y,options,objective })));
const fixtures = JSON.parse(readFileSync(new URL('../oracle-fixtures.json', import.meta.url)));
const matrix = (values, d) => Array.from({ length: values.length / d }, (_, i) => values.slice(i*d, (i+1)*d));
const near = (a,b,tol=2e-9) => assert.ok(Number.isFinite(a) && Math.abs(a-b) <= tol*(1+Math.abs(b)), `${a} != ${b}`);
test('all 80 exhaustive path fixtures also pass through the published JSON engine', () => {
  for (const fixture of fixtures) for (const objective of ['raw','corrected']) {
    const out = request(matrix(fixture.x,fixture.dimensions), matrix(fixture.y,fixture.dimensions), { gamma: fixture.gamma, feature_weights: fixture.feature_weights }, objective);
    assert.equal(out.ok,true); const expected = fixture[objective];
    near(out.value, expected.value);
    for (const key of ['gradient_x','gradient_y']) out[key].flat().forEach((v,i) => near(v,expected[key][i]));
    out.alignment.flat().forEach((v,i) => near(v,fixture.raw.alignment[i]));
  }
});
test('boundary gamma, zero-weight axes and extreme supported values remain finite', () => {
  for (const gamma of [1e-300, 1e-8, 10000]) {
    const out = request([[10000,2],[-10000,3]], [[-10000,-7],[10000,9]], { gamma, feature_weights: [1e6,0] });
    assert.equal(out.ok,true); for (const v of [out.value,...out.gradient_x.flat(),...out.gradient_y.flat(),...out.alignment.flat()]) assert.ok(Number.isFinite(v));
    out.gradient_x.forEach(row => near(row[1],0));
  }
});
test('weighted singleton prototype reaches the analytic weighted mean', () => {
  const result = JSON.parse(run(JSON.stringify({ schema: 'warpfit.request/1', operation: 'fit', seed: [[-3,8]], examples: [[[0,2]],[[4,6]]], options: { gamma: 0.8, max_steps: 120, example_weights: [1,3], feature_weights: [0.2,2] } })));
  assert.equal(result.ok,true); near(result.prototype[0][0],3,1e-3); near(result.prototype[0][1],5,1e-3);
});
test('translation leaves objective invariant and all input derivatives sum to zero per feature', () => {
  const x = [[.2,3],[1.4,2],[-.5,4]], y = [[.4,2],[1.2,3]];
  const a = request(x,y,{gamma:.7,feature_weights:[.3,2]});
  const shift = a => a.map(row => [row[0]+20,row[1]-10]);
  const b = request(shift(x),shift(y),{gamma:.7,feature_weights:[.3,2]}); near(a.value,b.value);
  for (let k=0;k<2;k++) near([...a.gradient_x,...a.gradient_y].reduce((s,row)=>s+row[k],0),0);
});
