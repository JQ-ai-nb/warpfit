"""Optional independent preprocessing and tslearn distance reference.

Centers are learned by WarpFit; this checks their inference results and the
initial-center baseline, not equivalence of complete clustering optimizers.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone

deps = os.environ.get("WARPFIT_REFERENCE_DEPS")
if deps:
    sys.path.insert(0, deps)
os.environ.setdefault("NUMBA_NUM_THREADS", "1")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
import numpy as np
import tslearn
from tslearn.metrics import dtw

root = Path(__file__).resolve().parent.parent
training = json.loads((root/"examples/uci-model-train.json").read_text(encoding="utf-8"))
testing = json.loads((root/"examples/uci-model-test-data.json").read_text(encoding="utf-8"))
driver = """import {readFileSync} from 'node:fs';
import {run} from './dist/engine.mjs';
const input=JSON.parse(readFileSync(0,'utf8'));
const train=JSON.parse(run(JSON.stringify(input.training)));
if(!train.ok) throw Error(JSON.stringify(train));
const request={schema:'warpfit.request/1',operation:'predict',model:train.model,data:input.testing};
const prediction=JSON.parse(run(JSON.stringify(request)));
const initial={...train.model,centers:train.seed_indices.map(i=>train.prepared[i].series)};
const baseline=JSON.parse(run(JSON.stringify({...request,model:initial})));
console.log(JSON.stringify({train,prediction,baseline}));"""
output = json.loads(subprocess.check_output(
    ["node", "--input-type=module", "-e", driver], cwd=root,
    input=json.dumps(dict(training=training, testing=testing)), text=True, encoding="utf-8", timeout=120,
))
train, prediction, baseline = (output[k] for k in ("train", "prediction", "baseline"))
assert prediction["ok"] and baseline["ok"]
assert train["clustering"]["stop"] != "work_budget"
options = training["options"]


def prepare(sample):
    sample = np.asarray(sample, dtype=float)
    old = np.linspace(0.0, 1.0, sample.shape[0])
    new = np.linspace(0.0, 1.0, options["target_count"])
    sampled = np.column_stack([np.interp(new, old, sample[:, k]) for k in range(sample.shape[1])])
    means, stds = sampled.mean(axis=0), sampled.std(axis=0)
    result = np.zeros_like(sampled)
    varying = stds > options.get("epsilon", 1e-12)
    result[:, varying] = (sampled[:, varying] - means[varying]) / stds[varying]
    return result


prepared_train, prepared_test = [list(map(prepare, samples)) for samples in (training["data"], testing)]
max_preprocess_error = 0.0
for expected, actual in zip(prepared_train + prepared_test, train["prepared"] + prediction["prepared"]):
    actual = np.asarray(actual["series"])
    max_preprocess_error = max(max_preprocess_error, float(np.max(np.abs(expected - actual))))
    np.testing.assert_allclose(actual, expected, rtol=1e-8, atol=1e-8)


def distances(samples, centers):
    return np.array([[dtw(s, c, global_constraint="sakoe_chiba", sakoe_chiba_radius=options["window"])
                      for c in centers] for s in samples])


learned = distances(prepared_test, [np.asarray(c) for c in train["model"]["centers"]])
initial = distances(prepared_test, [prepared_train[i] for i in train["seed_indices"]])
max_distance_error = 0.0
for reference, result in ((learned, prediction), (initial, baseline)):
    actual = np.asarray(result["distances_to_centers"])
    max_distance_error = max(max_distance_error, float(np.max(np.abs(actual - reference))))
    np.testing.assert_allclose(actual, reference, rtol=1e-8, atol=1e-8)
    assert np.argmin(reference, axis=1).tolist() == result["labels"]

learned_cost, initial_cost = (float(np.mean(np.min(matrix, axis=1)**2)) for matrix in (learned, initial))
workflow = json.loads((root/"artifacts/uci-model-holdout.json").read_text(encoding="utf-8"))
assert np.isclose(workflow["heldout"]["learned_center_mean_squared_dtw"], learned_cost, rtol=1e-8, atol=1e-8)
assert np.isclose(workflow["heldout"]["initial_center_mean_squared_dtw"], initial_cost, rtol=1e-8, atol=1e-8)
report = dict(
    recorded_at_utc=datetime.now(timezone.utc).isoformat(), reference="tslearn / NumPy",
    tslearn_version=tslearn.__version__, numpy_version=np.__version__,
    training_samples=len(prepared_train), heldout_samples=len(prepared_test),
    preprocessing_values_checked=sum(x.size for x in prepared_train + prepared_test),
    distance_comparisons=int(learned.size + initial.size),
    max_preprocess_absolute_error=max_preprocess_error, max_distance_absolute_error=max_distance_error,
    reference_learned_mean_squared_dtw=learned_cost, reference_initial_mean_squared_dtw=initial_cost,
    checked="Independent interpolation/standardization, all center distances, nearest labels and reported holdout means; centers learned by WarpFit",
    limitations="Single dataset and fixed split, no ground-truth accuracy or complete optimizer equivalence", status="passed",
)
(root/"artifacts/uci-model-holdout-reference.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
print(json.dumps(report))
