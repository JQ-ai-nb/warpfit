#!/usr/bin/env node
// Print every numerical claim the project makes, next to the evidence file that
// records it, and fail when the two disagree. This exists because the counts in
// the docs had drifted from the evidence twice: prose is not a source of truth,
// a re-runnable check is.
//
//   node scripts/evidence_report.mjs
//   node scripts/evidence_report.mjs --json
import {readFileSync, existsSync} from 'node:fs';

const root = new URL('..', import.meta.url);
const read = (name) => {
  const path = new URL(`docs/evidence/${name}`, root);
  if (!existsSync(path)) throw new Error(`missing evidence file: docs/evidence/${name}`);
  return JSON.parse(readFileSync(path, 'utf8'));
};

const rows = [];
const problems = [];
function claim(label, expected, actual, source, note = '') {
  const ok = expected === actual;
  rows.push({label, expected, actual, source, note, ok});
  if (!ok) problems.push(`${label}: docs say ${expected}, evidence says ${actual} (${source})`);
}

// A count written into a test *name* is still evidence, but it is text: say so
// rather than pretending it is a structured field.
function countInTestNames(name, pattern, expected, label) {
  const doc = read(name);
  const text = (doc.results || []).map((r) => r.stdout || '').join('\n');
  const found = text.match(pattern);
  const actual = found ? Number(found[1].replace(/,/g, '')) : null;
  claim(label, expected, actual, name, 'test-name text');
}

const hard = read('hard-reference.json');
claim('tslearn 硬 DTW 用例', 160, hard.cases.weighted_dtw, 'hard-reference.json');
claim('tslearn 单步 DBA 用例', 80, hard.cases.weighted_one_step_dba, 'hard-reference.json');
claim('tslearn 聚类用例', 9, hard.cases.cluster_workflow, 'hard-reference.json');
claim('tslearn 预处理用例', 100, hard.cases.preprocess, 'hard-reference.json');
claim('tslearn 完整流程用例', 1, hard.cases.full_pipeline, 'hard-reference.json');

const ts = read('tslearn.json');
claim('Soft-DTW 参考用例', 60, ts.cases, 'tslearn.json');

const sub = read('subsequence-reference.json');
claim('子序列 tslearn 对照', 120, sub.cases, 'subsequence-reference.json');

const knn = read('knn-reference.json');
claim('kNN 随机参考用例', 24, knn.randomized_knn_cases, 'knn-reference.json');

countInTestNames('clean-current.json', /(\d[\d,]*) hard DTW cases/, 240, '全路径穷举');
countInTestNames('clean-current.json', /(\d[\d,]*) small subsequence cases/, 256, '子序列路径枚举');
countInTestNames('clean-current.json', /full path across (\d[\d,]*) weighted cases/, 1200, '两行 DP 对照');

const holdout = read('uci-model-holdout.json');
// The split is recorded as two offset lists; the sample counts live one level
// down, next to the fitted model. Read the lists, not an assumed field name.
claim('真实数据训练段', 16, holdout.split.train_offsets.length, 'uci-model-holdout.json');
claim('真实数据留出段', 16, holdout.split.test_offsets.length, 'uci-model-holdout.json');
claim('真实数据训练样本', 16, holdout.training.samples, 'uci-model-holdout.json');
claim('真实数据留出样本', 16, holdout.heldout.samples, 'uci-model-holdout.json');

const browser = read('browser-0.2.2-20261118.json');
claim('浏览器检查', 24, browser.checks.length, 'browser-0.2.2-20261118.json');
claim('浏览器页面错误', 0, browser.pageErrors.length, 'browser-0.2.2-20261118.json');

const consumer = read('consumer-registry-0.2.2-20261118.json');
claim('注册表消费检查', 10, consumer.checks.length, 'consumer-registry-0.2.2-20261118.json');
claim('注册表安装验证', true, consumer.registry_install_verified, 'consumer-registry-0.2.2-20261118.json');

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({rows, problems, status: problems.length ? 'mismatch' : 'consistent'}, null, 2));
} else {
  const pad = (s, n) => String(s).padEnd(n);
  console.log('证据类型'.padEnd(22) + '用例/项'.padEnd(10) + '误差/结果'.padEnd(26) + '来源');
  console.log('-'.repeat(88));
  for (const row of rows) {
    const value = row.actual === null ? '未找到' : String(row.actual);
    const flag = row.ok ? '' : '  <-- MISMATCH';
    console.log(pad(row.label, 22) + pad(row.expected, 10) + pad(value, 26) + row.source + flag);
  }
  console.log('-'.repeat(88));
  const maxErr = Math.max(
    hard.max_absolute_error.dtw,
    hard.max_absolute_error.dba,
    hard.max_absolute_error.cluster,
    hard.max_absolute_error.preprocess,
  );
  console.log(`数值对照最大绝对误差（tslearn 0.6.4）：${maxErr.toExponential(3)}；容差 ${hard.tolerance}`);
  if (problems.length) {
    console.log(`\n不一致 ${problems.length} 处：`);
    for (const p of problems) console.log('  - ' + p);
    process.exitCode = 1;
  } else {
    console.log(`\n一致性检查通过：${rows.length} 项声明与证据文件逐项一致。`);
  }
}
