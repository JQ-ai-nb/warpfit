import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');

await mkdir('work/browser-downloads', { recursive: true });
const browser = await chromium.launch({ headless: true, downloadsPath: resolve('work/browser-downloads'), ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}) });
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
  for (const [name, operation] of [['align','dtw'],['dba','dba'],['clusters','cluster'],['pipeline','pipeline'],['uci-room','pipeline'],['subsequence','subsequence']]) {
    await page.locator(`[data-example=${name}]`).click();
    await page.waitForFunction(n => document.querySelector(`[data-example="${n}"]`).getAttribute('aria-pressed') === 'true', name);
    await page.waitForFunction(n => JSON.parse(document.getElementById('request').value).operation === n, operation);
    result = await execute(); assert.equal(result.ok, true); assert.equal(result.operation, operation);
    if (operation === 'dtw') { assert.equal(result.distance,0); assert.equal(await page.locator('canvas.heat').count(),1); }
    if (operation === 'dba') assert.ok(result.history.at(-1)<result.history[0]);
    if (operation === 'cluster') { assert.deepEqual(result.labels,[0,0,0,1,1,1]); assert.equal(await page.locator('table.rank').count(),1); }
    if (operation === 'pipeline') { assert.deepEqual(result.clustering.labels,name === 'uci-room' ? [0,1,0,1,1,1] : [0,0,1,1]); assert.equal(await page.locator('table.rank').count(),1); }
    if (operation === 'subsequence') { assert.deepEqual([result.start,result.end,result.distance],[2,4,0]); assert.equal(await page.locator('canvas.heat').count(),1); await page.screenshot({path:'artifacts/subsequence.png',fullPage:true}); }
    report.checks.push(`${name} workflow and visualization`);
  }
  await page.locator('[data-example=model_train]').click();
  await page.waitForFunction(() => document.querySelector('[data-example=model_train]').getAttribute('aria-pressed') === 'true');
  result=await execute(); assert.equal(result.operation,'auto_train_model'); assert.equal(result.model.schema,'warpfit.cluster-model/1');
  await page.screenshot({path:'artifacts/model.png',fullPage:true});
  const modelDownloadPromise=page.waitForEvent('download'); await page.locator('#save-model').click();
  const modelDownload=await modelDownloadPromise;
  assert.equal(modelDownload.suggestedFilename(),'warpfit-cluster-model.json');
  const savedModel=JSON.parse(await readFile(await modelDownload.path(),'utf8'));
  assert.deepEqual(savedModel,result.model);
  await page.locator('#use-model').click();
  let predictRequest=JSON.parse(await page.locator('#request').inputValue());
  assert.equal(predictRequest.operation,'predict');
  predictRequest.data=[[5,10,15],[30,20,10]];
  await page.locator('#request').fill(JSON.stringify(predictRequest));
  result=await execute(); assert.deepEqual(result.labels,[0,1]); assert.equal(await page.locator('table.rank').count(),1);
  await page.locator('#model-file').setInputFiles({name:'model.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(savedModel))});
  await page.waitForFunction(()=>document.getElementById('scenario-hint').textContent.includes('已载入模型'));
  predictRequest=JSON.parse(await page.locator('#request').inputValue()); predictRequest.data=[[30,20,10]];
  await page.locator('#request').fill(JSON.stringify(predictRequest));
  result=await execute(); assert.deepEqual(result.labels,[1]);
  report.checks.push('model train, download, reimport and prediction');
  await page.locator('#model-file').setInputFiles({name:'duplicate-model.json',mimeType:'application/json',buffer:Buffer.from('{"schema":"warpfit.cluster-model/1","schema":"duplicate"}')});
  await page.waitForFunction(()=>document.getElementById('request').value.includes('"schema":"duplicate"'));
  result=await execute(); assert.equal(result.error.code,'json');
  assert.equal(await page.locator('#save-model').isDisabled(),true);
  report.checks.push('model import preserves duplicate keys for engine rejection');
  const beforeMalformedImport=await page.locator('#request').inputValue();
  await page.locator('#model-file').setInputFiles({name:'compound-model.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(savedModel)+',"options":{"max_work_units":1}')});
  await page.waitForFunction(()=>document.getElementById('badge').textContent==='导入失败');
  assert.equal(await page.locator('#request').inputValue(),beforeMalformedImport);
  assert.match(await page.locator('#status').textContent(),/独立、完整/);
  report.checks.push('compound model file is rejected before request assembly');
  await page.evaluate(()=>{
    const original=File.prototype.arrayBuffer;
    File.prototype.arrayBuffer=function(){
      if(this.name==='slow-model.json') return new Promise(resolve=>{
        window.releaseModelImport=()=>original.call(this).then(resolve);
      });
      return original.call(this);
    };
  });
  await page.locator('#model-file').setInputFiles({name:'slow-model.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(savedModel))});
  await page.waitForFunction(()=>typeof window.releaseModelImport==='function');
  await page.locator('[data-example=align]').click();
  await page.waitForFunction(()=>JSON.parse(document.getElementById('request').value).operation==='dtw');
  await page.evaluate(async()=>{await window.releaseModelImport();});
  result=await execute(); assert.equal(result.operation,'dtw');
  report.checks.push('late file import does not overwrite a newer selected request');
  await page.locator('#file').setInputFiles({name:'sample.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify({schema:'warpfit.request/1',operation:'dtw',x:[2],y:[5]}))});
  await page.waitForFunction(() => document.getElementById('request').value.includes('"x":[2]'));
  result=await execute(); assert.equal(result.distance,3); report.checks.push('local JSON import computes user input');
  await page.locator('#request').fill(JSON.stringify({schema:'warpfit.request/1',operation:'preprocess',series:[1,2,3],options:{target_count:5}}));
  result=await execute();assert.equal(result.ok,true);assert.equal(result.prepared.series.length,5);
  assert.equal(await page.locator('.plot svg').count(),1);report.checks.push('preprocessing visualization works for custom input');
  const longRaw=Array.from({length:8192},(_,i)=>Array.from({length:16},(_,j)=>(i+j)%31));
  await page.locator('#request').fill(JSON.stringify({schema:'warpfit.request/1',operation:'preprocess',series:longRaw,options:{target_count:32,normalize:false}}));
  result=await execute(); assert.equal(result.ok,true); assert.equal(result.prepared.series.length,32);
  assert.equal(await page.locator('.plot svg').count(),1);
  report.checks.push('8192-point 16-feature raw input computes and renders without argument overflow');
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
