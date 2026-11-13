"""Independently recompute final real-data cluster distances with tslearn.

Optional: install tslearn and numpy separately; the MoonBit library does not
need them. WARPFIT_REFERENCE_DEPS can point at an isolated reference install.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone

reference_deps = os.environ.get("WARPFIT_REFERENCE_DEPS")
if reference_deps:
    sys.path.insert(0, reference_deps)
import numpy as np
import tslearn
from tslearn.metrics import dtw

root = Path(__file__).resolve().parent.parent
response = json.loads(subprocess.check_output(
    ["node", "bin/warpfit.mjs", "examples/uci-room.json"], cwd=root, text=True, encoding="utf-8"
))
if not response["ok"]:
    raise AssertionError(response)
samples = [np.asarray(item["series"], dtype=float) for item in response["prepared"]]
clustering = response["clustering"]
centers = [np.asarray(center, dtype=float) for center in clustering["centers"]]
costs = np.array([[dtw(s, c, global_constraint="sakoe_chiba", sakoe_chiba_radius=4) ** 2
                   for c in centers] for s in samples])
labels = np.argmin(costs, axis=1).tolist()
inertia = float(np.min(costs, axis=1).mean())
assert labels == clustering["labels"], (labels, clustering["labels"])
assert np.isclose(inertia, clustering["inertia"], rtol=1e-8, atol=1e-8)
report = {
    "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
    "dataset": "UCI Room Occupancy Estimation (fixed six-window derivative)",
    "tslearn_version": tslearn.__version__,
    "numpy_version": np.__version__,
    "sample_count": len(samples),
    "centers": len(centers),
    "distance_evaluations": int(costs.size),
    "reference_labels": labels,
    "reference_inertia": inertia,
    "warpfit_inertia": clustering["inertia"],
    "inertia_absolute_difference": abs(inertia - clustering["inertia"]),
    "method": "tslearn recomputes distances to WarpFit's returned centers and prepared series; no ground-truth classification claim",
    "status": "passed",
}
(root / "artifacts").mkdir(exist_ok=True)
(root / "artifacts/uci-room-reference.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print(json.dumps(report, ensure_ascii=False))
