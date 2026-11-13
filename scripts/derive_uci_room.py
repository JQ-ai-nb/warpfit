"""Reproduce the small, attributed room-sensor example from the UCI ZIP.

This does not download data. Pass the ZIP downloaded from the UCI page listed
in docs/REAL_DATA.md. --check verifies the checked-in derivative exactly.
"""
import argparse
import csv
import hashlib
import io
import json
import math
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent.parent
SOURCE_SHA256 = "a0db79ee96ea297c22458ac77a28fba20d41246e75d24b2655ca3ab624cc08fd"
OFFSETS = (0, 1800, 3600, 5400, 7200, 9000)
COLUMNS = ("S1_Temp", "S1_Light", "S5_CO2")
LENGTH = 60


def derive(path: Path) -> dict:
    if hashlib.sha256(path.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise ValueError("Source ZIP checksum differs; inspect the dataset revision before deriving")
    with ZipFile(path) as archive:
        with archive.open("Occupancy_Estimation.csv") as file:
            rows = list(csv.DictReader(io.TextIOWrapper(file, encoding="utf-8-sig")))
    if len(rows) != 10129:
        raise ValueError("Unexpected source row count")
    data = []
    for offset in OFFSETS:
        window = rows[offset : offset + LENGTH]
        if len(window) != LENGTH:
            raise ValueError("Source lacks an entire required window")
        series = [[float(row[column]) for column in COLUMNS] for row in window]
        if not all(math.isfinite(value) for row in series for value in row):
            raise ValueError("Source contains a non-finite value")
        data.append(series)
    return {
        "schema": "warpfit.request/1",
        "operation": "pipeline",
        "data": data,
        "seed_indices": [0, 3],
        "options": {
            "target_count": 48,
            "normalize": True,
            "window": 4,
            "max_iterations": 6,
            "max_dba_steps": 3,
            "max_work_units": 20000000,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_zip", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    derived = derive(args.source_zip)
    target = ROOT / "examples/uci-room.json"
    if args.check:
        if json.loads(target.read_text(encoding="utf-8")) != derived:
            raise SystemExit("Checked-in example differs from selected source records")
        print("Verified 6 fixed windows x 60 points x 3 sensor features from the cited source.")
    else:
        target.write_text(json.dumps(derived, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
        print("Wrote", target)


if __name__ == "__main__":
    main()
