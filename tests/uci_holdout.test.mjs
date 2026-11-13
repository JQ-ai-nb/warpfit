import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const read=name=>JSON.parse(readFileSync(`examples/${name}.json`,'utf8'));

test('real-data split has disjoint ordered source windows and excludes occupancy labels',()=>{
  const manifest=read('uci-model-split'), training=read('uci-model-train'), testing=read('uci-model-test-data');
  assert.equal(manifest.license,'CC-BY-4.0');
  assert.deepEqual(manifest.columns,['S1_Temp','S1_Light','S5_CO2']);
  assert.equal(manifest.train_offsets.length,16); assert.equal(manifest.test_offsets.length,16);
  assert.equal(training.data.length,16); assert.equal(testing.length,16);
  const all=[...manifest.train_offsets,...manifest.test_offsets];
  for(let i=0;i<all.length;i++) {
    assert.ok(all[i]>=0 && all[i]+manifest.window_length<=manifest.source_rows);
    if(i) assert.ok(all[i]>=all[i-1]+manifest.window_length);
  }
  for(const sample of [...training.data,...testing]) {
    assert.equal(sample.length,manifest.window_length);
    assert.ok(sample.every(row=>row.length===3 && row.every(Number.isFinite)));
  }
});

test('saved real-data model predicts later disjoint windows and reports a signed baseline comparison',()=>{
  const report=JSON.parse(execFileSync(process.execPath,['scripts/evaluate_holdout.mjs'],{encoding:'utf8',maxBuffer:2_000_000}));
  assert.equal(report.status,'passed');
  assert.equal(report.training.samples,16); assert.equal(report.heldout.samples,16);
  assert.equal(report.model.file_roundtrip_predict_matches_direct,true);
  assert.equal(report.heldout.labels.length,16);
  assert.equal(report.heldout.cluster_sizes.reduce((a,b)=>a+b,0),16);
  const final=report.heldout.learned_center_mean_squared_dtw;
  const initial=report.heldout.initial_center_mean_squared_dtw;
  assert.ok(Number.isFinite(final) && final>=0 && Number.isFinite(initial) && initial>=0);
  assert.equal(report.heldout.change_from_initial,final-initial);
  assert.ok(report.training.final_mean_squared_dtw<=report.training.initial_mean_squared_dtw+1e-9);
  assert.match(report.interpretation,/not classification accuracy/);
});
