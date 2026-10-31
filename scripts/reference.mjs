// JSON-lines bridge for optional, pinned tslearn numerical cross-checks.
import readline from 'node:readline';
import { run } from '../dist/engine.mjs';
for await (const line of readline.createInterface({ input: process.stdin })) process.stdout.write(run(line) + '\n');
