import { spawnSync } from 'node:child_process';
import { readFile, writeFile, mkdir, copyFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const result = spawnSync('moon', ['build', 'api', '--target', 'js', '--release', '--deny-warn'], {
  cwd: root, stdio: 'inherit'
});
if (result.error || result.status !== 0) process.exit(result.status || 1);
const code = (await readFile(join(root, '_build/js/release/build/api/api.js'), 'utf8'))
  .replace(/^\/\/# sourceMappingURL=.*$/gm, '');
const core = join(process.env.MOON_HOME || join(homedir(), '.moon'), 'lib', 'core');
for (const target of ['dist', 'web']) {
  const folder = join(root, target);
  await mkdir(folder, { recursive: true });
  await writeFile(join(folder, 'engine.mjs'), code);
  for (const name of ['LICENSE', 'NOTICE']) {
    await copyFile(join(core, name), join(folder, `MOONBIT_CORE_${name}`));
  }
  await copyFile(join(root, 'LICENSE'), join(folder, 'WARPFIT_LICENSE'));
}
await copyFile(join(root, 'docs', 'REAL_DATA.md'), join(root, 'web', 'UCI_ROOM_DATA_NOTICE.md'));
await mkdir(join(root, 'web', 'examples'), { recursive: true });
for (const name of ['prototype', 'training', 'retrieval', 'align', 'dba', 'clusters', 'pipeline', 'uci-room']) {
  await copyFile(join(root, 'examples', `${name}.json`), join(root, 'web', 'examples', `${name}.json`));
}
console.log('Built the MoonBit JSON engine for Node and the browser; included license notices.');
