// Reproducible single-dataset workflow; no network or occupancy labels.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rmdir, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { run } from '../dist/engine.mjs';

const root=fileURLToPath(new URL('..',import.meta.url));
const text=await readFile(join(root,'examples/uci-model-train.json'),'utf8');
const testingText=await readFile(join(root,'examples/uci-model-test-data.json'),'utf8');
const manifestText=await readFile(join(root,'examples/uci-model-split.json'),'utf8');
const request=JSON.parse(text), testing=JSON.parse(testingText), manifest=JSON.parse(manifestText);
const hash=source=>createHash('sha256').update(source).digest('hex');
function calculate(source) {
  const result=JSON.parse(run(typeof source==='string'?source:JSON.stringify(source)));
  assert.equal(result.ok,true,JSON.stringify(result.error));
  return result;
}
const trained=calculate(text);
assert.ok(!['work_budget','evaluation_budget'].includes(trained.clustering.stop),'Training budget did not complete the requested work');
await mkdir(join(root,'work'),{recursive:true});
const folder=await mkdtemp(join(root,'work','holdout-model-'));
const modelPath=join(folder,'model.json');
let predicted;
const serialized=JSON.stringify(trained.model,null,2)+'\n';
try {
  await writeFile(modelPath,serialized,{encoding:'utf8',flag:'wx'});
  predicted=JSON.parse(execFileSync(process.execPath,
    [join(root,'bin/warpfit-model.mjs'),'predict',modelPath,join(root,'examples/uci-model-test-data.json')],
    {cwd:root,encoding:'utf8',maxBuffer:2_000_000}));
  assert.equal(predicted.ok,true,JSON.stringify(predicted.error));
  assert.deepEqual(predicted,calculate({schema:request.schema,operation:'predict',model:trained.model,data:testing}));
} finally {
  await unlink(modelPath).catch(error=>{if(error.code!=='ENOENT')throw error;});
  await rmdir(folder);
}
const initialModel={...trained.model,centers:trained.seed_indices.map(i=>trained.prepared[i].series)};
const baseline=calculate({schema:request.schema,operation:'predict',model:initialModel,data:testing});
const meanSquared=distances=>distances.reduce((sum,value)=>sum+value*value,0)/distances.length;
const sizes=labels=>trained.model.centers.map((_,i)=>labels.filter(label=>label===i).length);
const learnedCost=meanSquared(predicted.distances), initialCost=meanSquared(baseline.distances);
const report={
  recorded_at_utc:new Date().toISOString(),
  dataset:'UCI Room Occupancy Estimation, fixed disjoint windows',
  source:manifest.source, source_zip_sha256:manifest.source_zip_sha256, data_license:manifest.license,
  input_sha256:{training:hash(text),testing:hash(testingText),manifest:hash(manifestText)},
  split:{train_offsets:manifest.train_offsets,test_offsets:manifest.test_offsets,raw_points:manifest.window_length,
    features:manifest.columns,prepared_points:request.options.target_count},
  training:{samples:request.data.length,seed_indices:trained.seed_indices,cluster_sizes:sizes(trained.clustering.labels),
    initial_mean_squared_dtw:trained.clustering.history[0],final_mean_squared_dtw:trained.clustering.inertia,
    history:trained.clustering.history,stop:trained.clustering.stop,total_work_units:trained.total_work_units},
  heldout:{samples:testing.length,labels:predicted.labels,cluster_sizes:sizes(predicted.labels),
    learned_center_mean_squared_dtw:learnedCost,initial_center_mean_squared_dtw:initialCost,
    change_from_initial:learnedCost-initialCost,distances:predicted.distances},
  model:{schema:trained.model.schema,file_sha256:hash(serialized),file_roundtrip_predict_matches_direct:true},
  status:'passed',
  interpretation:'Distance to centers on later disjoint windows, not classification accuracy. Initial and learned centers are both derived from training only. A lower training objective does not guarantee a lower held-out cost.',
  limitations:['One controlled experiment and fixed split; no cross-building or user validation',
    'Per-series normalization removes absolute sensor levels; no occupancy labels are used',
    'No forecasting, anomaly threshold or production quality claim'],
};
await mkdir(join(root,'artifacts'),{recursive:true});
await writeFile(join(root,'artifacts/uci-model-holdout.json'),JSON.stringify(report,null,2)+'\n');
process.stdout.write(JSON.stringify(report,null,2)+'\n');
