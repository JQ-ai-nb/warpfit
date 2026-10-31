import http from 'node:http';
import { readFile, realpath } from 'node:fs/promises';
import { resolve, sep, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = await realpath(fileURLToPath(new URL('../web', import.meta.url)));
const mime = { '.html': 'text/html; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8' };
const port = Number(process.env.WARPFIT_PORT || 4194);
http.createServer(async (req, res) => {
  try {
    if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
    const url = new URL(req.url, 'http://localhost');
    const part = decodeURIComponent(url.pathname);
    const target = resolve(root, '.' + (part === '/' ? '/index.html' : part));
    if (!target.startsWith(root + sep)) throw new Error('Outside static root');
    const actual = await realpath(target);
    if (!actual.startsWith(root + sep)) throw new Error('Outside static root');
    const data = await readFile(actual);
    res.writeHead(200, { 'Content-Type': mime[extname(actual)] || 'text/plain; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
    res.end(req.method === 'HEAD' ? undefined : data);
  } catch { res.writeHead(404); res.end('Not found'); }
}).listen(port, '127.0.0.1', () => console.log(`WarpFit: http://127.0.0.1:${port}`));
