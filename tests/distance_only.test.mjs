import test from 'node:test';
import assert from 'node:assert/strict';
import { run } from '../dist/engine.mjs';

let state=71238;
function random(max) { state^=state<<13; state^=state>>>17; state^=state<<5; return (state>>>0)%max; }
function call(operation,x,y,options) {
  return JSON.parse(run(JSON.stringify({schema:'warpfit.request/1',operation,x,y,options})));
}
test('rolling-row distance matches the full path across 1200 weighted cases', () => {
  for(let k=0;k<1200;k++) {
    const n=1+random(32),m=1+random(32),d=1+random(4);
    const x=Array.from({length:n},()=>Array.from({length:d},()=>random(21)-10));
    const y=Array.from({length:m},()=>Array.from({length:d},()=>random(21)-10));
    const weights=Array.from({length:d},()=>random(3));
    if (weights.every(w=>w===0)) weights[0]=1;
    const options={feature_weights:weights};
    if(k%5!==0) options.window=random(5);
    const full=call('dtw',x,y,options), rolling=call('dtw_distance',x,y,options);
    assert.equal(full.ok,true,JSON.stringify(full));
    assert.equal(rolling.ok,true,JSON.stringify(rolling));
    assert.equal(rolling.squared_cost,full.squared_cost,`case ${k}`);
    assert.equal(rolling.visited_cells,full.visited_cells,`case ${k}`);
    assert.equal(rolling.distance,full.distance,`case ${k}`);
    assert.equal('path' in rolling,false);
  }
});

test('narrow-band rolling rows agree with full paths at extreme length ratios', () => {
  for(const [n,m] of [[1,512],[512,1],[7,512],[512,7],[512,512]]) {
    const x=Array.from({length:n},(_,i)=>Math.sin(i/7));
    const y=Array.from({length:m},(_,i)=>Math.cos(i/11));
    for(const window of [0,1,4]) {
      const full=call('dtw',x,y,{window}), rolling=call('dtw_distance',x,y,{window});
      assert.equal(rolling.ok,true,JSON.stringify(rolling));
      assert.equal(rolling.squared_cost,full.squared_cost);
      assert.equal(rolling.visited_cells,full.visited_cells);
    }
  }
});
