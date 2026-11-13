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
  Ok(result) => println(result.value)
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
| `dtw` | `x`, `y` | `distance`, `squared_cost`, `path`, `visited_cells` |
| `dtw_distance` | `x`, `y` | `distance`, `squared_cost`, `visited_cells`；不返回路径 |
| `subsequence` | `query`, `target` | `start`, `end`, `distance`, `squared_cost`, `path`, `visited_cells` |
| `dba` | `seed`, `examples` | `prototype`, `history`, `accepted_steps`, `stop`, `evaluations`, `work_units` |
| `cluster` | `data`, `centers` | `centers`, `labels`, `inertia`, `history`, `iterations`, `stop`, `work_units` |
| `preprocess` | `series` | `prepared`：处理后的序列及均值、标准差、常量特征标记 |
| `pipeline` | `data`, `seed_indices` | `prepared` 和嵌套的 `clustering`（中心、标签、目标和状态） |
| `train_model` | `data`, `seed_indices` | `model`、`prepared`、`clustering`；手动指定初始样本 |
| `auto_train_model` | `data`, `cluster_count` | 同上，另有 `seed_indices`、`seed_work_units`、`total_work_units`；可选 `first_index` 默认0 |
| `predict` | `model`, `data` | `prepared`, `labels`, `distances`, `distances_to_centers`, `work_units` |

序列可以写成一维数组 `[0,1,0]`，也可以是等长行的二维数组 `[[0,2],[1,3]]`。输出序列和梯度一律为二维行数组。不同序列可有不同采样数，但特征数必须相同。`loss.objective` 默认为 `corrected`，可设 `raw`。raw 的 `components` 为 null；corrected 返回 cross / self_x / self_y。

未知字段、重复对象键、null 选项、非有限数、混合 / 不规则数组均返回错误；保存模型中的 `alignment.window:null` 是明确允许的例外。整数控制量要求普通非负整数字面量，`10` 合法，`10.0` / `1e1` 不合法；这样避免浮点舍入后意外接受小数预算。请求文本最多 2,000,000 UTF-16 单元，CLI / 浏览器另限制为 2,000,000 UTF-8 字节。只处理单个 JSON 请求，不支持流式多请求。

### 选项与默认值

原有 `loss` / `fit` / `rank` 的公共 `options`：gamma=0.5、feature_weights=[]（全部为1）、max_cells=262144。fit 额外默认 max_steps=60、learning_rate=1、gradient_tolerance=1e-8、improvement_tolerance=1e-10、max_evaluations=512、max_work_units=20000000、example_weights=[]（等权）。rank 额外 max_work_units=20000000，top_k 默认为全部候选。

新增 `dtw` / `dtw_distance` / `dba` / `cluster` / `pipeline` / `train_model` / `auto_train_model`：`window` 省略表示无限制；非负整数表示 Sakoe-Chiba 半径，不等长时沿较长轴延伸。`feature_weights=[]` 为全1，`max_cells=262144`。dba 的 `max_steps=30`、`tolerance=1e-8`、`max_work_units=20000000`、`example_weights=[]`；cluster / pipeline / 模型训练的 `max_iterations=20`、`max_dba_steps=20`、`tolerance=1e-8`、`max_work_units=20000000`。

`preprocess` / `pipeline` / 模型训练：原始输入每条最多8192点；`target_count=0` 表示保持长度，只适用于不超过512点的输入，1..512 表示按样本下标重采样。`normalize=true` 表示对每条序列独立逐特征标准化，`epsilon=1e-12`。先重采样后标准化。`pipeline.seed_indices` / `train_model.seed_indices` 是原始输入数组中不重复的零基下标，对应预处理后的初始中心。常量特征的标准化输出为0；`normalize=false` 时均值、标准差和常量标记数组为空。JSON 操作选项禁止 `window:-1`；省略 `window` 才表示不约束（MoonBit 类型接口用 -1）。请求总大小限制仍有效。

`subsequence` 的 `query` 最多512点，`target` 最多8192点；维数一致，`query.length × target.length ≤ max_cells`。仅接受 `feature_weights` 和 `max_cells`，不接受 `window`。输出 `start` / `end` 是目标上的零基闭区间，路径中第一列是查询下标、第二列是目标原始下标。例子 `[0,1,0]` 对 `[9,9,0,1,0,9,9]` 返回区间 `[2,4]`、距离0。合法非空输入总会返回一个最佳区间；业务是否接受该匹配须由调用方判定。

### 可保存的聚类模型

`auto_train_model.cluster_count` 为1..min(16,样本数)，最多32条样本；`first_index` 在输入数组范围内。先预处理，再按距最近已选中心最远的样本确定性选择初始中心；并列选最小下标。初始化和聚类共享 `max_work_units`，`total_work_units=seed_work_units+clustering.work_units`。不足以完成初始化或首次完整分配时报错；不能找到足够多非零 DTW 距离的中心时报 `seed_distinct`。它不是随机 k-means++，不自动选择簇数。

成功训练响应中的 `model` 可单独保存为 JSON 文件，schema 为 `warpfit.cluster-model/1`。字段全部必需，未知字段和重复键拒绝：

```json
{
  "schema": "warpfit.cluster-model/1",
  "centers": [[[1]], [[10]]],
  "preprocessing": { "target_count": 0, "normalize": false, "epsilon": 1e-12 },
  "alignment": { "window": null, "feature_weights": [], "max_cells": 262144 }
}
```

中心使用分析范围1..512点；设置 `target_count>0` 时中心长度须与它相同。`window:null` 表示无限制，否则为0..512的整数。模型不保存训练样本或监督标签；标准化只保留策略，预测时独立计算每条新序列的均值和标准差。`predict` 的 `data` 是1..32条原始序列，使用模型保存的预处理参数；只允许通过 `options.max_work_units`（默认20000000）控制本次预测预算，不能悄悄覆盖模型的对齐策略。

`distances_to_centers[i][j]` 是第 i 条输入到第 j 个中心的 DTW 距离，`labels[i]` 选最小距离的中心，并列选较小中心下标，`distances[i]` 为所选距离。预测不会重新训练，允许单条数据和新批次全部落入同一簇。预算不足不返回部分标签。簇编号没有监督分类概率含义。

文件流程：

```text
node -e "require('node:fs').mkdirSync('work',{recursive:true})"
node bin/warpfit-model.mjs train examples/model_train.json work/cluster-model.json
node bin/warpfit-model.mjs predict work/cluster-model.json examples/model_predict_data.json
```

训练请求使用 `train_model` 或 `auto_train_model`。预测数据文件只包含样本数组，例如 `[[5,10,15],[30,20,10]]`。可加 `--out work/prediction.json` 保存预测响应；输出目录应已存在。模型 CLI 首先校验模型和数据文件分别是独立、完整的 JSON 文档，然后使用原文组装请求，保留 MoonBit 的重复键和数值字面量校验；文件尾部附加字段或另一个文档返回 `json` 错误，不能作为预测参数。文件须为 UTF-8，分别和合并请求均有2MB上限；所有输出使用创建新文件模式，拒绝覆盖已存在文件。输入和输出路径不能相同。训练因预算中断时**不写模型**，退出码3并保留完整停止响应；其余输入或文件错误退出码2。达到迭代上限或数值停滞可能仍写出模型，需查看 `stop` 判断质量。底层 JSON 训练响应中的中断状态仍可包含最后完整中心，不能将 `ok:true` 单独解释为训练完成。

实际输入和完整配置例子：[align.json](../examples/align.json)、[dba.json](../examples/dba.json)、[clusters.json](../examples/clusters.json)、[pipeline.json](../examples/pipeline.json)、[真实传感器数据](REAL_DATA.md)，以及原有的 [prototype.json](../examples/prototype.json)、[training.json](../examples/training.json)、[retrieval.json](../examples/retrieval.json)。数值范围和工作量语义见 [SEMANTICS.md](SEMANTICS.md)。所有错误码由核心和 wire 层稳定字符串给出；判断应使用 code 而非自然语言 message。

```text
node bin/warpfit.mjs examples/prototype.json
node bin/warpfit.mjs examples/training.json --out training-result.json
node bin/warpfit.mjs -
```

`-` 从标准输入读取到 EOF。无 `--out` 时输出 JSON 到 stdout；指定后写入对应文件，stdout 为空。错误不回显序列数值；未知字段错误会包含字段名。`--help` / `--version` 提供帮助。

CLI 退出码：0=本次计算正常结束（不代表优化收敛或业务正确），2=输入 / schema / 文件错误，3=矩阵或逻辑预算不足，或 fit / dba / cluster / pipeline / 模型训练在预算耗尽时停止。预算耗尽时可能返回 `ok:true` 的最后一个完整状态；调用者必须检查 stop，pipeline 和模型训练的 stop 位于 `clustering.stop`。`max_steps`、`max_iterations`、`line_search_stalled`、`numerical_stall` 均不保证收敛。聚类如果出现空簇返回 `empty_cluster`，可更换初始中心或减少簇数。

## 浏览器

`node scripts/serve.mjs` 后打开 <http://127.0.0.1:4194>。静态服务器仅监听本机；无后端数据接口。示例和引擎从同源加载，计算在 Worker 内完成；取消会终止 Worker 并丢弃未完成结果。页面绘图横轴按各自长度归一，不能据此认定序列在真实时钟上同步。部署静态页时须随引擎保留 `MOONBIT_CORE_LICENSE` / `MOONBIT_CORE_NOTICE` / `WARPFIT_LICENSE`。

“训练并保存模型”示例运行后，可主动下载独立模型或用模型生成预测请求；生成的请求先填入一条训练样本以便演示，应在运行前换成待分析的新数据。“导入模型”先确认文件是独立 JSON，再将原文写入预测请求并保留重复键检测；文件校验失败不会改写当前请求。默认占位数据 `[[0]]` 须按实际特征数和业务替换。编辑或更换请求会清除旧结果和模型下载状态；预算中断时不启用模型下载按钮。
