import test from 'node:test';
import assert from 'node:assert/strict';
import { run } from '../dist/engine.mjs';

// Independent oracle: enumerate complete monotone paths rather than using DP.
function paths(n,m) {
  const output=[];
  const walk=(i,j,prior)=>{
    const path=[...prior,[i,j]];
    if(i===n-1&&j===m-1) {output.push(path);return;}
    for(const [dx,dy] of [[1,0],[0,1],[1,1]])
      if(i+dx<n&&j+dy<m) walk(i+dx,j+dy,path);
  };
  walk(0,0,[]);return output;
}
function band(i,j,n,m,r) {
  if(r===undefined) return true;
  return n<=m ? i-r<=j && j<=i+(m-n)+r : j-r<=i && i<=j+(n-m)+r;
}
function cost(path,x,y,w) {
  return path.reduce((sum,[i,j])=>sum+x[i].reduce((s,v,k)=>s+w[k]*(v-y[j][k])**2,0),0);
}
function close(a,b,tol=1e-9) { assert.ok(Math.abs(a-b)<=tol*(1+Math.abs(b)),`${a} != ${b}`); }
let state=20261111;
function random(n) { state=(Math.imul(state,1664525)+1013904223)>>>0; return Math.floor(state/0x100000000*n); }

test('240 hard DTW cases equal the global minimum over every admissible path', () => {
  const shapes=new Set(), dimensions=new Set(), windows=new Set();
  for(let trial=0;trial<240;trial++) {
    const n=1+random(4), m=1+random(4), d=1+random(2);
    shapes.add(`${n}x${m}`); dimensions.add(d);
    const x=Array.from({length:n},()=>Array.from({length:d},()=>((random(81)-40)/10)));
    const y=Array.from({length:m},()=>Array.from({length:d},()=>((random(81)-40)/10)));
    const w=Array.from({length:d},(_,i)=>i===0 ? [0.2,1,2][random(3)] : [0,0.5,3][random(3)]);
    const radius=[undefined,0,1,2][trial%4];
    windows.add(String(radius));
    const opts={feature_weights:w}; if(radius!==undefined) opts.window=radius;
    const admissible=paths(n,m).filter(p=>p.every(([i,j])=>band(i,j,n,m,radius)));
    assert.ok(admissible.length>0);
    const expected=Math.min(...admissible.map(p=>cost(p,x,y,w)));
    const out=JSON.parse(run(JSON.stringify({schema:'warpfit.request/1',operation:'dtw',x,y,options:opts})));
    assert.equal(out.ok,true,JSON.stringify(out));
    close(out.squared_cost,expected);close(out.distance,Math.sqrt(expected));close(cost(out.path,x,y,w),expected);
    assert.deepEqual(out.path[0],[0,0]); assert.deepEqual(out.path.at(-1),[n-1,m-1]);
    for(let t=0;t<out.path.length;t++) {
      const [i,j]=out.path[t]; assert.ok(band(i,j,n,m,radius));
      if(t) { const [pi,pj]=out.path[t-1]; assert.ok(i-pi>=0&&i-pi<=1&&j-pj>=0&&j-pj<=1&&(i-pi+j-pj)>0); }
    }
  }
  assert.equal(shapes.size,16); assert.equal(dimensions.size,2); assert.equal(windows.size,4);
});
