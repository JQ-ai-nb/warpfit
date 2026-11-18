#!/usr/bin/env node
import { readFile, writeFile } from 'node:fs/promises';
import { run } from '../dist/engine.mjs';

const args = process.argv.slice(2);
const usage = 'Usage: node bin/warpfit.mjs REQUEST.json|- [--out RESULT.json]\n';

// Failures carry a stable code and a message that is safe to hand to a caller.
// The underlying Node error (absolute paths, errno) goes to stderr only: a
// response document is public output, a stack trace is not.
class CliError extends Error {
  constructor(code, message, detail = '') {
    super(message);
    this.code = code;
    this.detail = detail;
  }
}

if (args.length === 1 && ['--help', '-h'].includes(args[0])) {
  process.stdout.write(usage); process.exit(0);
}
if (args.length === 1 && args[0] === '--version') {
  const metadata = JSON.parse(await readFile(new URL('../package.json', import.meta.url), 'utf8'));
  process.stdout.write(`WarpFit ${metadata.version}\n`); process.exit(0);
}

const failure = (code, message) => ({ schema: 'warpfit.response/1', ok: false, error: { code, message } });
let response;

try {
  if (!([1, 3].includes(args.length)) || (args.length === 3 && args[1] !== '--out')) {
    throw new CliError('usage', usage.trim());
  }

  let data;
  if (args[0] === '-') {
    const chunks = []; let size = 0;
    for await (const chunk of process.stdin) {
      size += chunk.length;
      if (size > 2_000_000) throw new CliError('io', 'input exceeds 2,000,000 bytes');
      chunks.push(chunk);
    }
    data = Buffer.concat(chunks);
  } else {
    const { stat } = await import('node:fs/promises');
    try {
      if ((await stat(args[0])).size > 2_000_000) {
        throw new CliError('io', 'input exceeds 2,000,000 bytes');
      }
      data = await readFile(args[0]);
    } catch (error) {
      if (error instanceof CliError) throw error;
      throw new CliError('io', 'cannot read the request file', error.message);
    }
    if (data.length > 2_000_000) throw new CliError('io', 'input exceeds 2,000,000 bytes');
  }

  let source;
  try {
    source = new TextDecoder('utf-8', { fatal: true }).decode(data);
  } catch {
    throw new CliError('io', 'request file is not valid UTF-8');
  }

  // Keep the original text: parsing and reserialising here would conceal
  // duplicate keys, which the engine is expected to reject itself.
  const raw = run(source);
  try {
    response = JSON.parse(raw);
  } catch {
    throw new CliError('engine', 'engine response is not valid JSON');
  }
} catch (error) {
  if (error instanceof CliError) {
    if (error.detail) process.stderr.write(error.detail + '\n');
    response = failure(error.code, error.message);
  } else {
    process.stderr.write((error?.stack || String(error)) + '\n');
    response = failure('engine', 'unexpected failure');
  }
}

const text = JSON.stringify(response, null, 2) + '\n';
try {
  if (args.length === 3 && args[1] === '--out') await writeFile(args[2], text, 'utf8');
  else process.stdout.write(text);
} catch (error) {
  process.stderr.write(String(error?.message || error) + '\n');
  process.stderr.write(JSON.stringify(failure('output_io', 'cannot write the output file')) + '\n');
  process.exitCode = 2;
}

if (!process.exitCode) {
  const stop = response.stop ?? response.clustering?.stop;
  process.exitCode = response.ok
    ? (['evaluation_budget', 'work_budget'].includes(stop) ? 3 : 0)
    : (['work_budget', 'cell_limit'].includes(response.error?.code) ? 3 : 2);
}
