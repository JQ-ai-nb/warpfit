#!/usr/bin/env node
import { readFile, stat, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { run } from '../dist/engine.mjs';

const args = process.argv.slice(2);
const usage = 'Usage:\n  node bin/warpfit-model.mjs train REQUEST.json MODEL.json\n' +
  '  node bin/warpfit-model.mjs predict MODEL.json DATA.json [--out RESULT.json]\n' +
  'DATA.json is an array of raw sequences. Output files are created only if absent.\n';
if (args.length === 1 && ['--help', '-h'].includes(args[0])) {
  process.stdout.write(usage); process.exit(0);
}
const error = (code, message) => ({ schema: 'warpfit.response/1', ok: false, error: { code, message } });
async function readText(path) {
  if ((await stat(path)).size > 2_000_000) throw new Error('Input exceeds 2,000,000 bytes.');
  const data = await readFile(path);
  if (data.length > 2_000_000) throw new Error('Input exceeds 2,000,000 bytes.');
  return new TextDecoder('utf-8', { fatal: true }).decode(data);
}
async function writeNew(path, text, inputPaths) {
  if (inputPaths.some(input => resolve(input) === resolve(path))) throw new Error('Output path must differ from input paths.');
  await writeFile(path, text, { encoding: 'utf8', flag: 'wx' });
}
let response;
let code = 0;
let outputHandled = false;
try {
  if (args[0] === 'train' && args.length === 3) {
    const source = await readText(args[1]);
    response = JSON.parse(run(source));
    if (response.ok && !['train_model', 'auto_train_model'].includes(response.operation)) response = error('operation', 'Training request must use train_model or auto_train_model.');
    if (response.ok && ['work_budget', 'evaluation_budget'].includes(response.clustering?.stop)) {
      code = 3;
    } else if (response.ok) {
      await writeNew(args[2], JSON.stringify(response.model, null, 2) + '\n', [args[1]]);
      response = { schema: 'warpfit.model-tool/1', ok: true, operation: 'train',
        model_path: args[2], cluster_count: response.model.centers.length,
        stop: response.clustering.stop, work_units: response.total_work_units ?? response.clustering.work_units,
        ...(response.seed_indices ? { seed_indices: response.seed_indices, seed_work_units: response.seed_work_units } : {}) };
    }
  } else if (args[0] === 'predict' && (args.length === 3 || (args.length === 5 && args[3] === '--out'))) {
    const model = await readText(args[1]);
    const data = await readText(args[2]);
    const source = `{"schema":"warpfit.request/1","operation":"predict","model":${model},"data":${data}}`;
    if (Buffer.byteLength(source, 'utf8') > 2_000_000) throw new Error('Combined request exceeds 2,000,000 bytes.');
    response = JSON.parse(run(source));
    if (args.length === 5) {
      await writeNew(args[4], JSON.stringify(response, null, 2) + '\n', [args[1], args[2]]);
      outputHandled = true;
    }
    if (!response.ok) code = ['work_budget', 'cell_limit'].includes(response.error?.code) ? 3 : 2;
  } else {
    response = error('usage', usage.trim());
  }
} catch (cause) {
  response = error('io', cause.message);
}
if (!response.ok && !code) code = ['work_budget', 'cell_limit'].includes(response.error?.code) ? 3 : 2;
if (!outputHandled) process.stdout.write(JSON.stringify(response, null, 2) + '\n');
process.exitCode = code;
