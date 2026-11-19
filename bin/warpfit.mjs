#!/usr/bin/env node
import { constants, fstatSync, ReadStream } from 'node:fs';
import { open, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
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
let inputIdentity;
let inputPath;

async function saveResponse(path, text) {
  const overlap = () => new CliError('output_io', 'output file must differ from the input file');
  if (inputPath !== undefined && resolve(path) === inputPath) throw overlap();

  // Open without truncating first. Checking the open file also handles aliases,
  // including symbolic links and hard links to the file that was read.
  const output = await open(path, constants.O_CREAT | constants.O_WRONLY);
  try {
    if (inputIdentity) {
      const target = await output.stat({ bigint: true });
      if (target.dev === inputIdentity.dev && target.ino === inputIdentity.ino) throw overlap();
    }
    await output.truncate(0);
    await output.writeFile(text, 'utf8');
  } finally {
    await output.close();
  }
}

try {
  if (!([1, 3].includes(args.length)) || (args.length === 3 && args[1] !== '--out')) {
    throw new CliError('usage', usage.trim());
  }

  let data;
  if (args[0] === '-') {
    // A shell may redirect a regular file to stdin. A pipe has no file identity
    // to compare with the output path.
    if (args.length === 3 && process.stdin instanceof ReadStream) {
      inputIdentity = fstatSync(process.stdin.fd, { bigint: true });
    }
    const chunks = []; let size = 0;
    for await (const chunk of process.stdin) {
      size += chunk.length;
      if (size > 2_000_000) throw new CliError('io', 'input exceeds 2,000,000 bytes');
      chunks.push(chunk);
    }
    data = Buffer.concat(chunks);
  } else {
    inputPath = resolve(args[0]);
    try {
      const input = await open(inputPath, 'r');
      try {
        inputIdentity = await input.stat({ bigint: true });
        if (inputIdentity.size > 2_000_000n) {
          throw new CliError('io', 'input exceeds 2,000,000 bytes');
        }
        data = await input.readFile();
      } finally {
        await input.close();
      }
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
  if (args.length === 3 && args[1] === '--out') await saveResponse(args[2], text);
  else process.stdout.write(text);
} catch (error) {
  if (!(error instanceof CliError)) process.stderr.write(String(error?.message || error) + '\n');
  const message = error instanceof CliError ? error.message : 'cannot write the output file';
  process.stderr.write(JSON.stringify(failure('output_io', message)) + '\n');
  process.exitCode = 2;
}

if (!process.exitCode) {
  const stop = response.stop ?? response.clustering?.stop;
  process.exitCode = response.ok
    ? (['evaluation_budget', 'work_budget'].includes(stop) ? 3 : 0)
    : (['work_budget', 'cell_limit'].includes(response.error?.code) ? 3 : 2);
}
