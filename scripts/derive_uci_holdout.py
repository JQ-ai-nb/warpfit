"""Derive disjoint training/test windows from the cited local UCI ZIP.

No download or label-driven selection. --check verifies all derivatives.
"""
import argparse
import json
import math
from pathlib import Path

from derive_uci_room import COLUMNS, LENGTH, ROOT, SOURCE_SHA256, read_source

TRAIN_OFFSETS = tuple(range(0, 4800, 300))
TEST_OFFSETS = tuple(range(5000, 9800, 300))


def derive(path: Path) -> dict[str, object]:
    rows = read_source(path)

    def windows(offsets: tuple[int, ...]) -> list:
        output = []
        for offset in offsets:
            block = rows[offset:offset + LENGTH]
            if len(block) != LENGTH:
                raise ValueError("Missing required complete source window")
            sample = [[float(row[column]) for column in COLUMNS] for row in block]
            if not all(math.isfinite(value) for row in sample for value in row):
                raise ValueError("Non-finite source value")
            output.append(sample)
        return output

    training = {
        "schema": "warpfit.request/1", "operation": "auto_train_model",
        "data": windows(TRAIN_OFFSETS), "cluster_count": 2, "first_index": 0,
        "options": {
            "target_count": 48, "normalize": True, "window": 4,
            "max_iterations": 10, "max_dba_steps": 5, "max_work_units": 20000000,
        },
    }
    manifest = {
        "schema": "warpfit.dataset-split/1",
        "source": "https://doi.org/10.24432/C5P605",
        "source_zip_sha256": SOURCE_SHA256, "source_rows": 10129,
        "license": "CC-BY-4.0", "columns": list(COLUMNS), "window_length": LENGTH,
        "train_offsets": list(TRAIN_OFFSETS), "test_offsets": list(TEST_OFFSETS),
        "selection": "Fixed row positions; no date, time or occupancy labels used. Test rows occur after all training rows.",
        "limitations": "One controlled experiment, no ground-truth evaluation or business accuracy claim. Per-series normalization removes absolute levels.",
    }
    return {
        "uci-model-train.json": training,
        "uci-model-test-data.json": windows(TEST_OFFSETS),
        "uci-model-split.json": manifest,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_zip", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = derive(args.source_zip)
    for name, value in files.items():
        path = ROOT/"examples"/name
        if args.check:
            if json.loads(path.read_text(encoding="utf-8")) != value:
                raise SystemExit("Derivative differs from fixed source records: " + name)
        else:
            path.write_text(json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print("Verified" if args.check else "Wrote", "16 training + 16 later test windows, 60 points x 3 features; source SHA-256 checked.")


if __name__ == "__main__":
    main()
