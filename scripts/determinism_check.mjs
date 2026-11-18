#!/usr/bin/env node
// Determinism check: the same request must produce the same bytes, twice, in
// one process. Running twice in the same process is deliberate - it also
// catches state left behind between calls, which a fresh process would hide.
//
//   node scripts/determinism_check.mjs
//   node scripts/determinism_check.mjs --json
import {run} from '../dist/engine.mjs';

function lcg(seed) {
  let state = seed >>> 0;
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

const value = (rand) => Math.round((rand() * 20 - 10) * 100) / 100;
const pointSeries = (rand, length, dims) =>
  Array.from({length}, () => Array.from({length: dims}, () => value(rand)));
const flatSeries = (rand, length) => Array.from({length}, () => value(rand));
const labeled = (rand, count, length, labels) =>
  Array.from({length: count}, (_, i) => ({label: labels[i % labels.length], series: pointSeries(rand, length, 1)}));

function cases() {
  const rand = lcg(20261118);
  const data = Array.from({length: 6}, () => pointSeries(rand, 6, 1));
  const flat = Array.from({length: 6}, () => flatSeries(rand, 6));
  return [
    ['dtw', {x: pointSeries(rand, 8, 2), y: pointSeries(rand, 9, 2), options: {window: 2}}],
    ['dba', {
      seed: flatSeries(rand, 5),
      examples: [flatSeries(rand, 6), flatSeries(rand, 7), flatSeries(rand, 5)],
      options: {window: 2, max_steps: 10, max_work_units: 2000000},
    }],
    ['cluster', {
      data: flat,
      centers: [flat[0], flat[3]],
      options: {window: 1, max_iterations: 5, max_dba_steps: 10, max_work_units: 2000000},
    }],
    ['knn', {query: pointSeries(rand, 5, 1), training: labeled(rand, 6, 5, ['a', 'b']), options: {k: 3, window: 1}}],
    ['knn_pruned', {query: pointSeries(rand, 5, 1), training: labeled(rand, 6, 5, ['a', 'b']), options: {k: 3, window: 1}}],
    ['medoids', {data, cluster_count: 2, options: {max_iterations: 10}}],
    ['motifs', {series: flatSeries(rand, 20), window: 4, top_k: 3, options: {max_windows: 32}}],
    ['cross_validate', {
      data: Array.from({length: 8}, () => flatSeries(rand, 5)),
      labels: ['a', 'b', 'a', 'b', 'a', 'b', 'a', 'b'],
      options: {k: 1, folds: 2, window: 1},
    }],
    ['outliers', {data, options: {k: 2, window: 1}}],
    ['describe', {series: pointSeries(rand, 12, 3)}],
    ['subsequence_topk', {query: pointSeries(rand, 3, 1), target: pointSeries(rand, 12, 1), top_k: 3}],
    ['select_k', {
      data: flat,
      candidates: [2, 3],
      options: {window: 1, max_iterations: 5, max_dba_steps: 10, max_work_units: 4000000, first_index: 0},
    }],
  ];
}

const rows = [];
const failures = [];
let bytes = 0;

for (const [operation, body] of cases()) {
  const request = JSON.stringify({schema: 'warpfit.request/1', operation, ...body});
  const first = run(request);
  const second = run(request);
  bytes += first.length;
  if (first !== second) {
    failures.push(`${operation}: two runs differ`);
    rows.push({operation, status: 'fail', bytes: first.length});
    continue;
  }
  const answer = JSON.parse(first);
  if (answer.ok !== true) {
    failures.push(`${operation}: generated request failed (${answer.error?.code})`);
    rows.push({operation, status: 'fail', bytes: first.length, detail: answer.error?.code});
    continue;
  }
  rows.push({operation, status: 'ok', bytes: first.length});
}

const passed = rows.filter((r) => r.status === 'ok').length;
if (process.argv.includes('--json')) {
  console.log(JSON.stringify({rows, failures, passed, total: rows.length, bytes}, null, 2));
} else {
  for (const row of rows) {
    console.log(`${row.status === 'ok' ? 'ok  ' : 'FAIL'}  ${row.operation.padEnd(18)} ${String(row.bytes).padStart(7)} bytes${row.detail ? '  ' + row.detail : ''}`);
  }
  console.log('-'.repeat(60));
  console.log(`确定性检查 ${passed}/${rows.length} 通过（同一进程内连续两次请求逐字节相同，共 ${bytes} 字节）。`);
  if (failures.length) {
    console.log(`\n失败 ${failures.length} 项：`);
    for (const f of failures) console.log('  - ' + f);
    process.exitCode = 1;
  }
}
