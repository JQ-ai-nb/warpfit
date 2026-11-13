import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');

const browser = await chromium.launch({ headless: true, ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}) });
const report = { browser: browser.version(), checks: [], pageErrors: [], externalRequests: [] };
const base = process.env.WARPFIT_URL || 'http://127.0.0.1:4194';
await mkdir('artifacts', { recursive: true });
try {
  const page = await browser.newPage({ viewport: { width: 1440, height: 1060 }, deviceScaleFactor: 1 });
  page.on('pageerror', e => report.pageErrors.push(e.message));
  page.on('request', req => { if (!req.url().startsWith(base) && !req.url().startsWith('blob:')) report.externalRequests.push(req.url()); });
  await page.goto(base);
  await page.waitForFunction(() => document.getElementById('request').value.length > 50);
  async function execute() {
    await page.locator('#run').click(); await page.waitForFunction(() => !document.getElementById('run').disabled);
    return JSON.parse(await page.locator('#output').textContent());
  }
  let result = await execute(); assert.equal(result.ok, true); assert.equal(result.operation, 'fit');
  assert.ok(result.history.at(-1) < result.history[0] / 10); assert.equal(await page.locator('.plot svg').count(), 2);
  report.checks.push('prototype fitting and optimization charts');
  await page.screenshot({ path: 'artifacts/desktop.png', fullPage: true });
  for (const name of ['training', 'retrieval']) {
    await page.locator(`[data-example=${name}]`).click();
    await page.waitForFunction(n => JSON.parse(document.getElementById('request').value).operation === n, name === 'training' ? 'loss' : 'rank');
    result = await execute(); assert.equal(result.ok, true);
    if (name === 'training') assert.equal(await page.locator('canvas.heat').count(), 1);
    else assert.equal(result.matches[0].id, 'same');
    report.checks.push(`${name} workflow and visualization`);
  }
  const downloadPromise = page.waitForEvent('download'); await page.locator('#download').click();
  const download = await downloadPromise; assert.equal(download.suggestedFilename(), 'warpfit-rank.json');
  report.checks.push('result JSON download');
  for (const [name, operation] of [['align','dtw'],['dba','dba'],['clusters','cluster'],['pipeline','pipeline'],['uci-room','pipeline']]) {
    await page.locator(`[data-example=${name}]`).click();
    await page.waitForFunction(n => document.querySelector(`[data-example="${n}"]`).getAttribute('aria-pressed') === 'true', name);
    await page.waitForFunction(n => JSON.parse(document.getElementById('request').value).operation === n, operation);
    result = await execute(); assert.equal(result.ok, true); assert.equal(result.operation, operation);
    if (operation === 'dtw') { assert.equal(result.distance,0); assert.equal(await page.locator('canvas.heat').count(),1); }
    if (operation === 'dba') assert.ok(result.history.at(-1)<result.history[0]);
    if (operation === 'cluster') { assert.deepEqual(result.labels,[0,0,0,1,1,1]); assert.equal(await page.locator('table.rank').count(),1); }
    if (operation === 'pipeline') { assert.deepEqual(result.clustering.labels,name === 'uci-room' ? [0,1,0,1,1,1] : [0,0,1,1]); assert.equal(await page.locator('table.rank').count(),1); }
    report.checks.push(`${name} workflow and visualization`);
  }
  await page.locator('#file').setInputFiles({name:'sample.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify({schema:'warpfit.request/1',operation:'dtw',x:[2],y:[5]}))});
  await page.waitForFunction(() => document.getElementById('request').value.includes('"x":[2]'));
  result=await execute(); assert.equal(result.distance,3); report.checks.push('local JSON import computes user input');
  await page.locator('#request').fill(JSON.stringify({schema:'warpfit.request/1',operation:'preprocess',series:[1,2,3],options:{target_count:5}}));
  result=await execute();assert.equal(result.ok,true);assert.equal(result.prepared.series.length,5);
  assert.equal(await page.locator('.plot svg').count(),1);report.checks.push('preprocessing visualization works for custom input');
  await page.locator('#request').fill(JSON.stringify({schema:'warpfit.request/1',operation:'pipeline',data:[[0],[2],[9],[11]],seed_indices:[0,2],options:{normalize:false,max_work_units:8}}));
  result=await execute();assert.equal(result.clustering.stop,'work_budget');
  assert.equal(await page.locator('#badge').textContent(),'预算耗尽');report.checks.push('pipeline nested budget stop is visible');
  await page.locator('#request').fill('{"schema":"warpfit.request/1","operation":"loss","operation":"fit"}');
  assert.equal(await page.locator('#download').isDisabled(), true);
  assert.equal(await page.locator('.metric').count(), 0);
  report.checks.push('changed input invalidates earlier displayed result');
  result = await execute(); assert.equal(result.ok, false); assert.equal(await page.locator('#badge').textContent(), '输入 / 预算错误');
  report.checks.push('duplicate JSON keys rejected without page error');
  const huge = Array.from({ length: 512 }, (_, i) => Math.sin(i / 25));
  await page.locator('#request').fill(JSON.stringify({ schema: 'warpfit.request/1', operation: 'fit', seed: huge, examples: [huge.map(v => v + 0.2)], options: { max_steps: 200, max_work_units: 100000000 } }));
  await page.locator('#run').click(); await page.locator('#cancel').click();
  assert.equal(await page.locator('#badge').textContent(), '已取消'); assert.equal(await page.locator('#run').isEnabled(), true);
  report.checks.push('worker cancellation discards incomplete result');
  await page.setViewportSize({ width: 390, height: 844 });
  await page.locator('[data-example=prototype]').click(); await page.waitForFunction(() => JSON.parse(document.getElementById('request').value).operation === 'fit');
  result = await execute(); assert.equal(result.ok, true);
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
  await page.screenshot({ path: 'artifacts/mobile.png', fullPage: true });
  report.checks.push('390px mobile layout and working compute');
  assert.deepEqual(report.pageErrors, []); assert.deepEqual(report.externalRequests, []);
  report.status = 'passed';
} finally {
  await browser.close();
  await writeFile('artifacts/browser.json', JSON.stringify(report, null, 2));
}
console.log(JSON.stringify(report));
