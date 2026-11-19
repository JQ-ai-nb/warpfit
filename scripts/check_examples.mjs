#!/usr/bin/env node
// Run every example through the CLI twice and require a stable, successful
// answer. This catches broken examples even when no individual test uses them.
//
// Files without an `operation` field are inputs to the model workflow (training
// and prediction payloads), not requests; they are listed as skipped, not
// counted as passes.
//
//   node scripts/check_examples.mjs
//   node scripts/check_examples.mjs --json
import {readdirSync, readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';

const root = new URL('..', import.meta.url);
const dir = new URL('examples/', root);
const files = readdirSync(dir).filter((f) => f.endsWith('.json')).sort();

const rows = [];
const failures = [];

for (const file of files) {
  const raw = readFileSync(new URL(file, dir), 'utf8');
  let doc;
  try {
    doc = JSON.parse(raw);
  } catch {
    failures.push(`${file}: not valid JSON`);
    rows.push({file, status: 'fail', operation: '-', note: 'invalid JSON'});
    continue;
  }
  if (!doc.operation) {
    rows.push({file, status: 'data', operation: '-', note: 'model input, not a request'});
    continue;
  }
  const run = () => spawnSync(process.execPath, ['bin/warpfit.mjs', `examples/${file}`], {
    cwd: root,
    encoding: 'utf8',
    timeout: 30_000,
  });
  const first = run();
  const second = run();
  const failure = [first, second].find((result) => result.status !== 0);
  if (failure) {
    failures.push(`${file}: exit ${failure.status}: ${(failure.error?.message || failure.stderr || '').slice(0, 120)}`);
    rows.push({file, status: 'fail', operation: doc.operation, note: 'non-zero exit'});
    continue;
  }
  let answer;
  try {
    answer = JSON.parse(first.stdout);
  } catch {
    failures.push(`${file}: stdout is not JSON`);
    rows.push({file, status: 'fail', operation: doc.operation, note: 'bad stdout'});
    continue;
  }
  if (answer.ok !== true) {
    failures.push(`${file}: ok=false (${answer.error?.code || 'unknown'})`);
    rows.push({file, status: 'fail', operation: doc.operation, note: 'ok=false'});
    continue;
  }
  if (answer.operation !== doc.operation) {
    failures.push(`${file}: asked for ${doc.operation}, answered ${answer.operation}`);
    rows.push({file, status: 'fail', operation: doc.operation, note: 'operation mismatch'});
    continue;
  }
  if (first.stdout !== second.stdout) {
    failures.push(`${file}: two runs produced different bytes`);
    rows.push({file, status: 'fail', operation: doc.operation, note: 'not deterministic'});
    continue;
  }
  rows.push({file, status: 'ok', operation: doc.operation, note: `${first.stdout.length} bytes, stable`});
}

const requests = rows.filter((r) => r.status !== 'data');
const passed = rows.filter((r) => r.status === 'ok').length;
const skipped = rows.filter((r) => r.status === 'data').length;

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({rows, failures, passed, requests: requests.length, skipped}, null, 2));
} else {
  for (const row of rows) {
    const mark = row.status === 'ok' ? 'ok  ' : row.status === 'data' ? 'data' : 'FAIL';
    console.log(`${mark}  ${row.file.padEnd(30)} ${String(row.operation).padEnd(18)} ${row.note}`);
  }
  console.log('-'.repeat(88));
  console.log(`示例请求 ${passed}/${requests.length} 通过（每个跑两次，输出逐字节一致）；数据文件 ${skipped} 个按设计跳过。`);
  if (failures.length) {
    console.log(`\n失败 ${failures.length} 项：`);
    for (const f of failures) console.log('  - ' + f);
  }
}
if (failures.length) process.exitCode = 1;
