const $ = id => document.getElementById(id);
let current = 'prototype', worker, lastResult, running = false, loadNumber = 0;
const descriptions = {
  prototype: '设备 / 动作模板开发者：从两条不同节奏的示例学习四点参考模板。可调整 seed、examples 和优化预算。',
  training: '时序模型开发者：计算二维预测序列与目标的校正损失、两侧梯度和软对齐占用。梯度可用于外部模型链式求导。',
  retrieval: '离线序列应用开发者：对完整候选集评分，再输出前 k 项。分数不表示类别概率。',
  align: '生产数据开发者：限制时间错位的范围，返回两条序列的硬对齐路径与代价；可修改 window 比较路径。',
  dba: '传感器应用开发者：输入多条不同长度样本和初始模板，沿硬 DTW 路径做迭代平均，得到 DBA 模板。',
  clusters: '时序分析开发者：输入未标记序列及初始中心，通过 DTW 分配和 DBA 更新得到簇编号与中心。',
  pipeline: '不同设备的序列可能长度、量纲不同。先按采样点重采样并逐维标准化，再按指定样本初始化聚类中心。',
  'uci-room': 'UCI Room Occupancy Estimation 公共数据节选（CC BY 4.0）：六段温度、光照、CO₂ 序列按形状分组。这里不预测房间人数。'
};
function status(text, label = '', kind = '') { $('status').textContent = text; $('badge').textContent = label; $('badge').className = `badge ${kind}`; }
function busy(value) {
  running = value; $('run').disabled = value; $('cancel').disabled = !value;
  $('request').readOnly = value;
  for (const b of document.querySelectorAll('.scenario,#reset')) b.disabled = value;
  $('file').disabled = value;
}
function clearResult() {
  lastResult = undefined; $('download').disabled = true;
  $('metrics').replaceChildren(); $('visuals').replaceChildren(); $('output').textContent = '当前输入尚未计算。';
}
async function load(name) {
  const ownLoad = ++loadNumber;
  try {
    const res = await fetch(`./examples/${name}.json`); if (!res.ok) throw new Error('示例文件不可用');
    const source = await res.text();
    if (ownLoad !== loadNumber) return;
    current = name; $('request').value = source; $('request').scrollLeft = 0; $('request').scrollTop = 0; $('scenario-hint').textContent = descriptions[name]; clearResult();
    for (const b of document.querySelectorAll('.scenario')) { const selected = b.dataset.example === name; b.classList.toggle('selected', selected); b.setAttribute('aria-pressed', String(selected)); }
    status('示例已载入。运行后查看结果，也可以直接编辑 JSON。', '等待运行');
  } catch (e) { if (ownLoad === loadNumber) status(e.message, '加载失败', 'bad'); }
}
for (const b of document.querySelectorAll('.scenario')) b.addEventListener('click', () => load(b.dataset.example));
$('reset').onclick = () => load(current);
$('file').onchange = async event => {
  const file = event.target.files[0]; if (!file) return;
  ++loadNumber;
  try { if (file.size > 2_000_000) throw new Error('输入文件超过 2,000,000 字节。');
    $('request').value = new TextDecoder('utf-8', { fatal: true }).decode(await file.arrayBuffer());
    clearResult();
    status('本地文件已载入，尚未计算。', '等待运行');
  } catch (e) { status(e.message, '导入失败', 'bad'); }
  event.target.value = '';
};
$('request').addEventListener('input', () => {
  ++loadNumber;
  clearResult(); status('输入已更改，请重新运行以获得对应结果。', '等待运行');
});
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
function heatmap(matrix, title = '软对齐占用 · 行 = x 的采样点，列 = y 的采样点') {
  const box = el('section', undefined, 'plot'); box.append(el('h3', title));
  const canvas = el('canvas', undefined, 'heat'); canvas.width = matrix[0].length; canvas.height = matrix.length; canvas.setAttribute('role', 'img'); canvas.setAttribute('aria-label', `${title}；完整数字见 JSON 结果`);
  const context = canvas.getContext('2d'); const img = context.createImageData(canvas.width, canvas.height);
  matrix.flat().forEach((value, i) => { const t = Math.max(0, Math.min(1, value)); img.data.set([Math.round(239 - 225*t), Math.round(247 - 127*t), Math.round(243 - 138*t), 255], i*4); });
  context.putImageData(img, 0, 0); box.append(canvas); $('visuals').append(box);
}
function render(result, source, elapsed) {
  $('output').textContent = JSON.stringify(result, null, 2); $('metrics').replaceChildren(); $('visuals').replaceChildren();
  lastResult = result; $('download').disabled = false;
  if (!result.ok) {
    const hint = result.error.code === 'empty_cluster' ? '；请更换初始中心或减少簇数' : '';
    status(`${result.error.code}: ${result.error.message}${hint}`, '输入 / 预算错误', 'bad'); return;
  }
  const request = JSON.parse(source); const stop = result.stop ?? result.clustering?.stop;
  const budget = ['work_budget', 'evaluation_budget'].includes(stop);
  const caution = ['numerical_stall', 'line_search_stalled', 'max_steps', 'max_iterations'].includes(stop);
  const description = stop ? `停止原因：${stop}。返回最后一次完整评估的结果。` : '计算完成。';
  status(`${description} 本机耗时 ${elapsed.toFixed(1)} ms。`, budget ? '预算耗尽' : caution ? '检查停止原因' : '已完成', budget || caution ? 'warn' : 'good');
  if (result.operation === 'fit' || result.operation === 'dba') {
    metric('初始目标', fmt(result.history[0])); metric('最终目标', fmt(result.history.at(-1))); metric('接受步数 / 评估数', `${result.accepted_steps} / ${result.evaluations}`);
    plot('原型前后对比 · 横轴按各自长度归一显示', [...channels('初始', request.seed), ...channels('拟合', result.prototype)]);
    plot('优化轨迹 · 横轴为接受的步数', [{ label: result.operation === 'dba' ? '平均平方 DTW 代价' : '校正目标', values: result.history }]);
    metric('逻辑工作量', String(result.work_units));
  } else if (result.operation === 'loss') {
    metric('目标值', fmt(result.value)); metric('目标类型', result.objective === 'raw' ? '原始' : '自项校正'); metric('矩阵大小', `${result.alignment.length} × ${result.alignment[0].length}`);
    plot('输入序列 · 横轴按各自长度归一显示', [...channels('x', request.x), ...channels('y', request.y)]);
    plot('对 x 的输入梯度', channels('∂L/∂x', result.gradient_x)); heatmap(result.alignment);
  } else if (result.operation === 'dtw') {
    metric('DTW 距离', fmt(result.distance)); metric('平方路径代价', fmt(result.squared_cost)); metric('路径格点数', String(result.path.length));
    plot('输入序列 · 横轴按各自长度归一显示', [...channels('x', request.x), ...channels('y', request.y)]);
    const rows = series(request.x).length, columns = series(request.y).length;
    const occupancy = Array.from({ length: rows }, () => Array(columns).fill(0));
    for (const [i,j] of result.path) occupancy[i][j] = 1;
    heatmap(occupancy, '硬 DTW 路径 · 深色为选中格点，行 = x，列 = y');
  } else if (result.operation === 'preprocess') {
    const prepared=result.prepared;
    metric('原始采样点', String(series(request.series).length)); metric('输出采样点', String(prepared.series.length));
    metric('逐维标准化', prepared.normalized ? '是' : '否');
    plot('预处理前后 · 横轴按各自长度归一', [...channels('原始',request.series),...channels('输出',prepared.series)]);
    if (prepared.normalized) status(`${description} 常量特征数：${prepared.constant_features.filter(Boolean).length}。本机耗时 ${elapsed.toFixed(1)} ms。`, '已完成', 'good');
  } else if (result.operation === 'cluster' || result.operation === 'pipeline') {
    const group=result.operation === 'pipeline' ? result.clustering : result;
    metric('输入序列', String(group.labels.length)); metric('簇数', String(group.centers.length)); metric('平均平方 DTW 代价', fmt(group.inertia));
    if (result.operation === 'pipeline') {
      const normalized=result.prepared.filter(p=>p.normalized).length;
      const constants=result.prepared.reduce((sum,p)=>sum+p.constant_features.filter(Boolean).length,0);
      metric('已标准化 / 常量特征数', `${normalized} / ${constants}`);
      plot('预处理序列 · 最多显示前 4 条的前 3 个特征',result.prepared.slice(0,4).flatMap((p,i)=>channels(`序列 ${i}`,p.series).slice(0,3)));
    }
    const table=el('table', undefined, 'rank'), head=el('tr');
    ['簇编号', '样本数', '输入下标（从 0 开始）'].forEach(t=>head.append(el('th',t))); table.append(head);
    group.centers.forEach((center,k) => {
      const members=group.labels.flatMap((label,index)=>label===k?[index]:[]);
      const row=el('tr'); [k,members.length,members.join('、')].forEach(t=>row.append(el('td',String(t)))); table.append(row);
    }); $('visuals').append(table);
    const datasets=group.centers.slice(0,4).flatMap((center,k)=>channels(`簇 ${k}`,center).slice(0,3));
    plot('聚类中心 · 最多显示 4 簇、每簇前 3 个特征；横轴按各自长度归一', datasets);
    plot('聚类目标轨迹 · 横轴为完整接受的迭代', [{label:'平均平方 DTW 代价',values:group.history}]);
    metric('完整迭代 / 工作量', `${group.iterations} / ${group.work_units}`);
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
