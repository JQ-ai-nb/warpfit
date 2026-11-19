#!/usr/bin/env node
// Verify fixed reference results and report browser and registry evidence for
// the exact source version. An unpublished version can have pending evidence.
//
//   node scripts/evidence_report.mjs
//   node scripts/evidence_report.mjs --json
import {readFileSync, existsSync, readdirSync} from 'node:fs';

const root = new URL('..', import.meta.url);
const manifest = readFileSync(new URL('moon.mod', root), 'utf8');
const version = manifest.match(/^version\s*=\s*"([^"]+)"\s*$/m)?.[1];
const moduleName = manifest.match(/^name\s*=\s*"([^"]+)"\s*$/m)?.[1];
if (!moduleName || !version) throw new Error('moon.mod is missing a module name or version');
const packageVersion = JSON.parse(readFileSync(new URL('package.json', root), 'utf8')).version;

const read = (name) => {
  const path = new URL(`docs/evidence/${name}`, root);
  if (!existsSync(path)) throw new Error(`missing evidence file: docs/evidence/${name}`);
  return JSON.parse(readFileSync(path, 'utf8'));
};

function evidenceForVersion(kind) {
  const prefix = `${kind}-${version}-`;
  return readdirSync(new URL('docs/evidence/', root))
    .filter((file) => file.startsWith(prefix) && /^\d{8}\.json$/.test(file.slice(prefix.length)))
    .sort().at(-1);
}

const rows = [];
const problems = [];
const release = { module: moduleName, version, browser: {status: 'pending'}, registry: {status: 'pending'} };
function claim(label, expected, actual, source, note = '') {
  const ok = expected === actual;
  rows.push({label, expected, actual, source, note, ok});
  if (!ok) problems.push(`${label}: expected ${expected}, found ${actual} (${source})`);
}
claim('源码与工具版本', version, packageVersion, 'moon.mod / package.json');

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

const browserFile = evidenceForVersion('browser');
if (browserFile) {
  const browser = read(browserFile);
  const priorProblems = problems.length;
  claim('浏览器证据版本', version, browser.version, browserFile);
  claim('浏览器检查状态', 'passed', browser.status, browserFile);
  const checks = browser.checks?.length ?? 0;
  claim('浏览器有实际检查', true, Array.isArray(browser.checks) && checks > 0, browserFile);
  claim('浏览器页面错误', 0, browser.pageErrors?.length, browserFile);
  claim('浏览器外部请求', 0, browser.externalRequests?.length, browserFile);
  release.browser = {file: browserFile, checks, origin: browser.origin,
    status: problems.length === priorProblems ? 'passed' : 'mismatch'};
}

const consumerFile = evidenceForVersion('consumer-registry');
if (consumerFile) {
  const consumer = read(consumerFile);
  const priorProblems = problems.length;
  claim('注册表证据版本', version, consumer.version, consumerFile);
  claim('注册表模块', moduleName, consumer.module, consumerFile);
  claim('注册表消费模式', 'registry', consumer.mode, consumerFile);
  claim('注册表安装验证', true, consumer.registry_install_verified, consumerFile);
  claim('注册表消费状态', 'passed', consumer.status, consumerFile);
  claim('注册表不依赖源码', false, consumer.source_checkout_dependency, consumerFile);
  claim('注册表无本地路径依赖', false, consumer.path_dependency, consumerFile);
  const checks = consumer.checks?.length ?? 0;
  claim('注册表有实际检查', true, Array.isArray(consumer.checks) && checks > 0, consumerFile);
  release.registry = {file: consumerFile, checks, targets: consumer.runtime_targets,
    status: problems.length === priorProblems ? 'passed' : 'mismatch'};
}

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({rows, release, problems, status: problems.length ? 'mismatch' : 'consistent'}, null, 2));
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
  for (const [label, item] of [['浏览器', release.browser], ['注册表消费', release.registry]]) {
    if (item.status === 'pending') console.log(`${version} ${label}：当前版本证据待记录`);
    else console.log(`${version} ${label}：${item.status}（${item.checks} 项，${item.file}）`);
  }
  if (problems.length) {
    console.log(`\n不一致 ${problems.length} 处：`);
    for (const p of problems) console.log('  - ' + p);
  } else {
    console.log(`\n版本与已记录的证据一致，共核对 ${rows.length} 项。`);
  }
}
if (problems.length) process.exitCode = 1;
