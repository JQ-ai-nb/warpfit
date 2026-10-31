#!/usr/bin/env node
import { readFile, writeFile } from 'node:fs/promises';
import { run } from '../dist/engine.mjs';

const args = process.argv.slice(2);
const usage = 'Usage: node bin/warpfit.mjs REQUEST.json|- [--out RESULT.json]\n';
if (args.length === 1 && ['--help', '-h'].includes(args[0])) {
  process.stdout.write(usage); process.exit(0);
}
if (args.length === 1 && args[0] === '--version') {
  process.stdout.write('WarpFit 0.1.0\n'); process.exit(0);
}
const failure = (code, message) => ({ schema: 'warpfit.response/1', ok: false, error: { code, message } });
let response;
try {
  if (!([1, 3].includes(args.length)) || (args.length === 3 && args[1] !== '--out')) {
    throw new Error(usage.trim());
  }
  let data;
  if (args[0] === '-') {
    const chunks = []; let size = 0;
    for await (const chunk of process.stdin) {
      size += chunk.length;
      if (size > 2_000_000) throw new Error('Input exceeds 2,000,000 bytes.');
      chunks.push(chunk);
    }
    data = Buffer.concat(chunks);
  } else {
    const { stat } = await import('node:fs/promises');
    if ((await stat(args[0])).size > 2_000_000) throw new Error('Input exceeds 2,000,000 bytes.');
    data = await readFile(args[0]);
    if (data.length > 2_000_000) throw new Error('Input exceeds 2,000,000 bytes.');
  }
  const source = new TextDecoder('utf-8', { fatal: true }).decode(data);
  // Keep the original text: parsing and reserializing here would conceal duplicate keys.
  response = JSON.parse(run(source));
} catch (error) {
  response = failure('io', error.message);
}
const text = JSON.stringify(response, null, 2) + '\n';
try {
  if (args.length === 3 && args[1] === '--out') await writeFile(args[2], text, 'utf8');
  else process.stdout.write(text);
} catch (error) {
  process.stderr.write(JSON.stringify(failure('output_io', error.message)) + '\n');
  process.exitCode = 2;
}
if (!process.exitCode) {
  process.exitCode = response.ok
    ? (['evaluation_budget', 'work_budget'].includes(response.stop) ? 3 : 0)
    : (['work_budget', 'cell_limit'].includes(response.error?.code) ? 3 : 2);
}
