"""Independently recompute KNN neighbours / votes and silhouette scores.

Pure Python, no third-party dependency: DTW is a direct dynamic program and the
silhouette uses the same textbook definition. The engine is only asked for its
answer; every number compared here is produced again on this side.
"""
import argparse
import json
import math
import random
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARTIFACT = ROOT / "artifacts" / "knn-reference.json"
EVIDENCE = ROOT / "docs" / "evidence" / "knn-reference.json"
# Provenance only: these describe the run, not the numbers it produced.
# engine_commit also moves with every commit, including the one that records the evidence,
# so --check-evidence would go stale by itself if it were compared.
VOLATILE = ("recorded_at_utc", "python", "engine_commit")
REFRESH_IGNORED = ("recorded_at_utc", "python")


def call(request):
    completed = subprocess.run(
        ["node", "bin/warpfit.mjs", "-"],
        cwd=ROOT,
        input=json.dumps(request),
        text=True,
        encoding="utf-8",
        capture_output=True,
    )
    if completed.returncode != 0:
        raise AssertionError(completed.stdout + completed.stderr)
    return json.loads(completed.stdout)


def dtw(x, y, window):
    n, m, d = len(x), len(y), len(x[0])
    inf = float("inf")
    previous = [inf] * (m + 1)
    previous[0] = 0.0
    for i in range(1, n + 1):
        current = [inf] * (m + 1)
        row = i - 1
        if window < 0:
            lower, upper = 0, m - 1
        elif n <= m:
            lower, upper = max(0, row - window), min(m - 1, row + (m - n) + window)
        else:
            lower, upper = max(0, row - (n - m) - window), min(m - 1, row + window)
        for j in range(lower + 1, upper + 2):
            column = j - 1
            cost = sum((x[row][k] - y[column][k]) ** 2 for k in range(d))
            current[j] = cost + min(previous[j], current[j - 1], previous[j - 1])
        previous = current
    return math.sqrt(previous[m])


def as_rows(series):
    # A flat list is one feature per sample; a list of lists is already rows.
    return [[value] for value in series] if isinstance(series[0], (int, float)) else series


def expected_knn(query, training, k, window):
    rows = [(item["label"], dtw(as_rows(query), as_rows(item["series"]), window)) for item in training]
    order = sorted(range(len(rows)), key=lambda i: (rows[i][1], i))
    chosen = [order[i] for i in range(k)]
    labels, votes, sums = [], [], []
    for index in chosen:
        label, distance = rows[index]
        if label in labels:
            position = labels.index(label)
            votes[position] += 1
            sums[position] += distance
        else:
            labels.append(label)
            votes.append(1)
            sums.append(distance)
    best = 0
    for position in range(1, len(labels)):
        if votes[position] > votes[best]:
            best = position
        elif votes[position] == votes[best] and sums[position] < sums[best]:
            best = position
    return {
        "label": labels[best],
        "labels": labels,
        "votes": votes,
        "order": chosen,
        "distances": [rows[i][1] for i in chosen],
    }


def silhouette(matrix, labels):
    n = len(labels)
    clusters = sorted(set(labels))
    total = 0.0
    for i in range(n):
        own = labels[i]
        same = [matrix[i][j] for j in range(n) if j != i and labels[j] == own]
        if not same:
            continue
        a = sum(same) / len(same)
        b = float("inf")
        for cluster in clusters:
            if cluster == own:
                continue
            other = [matrix[i][j] for j in range(n) if labels[j] == cluster]
            if other:
                b = min(b, sum(other) / len(other))
        if b == float("inf"):
            continue
        scale = max(a, b)
        if scale > 0:
            total += (b - a) / scale
    return total / n


def check_example():
    request = json.loads((ROOT / "examples/knn.json").read_text(encoding="utf-8"))
    response = call(request)
    assert response["ok"], response
    window = request["options"]["window"]
    k = request["options"]["k"]
    expected = expected_knn(request["query"], request["training"], k, window)
    assert response["label"] == expected["label"], (response["label"], expected)
    assert response["labels"] == expected["labels"], (response["labels"], expected)
    assert response["votes"] == expected["votes"], (response["votes"], expected)
    assert [n["train_index"] for n in response["neighbors"]] == expected["order"]
    for neighbor, distance in zip(response["neighbors"], expected["distances"]):
        assert abs(neighbor["distance"] - distance) <= 1e-12, (neighbor, distance)
    return request, response, expected


def randomized(seed=20261115, cases=24):
    rng = random.Random(seed)
    labels = ["up", "down", "flat"]
    checked = 0
    for _ in range(cases):
        dims = rng.randint(1, 3)

        def draw(length):
            rows = [[rng.randint(-3, 3) for _ in range(dims)] for _ in range(length)]
            return [row[0] for row in rows] if dims == 1 else rows

        training = [
            {"label": rng.choice(labels), "series": draw(rng.randint(1, 8))}
            for _ in range(rng.randint(3, 7))
        ]
        query = draw(rng.randint(1, 8))
        k = rng.randint(1, len(training))
        window = rng.choice([-1, 0, 1, 2])
        options = {"k": k}
        if window >= 0:
            options["window"] = window  # the wire rejects -1; omission means unbounded
        response = call({
            "schema": "warpfit.request/1",
            "operation": "knn",
            "query": query,
            "training": training,
            "options": options,
        })
        assert response["ok"], response
        expected = expected_knn(query, training, k, window)
        assert response["label"] == expected["label"], (response, expected)
        assert [n["train_index"] for n in response["neighbors"]] == expected["order"]
        checked += 1
    return checked


def check_silhouette():
    request = json.loads((ROOT / "examples/select-k.json").read_text(encoding="utf-8"))
    response = call(request)
    assert response["ok"], response
    window = request["options"]["window"]
    data = [as_rows(series) for series in request["data"]]
    matrix = [[dtw(a, b, window) for b in data] for a in data]
    for score in response["scores"]:
        expected = silhouette(matrix, score["labels"])
        assert abs(expected - score["silhouette"]) <= 1e-10, (score, expected)
    return request, response


def engine_commit():
    try:
        completed = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            capture_output=True,
        )
    except OSError:
        return "unknown"
    revision = completed.stdout.strip()
    return revision if completed.returncode == 0 and revision else "unknown"


def write_json(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    # newline="\n" keeps the checked-in evidence byte-identical across platforms.
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(payload)


def read_evidence():
    if not EVIDENCE.exists():
        return None
    try:
        return json.loads(EVIDENCE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def differences(recorded, current, ignored, prefix=""):
    keys = []
    if isinstance(recorded, dict) and isinstance(current, dict):
        for key in sorted(set(recorded) | set(current)):
            if not prefix and key in ignored:
                continue
            if key not in recorded or key not in current:
                keys.append(prefix + key)
            else:
                keys.extend(differences(recorded[key], current[key], ignored, prefix + key + "."))
    elif recorded != current:
        keys.append(prefix.rstrip(".") or "<root>")
    return keys


def main(argv):
    parser = argparse.ArgumentParser(description="Recompute KNN / silhouette reference numbers.")
    parser.add_argument("--evidence", action="store_true",
                        help="also refresh docs/evidence/knn-reference.json")
    parser.add_argument("--check-evidence", action="store_true",
                        help="compare with docs/evidence/knn-reference.json; exit 1 when stale")
    args = parser.parse_args(argv)

    request, response, expected = check_example()
    cases = randomized()
    selection_request, selection = check_silhouette()
    report = {
        "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
        "python": sys.version.split()[0],
        "engine_commit": engine_commit(),
        "knn_example": {
            "label": response["label"],
            "votes": response["votes"],
            "neighbor_indices": [n["train_index"] for n in response["neighbors"]],
            "reference_distances": expected["distances"],
        },
        "randomized_knn_cases": cases,
        "select_k_example": {
            "best_k": selection["best_k"],
            "silhouettes": {str(s["k"]): s["silhouette"] for s in selection["scores"]},
        },
        "status": "passed",
    }
    payload = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    recorded = read_evidence()
    missing = ["docs/evidence/knn-reference.json"]
    stale = missing if recorded is None else differences(recorded, report, VOLATILE)
    refresh = missing if recorded is None else differences(recorded, report, REFRESH_IGNORED)

    if args.check_evidence:
        if not stale:
            print("evidence: current")
            return 0
        print("evidence: STALE")
        for key in stale:
            print(f"  {key}")
        return 1

    write_json(ARTIFACT, payload)
    print(f"knn-reference: passed; {cases} randomized cases; {ARTIFACT.relative_to(ROOT).as_posix()}")

    if args.evidence:
        if not refresh:
            print("evidence: unchanged")
            return 0
        write_json(EVIDENCE, payload)
        print(f"evidence: updated; {EVIDENCE.relative_to(ROOT).as_posix()}")
        return 0

    print("evidence: current" if not stale else "evidence: STALE; run --check-evidence for keys")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
