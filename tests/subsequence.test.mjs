import test from 'node:test';
import assert from 'node:assert/strict';
import { run } from '../dist/engine.mjs';

let state = 20261113;
function random(limit) { state = (1664525 * state + 1013904223) >>> 0; return state % limit; }
function pointCost(a, b, weights) { return a.reduce((sum, value, k) => sum + weights[k] * (value - b[k]) ** 2, 0); }

// Enumerate every admissible path directly; this is deliberately not DTW DP.
function exhaustive(query, target, weights) {
  let best = Infinity, bestEnd = Infinity;
  function visit(i, j, total) {
    const cost = total + pointCost(query[i], target[j], weights);
    if (i === query.length - 1) {
      if (cost < best || (cost === best && j < bestEnd)) { best = cost; bestEnd = j; }
      return;
    }
    if (i + 1 < query.length) visit(i + 1, j, cost);
    if (j + 1 < target.length) visit(i, j + 1, cost);
    if (i + 1 < query.length && j + 1 < target.length) visit(i + 1, j + 1, cost);
  }
  for (let start = 0; start < target.length; start++) visit(0, start, 0);
  return { best, bestEnd };
}

function call(query, target, options = {}) {
  return JSON.parse(run(JSON.stringify({schema:'warpfit.request/1',operation:'subsequence',query,target,options})));
}

test('256 small subsequence cases agree with independent path enumeration', () => {
  let count = 0;
  for (let n=1;n<=4;n++) for (let m=1;m<=4;m++) for (let d=1;d<=2;d++) for (let repeat=0;repeat<8;repeat++) {
    const query = Array.from({length:n}, () => Array.from({length:d}, () => random(7)-3));
    const target = Array.from({length:m}, () => Array.from({length:d}, () => random(7)-3));
    const weights = d === 1 ? [1] : (repeat % 2 ? [1,2] : [0,1]);
    const expected = exhaustive(query,target,weights);
    const result = call(query,target,{feature_weights:weights});
    assert.equal(result.ok,true,JSON.stringify(result));
    assert.equal(result.squared_cost,expected.best);
    assert.equal(result.end,expected.bestEnd);
    assert.equal(result.path[0][0],0);
    assert.equal(result.path.at(-1)[0],n-1);
    assert.equal(result.start,result.path[0][1]);
    assert.equal(result.end,result.path.at(-1)[1]);
    let cost=0;
    result.path.forEach(([i,j],index) => {
      assert.ok(i>=0 && i<n && j>=0 && j<m);
      cost += pointCost(query[i],target[j],weights);
      if (index) {
        const [pi,pj] = result.path[index-1];
        assert.ok(i-pi>=0 && i-pi<=1 && j-pj>=0 && j-pj<=1 && i+j>pi+pj);
      }
    });
    assert.equal(cost,result.squared_cost);
    count++;
  }
  assert.equal(count,256);
});

test('subsequence locates an embedded event in a bounded long target', () => {
  const target=Array(2000).fill(9); target.splice(1234,3,0,1,0);
  const result=call([0,1,0],target);
  assert.equal(result.ok,true);
  assert.deepEqual([result.start,result.end,result.distance],[1234,1236,0]);
  assert.equal(call([0,1,0],target,{max_cells:5999}).error.code,'cell_limit');
  assert.equal(call([0,1,0],target,{window:1}).error.code,'unknown_field');
});
