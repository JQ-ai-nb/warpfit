const $ = id => document.getElementById(id);
let current = 'prototype', worker, lastResult, running = false;
const descriptions = {
  prototype: '设备 / 动作模板开发者：从两条不同节奏的示例学习四点参考模板。可调整 seed、examples 和优化预算。',
  training: '时序模型开发者：计算二维预测序列与目标的校正损失、两侧梯度和软对齐占用。梯度可用于外部模型链式求导。',
  retrieval: '离线序列应用开发者：对完整候选集评分，再输出前 k 项。分数不表示类别概率。'
};
function status(text, label = '', kind = '') { $('status').textContent = text; $('badge').textContent = label; $('badge').className = `badge ${kind}`; }
function busy(value) {
  running = value; $('run').disabled = value; $('cancel').disabled = !value;
  for (const b of document.querySelectorAll('.scenario,#reset')) b.disabled = value;
  $('file').disabled = value;
}
async function load(name) {
  try {
    const res = await fetch(`./examples/${name}.json`); if (!res.ok) throw new Error('示例文件不可用');
    const source = await res.text();
    current = name; $('request').value = source; $('request').scrollLeft = 0; $('request').scrollTop = 0; $('scenario-hint').textContent = descriptions[name];
    for (const b of document.querySelectorAll('.scenario')) { const selected = b.dataset.example === name; b.classList.toggle('selected', selected); b.setAttribute('aria-pressed', String(selected)); }
    status('示例已载入。运行后查看结果，也可以直接编辑 JSON。', '等待运行');
  } catch (e) { status(e.message, '加载失败', 'bad'); }
}
for (const b of document.querySelectorAll('.scenario')) b.addEventListener('click', () => load(b.dataset.example));
$('reset').onclick = () => load(current);
$('file').onchange = async event => {
  const file = event.target.files[0]; if (!file) return;
  try { if (file.size > 2_000_000) throw new Error('输入文件超过 2,000,000 字节。');
    $('request').value = new TextDecoder('utf-8', { fatal: true }).decode(await file.arrayBuffer());
    status('本地文件已载入，尚未计算。', '等待运行');
  } catch (e) { status(e.message, '导入失败', 'bad'); }
  event.target.value = '';
};
const ns = 'http://www.w3.org/2000/svg';
function el(tag, text, className) { const n = document.createElement(tag); if (text !== undefined) n.textContent = text; if (className) n.className = className; return n; }
function metric(label, value) { const n = el('div', undefined, 'metric'); n.append(el('span', label), el('strong', value)); $('metrics').append(n); }
const fmt = x => Number.isFinite(x) ? Number(x.toPrecision(7)).toString() : String(x);
function series(value) { return value.map(row => Array.isArray(row) ? row : [row]); }
function plot(title, datasets) {
  const box = el('section', undefined, 'plot'); box.append(el('h3', title));
  const svg = document.createElementNS(ns, 'svg'); svg.setAttribute('viewBox', '0 0 600 190'); svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', title);
  const all = datasets.flatMap(d => d.values); let lo = Math.min(...all), hi = Math.max(...all);
  if (hi - lo < 1e-12) { lo -= 1; hi += 1; }
  const y = v => 158 - (v - lo) / (hi - lo) * 132;
  for (const value of [lo, (lo + hi) / 2, hi]) {
    const line = document.createElementNS(ns, 'line'); for (const [k, v] of Object.entries({ x1: 58, x2: 583, y1: y(value), y2: y(value), stroke: '#e0e8e4' })) line.setAttribute(k, v); svg.append(line);
    const text = document.createElementNS(ns, 'text'); text.setAttribute('x', 8); text.setAttribute('y', y(value) + 4); text.setAttribute('fill', '#74847c'); text.setAttribute('font-size', '10'); text.textContent = fmt(value); svg.append(text);
  }
  const legend = el('div', undefined, 'legend');
  datasets.forEach((d, index) => {
    const color = ['#087568', '#ce8c37', '#6675c9', '#b45476', '#4b91b0'][index % 5];
    const points = d.values.map((v, i) => `${58 + i / Math.max(1, d.values.length - 1) * 525},${y(v)}`).join(' ');
    const line = document.createElementNS(ns, 'polyline'); line.setAttribute('points', points); line.setAttribute('fill', 'none'); line.setAttribute('stroke', color); line.setAttribute('stroke-width', '2.2'); svg.append(line);
    if (d.values.length === 1) { const dot = document.createElementNS(ns, 'circle'); dot.setAttribute('cx', '58'); dot.setAttribute('cy', y(d.values[0])); dot.setAttribute('r', '4'); dot.setAttribute('fill', color); svg.append(dot); }
    const label = el('span', d.label), swatch = el('i'); swatch.style.backgroundColor = color; label.prepend(swatch); legend.append(label);
  }); box.append(svg, legend); $('visuals').append(box);
}
function channels(label, rows) { const data = series(rows); return data[0].map((_, k) => ({ label: `${label} · 特征 ${k + 1}`, values: data.map(row => row[k]) })); }
function heatmap(matrix) {
  const box = el('section', undefined, 'plot'); box.append(el('h3', '软对齐占用 · 行 = x 的采样点，列 = y 的采样点'));
  const canvas = el('canvas', undefined, 'heat'); canvas.width = matrix[0].length; canvas.height = matrix.length; canvas.setAttribute('role', 'img'); canvas.setAttribute('aria-label', '软对齐占用矩阵；完整数字见 JSON 结果');
  const context = canvas.getContext('2d'); const img = context.createImageData(canvas.width, canvas.height);
  matrix.flat().forEach((value, i) => { const t = Math.max(0, Math.min(1, value)); img.data.set([Math.round(239 - 225*t), Math.round(247 - 127*t), Math.round(243 - 138*t), 255], i*4); });
  context.putImageData(img, 0, 0); box.append(canvas); $('visuals').append(box);
}
function render(result, source, elapsed) {
  $('output').textContent = JSON.stringify(result, null, 2); $('metrics').replaceChildren(); $('visuals').replaceChildren();
  lastResult = result; $('download').disabled = false;
  if (!result.ok) { status(`${result.error.code}: ${result.error.message}`, '输入 / 预算错误', 'bad'); return; }
  const request = JSON.parse(source); const budget = ['work_budget', 'evaluation_budget'].includes(result.stop);
  status(`${result.operation === 'fit' ? `停止原因：${result.stop}。返回最后一次完整评估的模板。` : '计算完成。'} 本机耗时 ${elapsed.toFixed(1)} ms。`, budget ? '预算耗尽' : '已完成', budget ? 'warn' : 'good');
  if (result.operation === 'fit') {
    metric('初始目标', fmt(result.history[0])); metric('最终目标', fmt(result.history.at(-1))); metric('接受步数 / 评估数', `${result.accepted_steps} / ${result.evaluations}`);
    plot('原型前后对比 · 横轴按各自长度归一显示', [...channels('初始', request.seed), ...channels('拟合', result.prototype)]);
    plot('优化轨迹 · 横轴为接受的步数', [{ label: '校正目标', values: result.history }]);
    metric('逻辑工作量', String(result.work_units));
  } else if (result.operation === 'loss') {
    metric('目标值', fmt(result.value)); metric('目标类型', result.objective === 'raw' ? '原始' : '自项校正'); metric('矩阵大小', `${result.alignment.length} × ${result.alignment[0].length}`);
    plot('输入序列 · 横轴按各自长度归一显示', [...channels('x', request.x), ...channels('y', request.y)]);
    plot('对 x 的输入梯度', channels('∂L/∂x', result.gradient_x)); heatmap(result.alignment);
  } else {
    metric('完整评估候选', String(result.candidates_evaluated)); metric('返回数量', String(result.matches.length)); metric('逻辑工作量', String(result.work_units));
    const table = el('table', undefined, 'rank'), head = el('tr'); ['顺序', '候选 ID', '校正值 ↓'].forEach(t => head.append(el('th', t))); table.append(head);
    result.matches.forEach((m, i) => { const row = el('tr'); [i+1, m.id, fmt(m.value)].forEach(t => row.append(el('td', String(t)))); table.append(row); }); $('visuals').append(table);
    const best = request.candidates.find(c => c.id === result.matches[0].id);
    plot('查询与首位候选 · 横轴按各自长度归一显示', [...channels('查询', request.query), ...channels('首位', best.series)]);
  }
}
$('run').onclick = () => {
  if (running) return; const source = $('request').value;
  if (new TextEncoder().encode(source).length > 2_000_000) { status('输入超过 2,000,000 字节。', '输入过大', 'bad'); return; }
  busy(true); lastResult = undefined; $('download').disabled = true; status('MoonBit 引擎正在独立 Worker 中计算，可随时取消。', '运行中');
  const started = performance.now(); worker = new Worker(new URL('./worker.mjs', import.meta.url), { type: 'module' });
  worker.onmessage = ({ data }) => {
    worker.terminate(); busy(false);
    try { if (data.failure) throw new Error(data.failure); render(JSON.parse(data.result), source, performance.now() - started); }
    catch (e) { status(e.message, '运行失败', 'bad'); }
  };
  worker.onerror = () => { worker.terminate(); busy(false); status('无法启动计算引擎，请确认已经运行构建。', '引擎错误', 'bad'); };
  worker.postMessage(source);
};
$('cancel').onclick = () => { worker?.terminate(); busy(false); lastResult = undefined; $('download').disabled = true; $('metrics').replaceChildren(); $('visuals').replaceChildren(); $('output').textContent = '本次计算已取消，未返回结果。'; status('计算已取消；此前 Worker 的状态已丢弃。', '已取消', 'warn'); };
$('download').onclick = () => {
  if (!lastResult) return; const url = URL.createObjectURL(new Blob([JSON.stringify(lastResult, null, 2)], { type: 'application/json' }));
  const a = el('a'); a.href = url; a.download = `warpfit-${lastResult.operation || 'error'}.json`; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
};
load(current);
