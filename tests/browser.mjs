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
  await page.goto(base); await page.locator('#request').inputValue().then(v => assert.ok(v.length > 50));
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
  await page.locator('#request').fill('{"schema":"warpfit.request/1","operation":"loss","operation":"fit"}');
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
