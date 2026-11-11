import test from 'node:test';
import assert from 'node:assert/strict';
import { run } from '../dist/engine.mjs';

const schema='warpfit.request/1';
const invoke=(operation,fields)=>JSON.parse(run(JSON.stringify({schema,operation,...fields})));
const near=(a,b,tol=1e-8)=>assert.ok(Number.isFinite(a)&&Math.abs(a-b)<=tol*(1+Math.abs(b)),`${a} != ${b}`);
let state=31112026;
function random() { state=(Math.imul(state,1664525)+1013904223)>>>0;return state/0x100000000; }
const integer=n=>Math.floor(random()*n);
const sample=(n,d,base=0)=>Array.from({length:n},(_,i)=>Array.from({length:d},(_,k)=>base+Math.sin(i+k)+random()/10));

test('80 DBA runs return consistent objective, valid prototypes and honest budget stops',()=>{
  for(let trial=0;trial<80;trial++) {
    const d=1+integer(3), count=1+integer(4), length=1+integer(5);
    const seed=sample(length,d), examples=Array.from({length:count},()=>sample(1+integer(6),d));
    const weights=Array.from({length:count},()=>1+integer(4));
    const featureWeights=Array.from({length:d},(_,k)=>k===0?1:[0,.5,1,2][integer(4)]);
    const alignment={feature_weights:featureWeights}; if(trial%2===0) alignment.window=integer(3);
    const result=invoke('dba',{seed,examples,options:{...alignment,example_weights:weights,max_steps:6}});
    assert.equal(result.ok,true,JSON.stringify(result));
    assert.equal(result.history.length,result.accepted_steps+1);
    assert.ok(result.evaluations>=result.accepted_steps+1);
    assert.ok(result.work_units<=20000000);
    for(let i=1;i<result.history.length;i++) assert.ok(result.history[i]<=result.history[i-1]);
    const sum=weights.reduce((a,b)=>a+b,0);
    const objective=prototype=>examples.reduce((v,x,i)=>{
      const r=invoke('dtw',{x:prototype,y:x,options:alignment}); assert.equal(r.ok,true);
      return v+weights[i]/sum*r.squared_cost;
    },0);
    near(result.history[0],objective(seed));near(result.history.at(-1),objective(result.prototype));
    result.prototype.forEach((row,i)=>row.forEach((v,k)=>{
      assert.ok(Number.isFinite(v));
      if(featureWeights[k]===0) near(v,seed[i][k]);
    }));
  }
});

test('30 clustered datasets retain nearest labels, nonempty groups and measured inertia',()=>{
  for(let trial=0;trial<30;trial++) {
    const d=1+integer(2), groups=2+integer(2), countPerGroup=3;
    const data=[], centers=[];
    for(let group=0;group<groups;group++) {
      const members=Array.from({length:countPerGroup},()=>sample(2+integer(4),d,group*10));
      data.push(...members);centers.push(members[0]);
    }
    const alignment=trial%2===0?{window:1}:{};
    const result=invoke('cluster',{data,centers,options:{...alignment,max_iterations:6,max_dba_steps:6}});
    assert.equal(result.ok,true,JSON.stringify(result));
    assert.equal(result.labels.length,data.length);
    assert.equal(result.history.length,result.iterations+1);
    assert.ok(result.work_units<=20000000);
    for(let i=1;i<result.history.length;i++) assert.ok(result.history[i]<=result.history[i-1]);
    const counts=Array(groups).fill(0);let total=0;
    data.forEach((x,i)=>{
      const costs=result.centers.map(center=>invoke('dtw',{x:center,y:x,options:alignment}).squared_cost);
      const label=result.labels[i];counts[label]++;
      near(costs[label],Math.min(...costs));total+=costs[label];
    });
    assert.ok(counts.every(x=>x>0));near(result.inertia,total/data.length);near(result.history.at(-1),result.inertia);
  }
});

test('shared budget never publishes centers paired with stale assignments',()=>{
  const data=[[0],[2],[9],[11]],centers=[[0],[10]];
  for(let budget=8;budget<=32;budget++) {
    const result=invoke('cluster',{data,centers,options:{max_work_units:budget}});
    assert.equal(result.ok,true);assert.ok(result.work_units<=budget);
    let total=0;
    data.forEach((x,i)=>{
      const costs=result.centers.map(center=>invoke('dtw',{x:center,y:x}).squared_cost);
      const selected=costs[result.labels[i]];near(selected,Math.min(...costs));total+=selected;
    });
    near(result.inertia,total/data.length);
  }
});
