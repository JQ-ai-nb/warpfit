#!/usr/bin/env node
// Every operation the engine dispatches must have at least one runnable
// example and a mention in docs/API.md, and every example must name an
// operation the engine knows. Adding an operation without either is how the
// four gaps this checks for appeared in the first place.
//
//   node scripts/api_coverage.mjs
//   node scripts/api_coverage.mjs --json
import {readdirSync, readFileSync} from 'node:fs';

const root = new URL('..', import.meta.url);
const source = readFileSync(new URL('api/wire.mbt', root), 'utf8');
const api = readFileSync(new URL('docs/API.md', root), 'utf8');
const dir = new URL('examples/', root);

// Dispatch arms are four-space indented `"name" => [...]` entries.
const operations = [...new Set([...source.matchAll(/^ {4}"([a-z_]+)"\s*=>/gm)].map((m) => m[1]))].sort();

const byOperation = new Map();
const unknown = [];
const dataFiles = [];
for (const file of readdirSync(dir).filter((f) => f.endsWith('.json')).sort()) {
  const doc = JSON.parse(readFileSync(new URL(file, dir), 'utf8'));
  if (!doc.operation) {
    dataFiles.push(file);
    continue;
  }
  if (!operations.includes(doc.operation)) {
    unknown.push(`${file}: operation ${doc.operation} is not in the dispatch table`);
    continue;
  }
  byOperation.set(doc.operation, [...(byOperation.get(doc.operation) ?? []), file]);
}

const rows = operations.map((operation) => {
  const examples = byOperation.get(operation) ?? [];
  const documented = api.includes(operation);
  return {
    operation,
    examples: examples.length,
    example: examples[0] ?? '-',
    documented,
    ok: examples.length > 0 && documented,
  };
});

const failures = [];
for (const row of rows) {
  if (row.examples === 0) failures.push(`${row.operation}: no example request`);
  if (!row.documented) failures.push(`${row.operation}: not mentioned in docs/API.md`);
}
failures.push(...unknown);

const passed = rows.filter((r) => r.ok).length;
if (process.argv.includes('--json')) {
  console.log(JSON.stringify({rows, failures, passed, total: rows.length, dataFiles}, null, 2));
} else {
  for (const row of rows) {
    const mark = row.ok ? 'ok  ' : 'FAIL';
    console.log(`${mark}  ${row.operation.padEnd(18)} example: ${row.example.padEnd(28)} documented: ${row.documented ? 'yes' : 'no'}`);
  }
  console.log('-'.repeat(80));
  console.log(`API 覆盖 ${passed}/${rows.length}：每个操作都有示例且出现在 docs/API.md；${dataFiles.length} 个数据文件按设计跳过。`);
  if (failures.length) {
    console.log(`\n失败 ${failures.length} 项：`);
    for (const failure of failures) console.log('  - ' + failure);
  }
}
if (failures.length) process.exitCode = 1;
