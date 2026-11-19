#!/usr/bin/env node
// Every budgeted operation must refuse a one-unit budget before doing the work,
// and accept a generous one. The refusal code differs by mechanism: iterative
// operations take max_work_units, matrix operations take max_cells. Operations
// with neither are listed as unbudgeted rather than counted as passes.
//
//   node scripts/budget_check.mjs
//   node scripts/budget_check.mjs --json
import {readdirSync, readFileSync} from 'node:fs';
import {run} from '../dist/engine.mjs';

const root = new URL('..', import.meta.url);
const dir = new URL('examples/', root);
const files = readdirSync(dir).filter((f) => f.endsWith('.json')).sort();

const rows = [];
const failures = [];
const BUDGET_KEYS = ['max_work_units', 'max_cells'];
const REFUSALS = new Set(['work_budget', 'cell_limit']);
// Each mechanism has its own documented cap; exceeding it is a validation
// error, not a budget refusal.
const GENEROUS = {max_work_units: 100000000, max_cells: 262144};

for (const file of files) {
  const doc = JSON.parse(readFileSync(new URL(file, dir), 'utf8'));
  if (!doc.operation) continue;

  let key = null;
  let refusal = null;
  for (const candidate of BUDGET_KEYS) {
    const probe = structuredClone(doc);
    probe.options = {...(probe.options ?? {}), [candidate]: 1};
    const answer = JSON.parse(run(JSON.stringify(probe)));
    if (answer.ok === false && answer.error.code === 'unknown_field') continue;
    key = candidate;
    refusal = answer.ok === true ? 'ok' : answer.error.code;
    break;
  }

  if (!key) {
    rows.push({file, operation: doc.operation, mechanism: '-', status: 'unbudgeted', detail: 'accepts neither budget key'});
    continue;
  }

  if (!REFUSALS.has(refusal)) {
    failures.push(`${file}: budget=1 returned ${refusal}, expected work_budget or cell_limit`);
    rows.push({file, operation: doc.operation, mechanism: key, status: 'fail', detail: refusal});
    continue;
  }

  const generous = structuredClone(doc);
  generous.options = {...(generous.options ?? {}), [key]: GENEROUS[key]};
  const accepted = JSON.parse(run(JSON.stringify(generous)));
  if (accepted.ok !== true) {
    failures.push(`${file}: generous ${key} was refused (${accepted.error?.code})`);
    rows.push({file, operation: doc.operation, mechanism: key, status: 'fail', detail: 'generous budget refused'});
    continue;
  }

  rows.push({file, operation: doc.operation, mechanism: key, status: 'ok', detail: refusal});
}

const budgeted = rows.filter((r) => r.status !== 'unbudgeted');
const passed = rows.filter((r) => r.status === 'ok').length;
const unbudgeted = rows.length - budgeted.length;

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({rows, failures, passed, budgeted: budgeted.length, unbudgeted}, null, 2));
} else {
  for (const row of rows) {
    const mark = row.status === 'ok' ? 'ok  ' : row.status === 'unbudgeted' ? 'n/a ' : 'FAIL';
    console.log(`${mark}  ${row.file.padEnd(30)} ${row.operation.padEnd(18)} ${row.mechanism.padEnd(16)} ${row.detail}`);
  }
  console.log('-'.repeat(92));
  console.log(`预算双向检查 ${passed}/${budgeted.length} 通过（预算=1 必须拒绝，宽裕预算必须成功）；${unbudgeted} 个操作不接收预算键，单独标注。`);
  if (failures.length) {
    console.log(`\n失败 ${failures.length} 项：`);
    for (const f of failures) console.log('  - ' + f);
  }
}
if (failures.length) process.exitCode = 1;
