// Run from the extracted demo, without a build, package install or network service.
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, readFile, rmdir, unlink, writeFile } from 'node:fs/promises';
import { join, posix } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const report = {
  schema: 'warpfit.demo-check/1', recorded_at_utc: new Date().toISOString(),
  node: process.version, runtime_root: root, checks: [], status: 'failed',
};
const hash = data => createHash('sha256').update(data).digest('hex');
const text = path => readFile(join(root, path), 'utf8');
const json = async path => JSON.parse(await text(path));
const close = (actual, expected) => assert.ok(Math.abs(actual - expected) <= 1e-9 * (1 + Math.abs(expected)), `${actual} != ${expected}`);
function call(args, { input, expectedCode = 0 } = {}) {
  const result = spawnSync(process.execPath, args, {
    cwd: root, input, encoding: 'utf8', timeout: 90_000, maxBuffer: 2_000_000,
  });
  assert.ifError(result.error);
  assert.equal(result.status, expectedCode, result.stdout + result.stderr);
  return result.stdout;
}
const cli = name => JSON.parse(call(['bin/warpfit.mjs', `examples/${name}.json`]));
const passed = (name, detail = {}) => report.checks.push({ name, status: 'passed', ...detail });

async function checkWebFiles(manifest) {
  const server = spawn(process.execPath, ['scripts/serve.mjs'], {
    cwd: root, env: { ...process.env, WARPFIT_PORT: '0' }, stdio: ['ignore', 'pipe', 'pipe'],
  });
  let errors = '';
  server.stderr.on('data', chunk => { errors += chunk; });
  const exited = new Promise(resolve => { server.once('exit', resolve); server.once('error', resolve); });
  let timer;
  try {
    const base = await new Promise((resolve, reject) => {
      let output = '';
      timer = setTimeout(() => reject(new Error(`Preview server did not become ready: ${errors}`)), 10_000);
      server.once('error', reject);
      server.once('exit', code => reject(new Error(`Preview server exited with ${code}: ${errors}`)));
      server.stdout.on('data', chunk => {
        output += chunk;
        const match = output.match(/WarpFit: (http:\/\/127\.0\.0\.1:\d+)/);
        if (match) resolve(match[1]);
      });
    });
    clearTimeout(timer);
    const assets = manifest.files.filter(file => file.path.startsWith('web/'));
    for (const asset of assets) {
      const route = asset.path === 'web/index.html' ? '/' : '/' + asset.path.slice(4);
      const response = await fetch(base + route, { signal: AbortSignal.timeout(10_000) });
      assert.equal(response.status, 200, route);
      assert.equal(hash(Buffer.from(await response.arrayBuffer())), asset.sha256, route);
      if (route.endsWith('.mjs')) assert.match(response.headers.get('content-type'), /javascript/);
    }
    assert.equal((await fetch(base + '/missing-file', { signal: AbortSignal.timeout(10_000) })).status, 404);
    assert.equal((await fetch(base + '/', { method: 'POST', signal: AbortSignal.timeout(10_000) })).status, 405);
    passed('static_preview_assets', { files: assets.length, loopback_only: true });
  } finally {
    clearTimeout(timer);
    server.kill();
    const deadline = setTimeout(() => server.kill('SIGKILL'), 5_000);
    try { await exited; } finally { clearTimeout(deadline); }
  }
}

try {
  const manifest = await json('DEMO_MANIFEST.json');
  assert.equal(manifest.schema, 'warpfit.demo-bundle/1');
  assert.equal(manifest.module, 'JQ-ai-nb/warpfit');
  const metadata = await json('package.json');
  assert.equal(manifest.version, metadata.version);
  assert.ok(manifest.files.length > 0);
  const names = new Set();
  for (const file of manifest.files) {
    assert.equal(typeof file.path, 'string');
    assert.match(file.path, /^[A-Za-z0-9_.\/-]+$/);
    assert.ok(!file.path.startsWith('/') && posix.normalize(file.path) === file.path && !file.path.split('/').includes('..'));
    assert.ok(!names.has(file.path), file.path); names.add(file.path);
    const data = await readFile(join(root, file.path));
    assert.equal(data.length, file.bytes, file.path);
    assert.equal(hash(data), file.sha256, file.path);
  }
  for (const required of ['README.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'docs/REAL_DATA.md',
    'dist/engine.mjs', 'dist/MOONBIT_CORE_LICENSE', 'dist/MOONBIT_CORE_NOTICE', 'dist/WARPFIT_LICENSE',
    'web/engine.mjs', 'web/MOONBIT_CORE_LICENSE', 'web/MOONBIT_CORE_NOTICE', 'web/WARPFIT_LICENSE',
    'web/UCI_ROOM_DATA_NOTICE.md']) assert.ok(names.has(required), required);
  assert.equal(hash(await readFile(join(root, 'dist/engine.mjs'))), hash(await readFile(join(root, 'web/engine.mjs'))));
  const advertised = [...(await text('web/index.html')).matchAll(/data-example="([^"]+)"/g)].map(match => match[1]);
  assert.equal(new Set(advertised).size, advertised.length, 'duplicate data-example entry');
  for (const name of advertised) assert.ok(names.has(`web/examples/${name}.json`), `web/examples/${name}.json`);
  report.version = manifest.version;
  report.source_commit = manifest.source_commit;
  report.source_dirty = manifest.source_dirty;
  const moon = spawnSync('moon', ['version'], { cwd: root, encoding: 'utf8', timeout: 5_000 });
  report.sdk_absence_verified = moon.error?.code === 'ENOENT';
  if (process.env.WARPFIT_REQUIRE_NO_SDK === '1') assert.equal(report.sdk_absence_verified, true);
  passed('bundle_integrity', { files: manifest.files.length, matching_browser_and_cli_engine: true,
    workbench_examples_verified: advertised.length });

  assert.equal(call(['bin/warpfit.mjs', '--version']).trim(), `WarpFit ${manifest.version}`);
  passed('cli_version', { version: manifest.version });

  const knn = JSON.parse(call(['bin/warpfit.mjs', 'web/examples/knn.json']));
  assert.equal(knn.ok, true); assert.equal(knn.label, 'rise'); assert.deepEqual(knn.votes, [2, 1]);
  const selectK = JSON.parse(call(['bin/warpfit.mjs', 'web/examples/select-k.json']));
  assert.equal(selectK.ok, true); assert.equal(selectK.best_k, 3); assert.equal(selectK.scores.length, 2);
  assert.ok(selectK.scores[1].silhouette > selectK.scores[0].silhouette,
    `${selectK.scores[1].silhouette} <= ${selectK.scores[0].silhouette}`);
  passed('recent_neighbor_classification', {
    knn_label: knn.label, knn_votes: knn.votes, best_k: selectK.best_k,
    silhouette_by_k: selectK.scores.map(score => [score.k, score.silhouette]),
  });

  const alignment = cli('align');
  assert.equal(alignment.ok, true); close(alignment.distance, 0);
  assert.deepEqual(alignment.path[0], [0, 0]); assert.deepEqual(alignment.path.at(-1), [3, 3]);
  const diagonal = await json('examples/align.json'); diagonal.options.window = 0;
  const restricted = JSON.parse(call(['bin/warpfit.mjs', '-'], { input: JSON.stringify(diagonal) }));
  assert.equal(restricted.ok, true); close(restricted.squared_cost, 2);
  passed('constrained_alignment', { window_1_distance: alignment.distance, window_0_squared_cost: restricted.squared_cost });

  const dba = cli('dba');
  assert.equal(dba.ok, true); assert.equal(dba.prototype.length, 4);
  assert.ok(!['work_budget', 'evaluation_budget'].includes(dba.stop));
  assert.ok(dba.history.at(-1) < dba.history[0]);
  passed('template_learning', { initial_cost: dba.history[0], final_cost: dba.history.at(-1) });

  const pipeline = cli('pipeline');
  assert.equal(pipeline.ok, true); assert.deepEqual(pipeline.clustering.labels, [0, 0, 1, 1]);
  assert.ok(pipeline.prepared.every(sample => sample.series.length === 5 && sample.normalized));
  passed('resample_normalize_cluster', { labels: pipeline.clustering.labels });

  await mkdir(join(root, 'work'), { recursive: true });
  const folder = await mkdtemp(join(root, 'work', 'demo-model-'));
  const model = join(folder, 'model.json');
  try {
    const trained = JSON.parse(call(['bin/warpfit-model.mjs', 'train', 'examples/model_train.json', model]));
    assert.equal(trained.ok, true); assert.equal(trained.cluster_count, 2);
    const original = await readFile(model, 'utf8');
    const predicted = JSON.parse(call(['bin/warpfit-model.mjs', 'predict', model, 'examples/model_predict_data.json']));
    assert.equal(predicted.ok, true); assert.deepEqual(predicted.labels, [0, 1, 0]);
    const overwrite = JSON.parse(call(['bin/warpfit-model.mjs', 'train', 'examples/model_train.json', model], { expectedCode: 2 }));
    assert.equal(overwrite.ok, false); assert.equal(await readFile(model, 'utf8'), original);
    passed('model_save_reload_predict', { labels: predicted.labels, existing_model_preserved: true });
  } finally {
    await unlink(model).catch(error => { if (error.code !== 'ENOENT') throw error; });
    await rmdir(folder);
  }

  const subsequence = cli('subsequence');
  assert.equal(subsequence.ok, true);
  assert.deepEqual([subsequence.start, subsequence.end, subsequence.distance], [2, 4, 0]);
  passed('subsequence_localization', { start: subsequence.start, end: subsequence.end, distance: subsequence.distance });

  const holdout = JSON.parse(call(['scripts/evaluate_holdout.mjs']));
  assert.equal(holdout.status, 'passed');
  assert.equal(holdout.training.samples, 16); assert.equal(holdout.heldout.samples, 16);
  assert.equal(holdout.model.file_roundtrip_predict_matches_direct, true);
  close(holdout.heldout.initial_center_mean_squared_dtw, 135.3533878965);
  close(holdout.heldout.learned_center_mean_squared_dtw, 83.9299692157);
  passed('real_data_holdout', {
    train_samples: 16, test_samples: 16,
    initial_center_mean_squared_dtw: holdout.heldout.initial_center_mean_squared_dtw,
    learned_center_mean_squared_dtw: holdout.heldout.learned_center_mean_squared_dtw,
    interpretation: 'Fixed-split distance check, not classification accuracy or a claim about other datasets.',
  });

  await checkWebFiles(manifest);
  assert.equal(report.checks.length, 10, `expected 10 check groups, got ${report.checks.length}`);
  report.status = 'passed';
} catch (error) {
  report.error = error.stack || String(error);
  process.exitCode = 1;
}
await mkdir(join(root, 'artifacts'), { recursive: true });
await writeFile(join(root, 'artifacts/demo-check.json'), JSON.stringify(report, null, 2) + '\n');
process.stdout.write(JSON.stringify(report, null, 2) + '\n');
