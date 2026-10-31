# 接口与集成

## MoonBit 库

依赖模块 `JQ-ai-nb/warpfit`，包导入为 `"JQ-ai-nb/warpfit/core" @warpfit`。`moon info` 生成的 [公开接口](../core/pkg.generated.mbti) 是准确的签名列表。

```moonbit
let prediction : @warpfit.Series = {
  count: 2, dimensions: 1, values: [0.2, 1.0],
}
let target : @warpfit.Series = {
  count: 3, dimensions: 1, values: [0.0, 0.8, 1.1],
}
match @warpfit.divergence(prediction, target, 0.4) {
  Ok(result) => println(result.gradient_x)
  Err(error) => println(error.code)
}
```

完整的外部模型参数训练示例：[cmd/calibrate](../cmd/calibrate/main.mbt)，运行 `moon run cmd/calibrate --target js`。它计算预测 `gain * sensor + offset`，将输入梯度通过链式法则累加到 gain / offset，再用下降步更新。它不是自动求导框架；神经网络参数的反向传播由调用者负责。

`soft_dtw` / `divergence` 是默认选项的便捷接口，`*_with` 支持特征权重和矩阵预算。`fit_with` 从多条带权示例拟合固定长度模板；`rank_candidates` 对全部候选评分后取前 k 项。所有计算返回 `Result[..., WarpError]`，不修改调用者输入数组。结果拥有独立数组；调用者后续修改数组不会被库后台使用。没有线程、网络或全局可变状态。

## 版本化 JSON

先运行 `node scripts/build.mjs`。同一个 MoonBit `run(String) -> String` 引擎供 Node CLI 和浏览器 Worker 使用。请求必须带 `"schema":"warpfit.request/1"`；响应为 `"schema":"warpfit.response/1"`。成功响应带 `ok:true`；错误为 `ok:false,error:{code,message}`。

| 操作 | 必需字段 | 输出 |
|---|---|---|
| `loss` | `x`, `y` | `value`, `gradient_x`, `gradient_y`, `alignment`, `components` |
| `fit` | `seed`, `examples` | `prototype`, `history`, `accepted_steps`, `stop`, `evaluations`, `work_units`, `gradient_norm` |
| `rank` | `query`, `candidates:[{id,series}]` | `matches`, `raw_self_query`, `work_units`, `candidates_evaluated` |

序列可以写成一维数组 `[0,1,0]`，也可以是等长行的二维数组 `[[0,2],[1,3]]`。输出序列和梯度一律为二维行数组。不同序列可有不同采样数，但特征数必须相同。`loss.objective` 默认为 `corrected`，可设 `raw`。raw 的 `components` 为 null；corrected 返回 cross / self_x / self_y。

未知字段、重复对象键、null 选项、非有限数、混合 / 不规则数组均返回错误。整数控制量要求普通非负整数字面量，`10` 合法，`10.0` / `1e1` 不合法；这样避免浮点舍入后意外接受小数预算。请求文本最多 2,000,000 UTF-16 单元，CLI / 浏览器另限制为 2,000,000 UTF-8 字节。只处理单个 JSON 请求，不支持流式多请求。

### 选项与默认值

全部操作的 `options`：gamma=1、feature_weights=[]（全部为1）、max_cells=262144。fit 额外默认 max_steps=60、learning_rate=1、gradient_tolerance=1e-8、improvement_tolerance=1e-10、max_evaluations=512、max_work_units=20000000、example_weights=[]（等权）。rank 额外 max_work_units=20000000，top_k 默认为全部候选。

实际输入和完整配置例子：[prototype.json](../examples/prototype.json)、[training.json](../examples/training.json)、[retrieval.json](../examples/retrieval.json)。数值范围和工作量语义见 [SEMANTICS.md](SEMANTICS.md)。所有错误码由核心和 wire 层稳定字符串给出；判断应使用 code 而非自然语言 message。

```text
node bin/warpfit.mjs examples/prototype.json
node bin/warpfit.mjs examples/training.json --out training-result.json
node bin/warpfit.mjs -
```

`-` 从标准输入读取到 EOF。无 `--out` 时输出 JSON 到 stdout；指定后写入对应文件，stdout 为空。错误不回显序列数值；未知字段错误会包含字段名。`--help` / `--version` 提供帮助。

CLI 退出码：0=本次计算正常结束（不代表优化收敛或业务正确），2=输入 / schema / 文件错误，3=矩阵或逻辑预算不足，或 fit 停在 evaluation_budget / work_budget。预算耗尽时可能返回 `ok:true` 的最后一个完整模板；调用者必须同时检查 stop。`max_steps` / `line_search_stalled` 也不保证收敛。

## 浏览器

`node scripts/serve.mjs` 后打开 <http://127.0.0.1:4194>。静态服务器仅监听本机；无后端数据接口。示例和引擎从同源加载，计算在 Worker 内完成；取消会终止 Worker 并丢弃未完成结果。页面绘图横轴按各自长度归一，不能据此认定序列在真实时钟上同步。部署静态页时须随引擎保留 `MOONBIT_CORE_LICENSE` / `MOONBIT_CORE_NOTICE` / `WARPFIT_LICENSE`。
