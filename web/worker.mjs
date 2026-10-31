import { run } from './engine.mjs';
self.onmessage = ({ data }) => {
  try { self.postMessage({ result: run(data) }); }
  catch { self.postMessage({ failure: '计算引擎出现异常；请检查输入或降低规模。' }); }
};
