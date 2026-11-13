# WarpFit — 时序对齐、模板学习与聚类

> **本地开发候选版 0.2.0，本次修改尚未推送或发布。** 它在 2026 年 10 月已公开的 WarpFit 0.1.2 基础上扩展；最后一次留存的公开版本记录是 0.1.2，当前远程最新状态尚需复核。新增功能的测试证据以本地记录为准，不把旧版远程 CI 或 Mooncakes 状态当作新版验收。

为不同长度、节奏和量纲的数值序列提供一套**有界的时序分析流程**：按采样点重采样、逐维标准化、硬 DTW 约束对齐、DBA 模板与 DTW 聚类，训练后保存模型供新序列使用，并在较长输入中定位完整查询的最佳匹配区间；保留原有 Soft-DTW 损失、两侧梯度、可微分模板拟合和示例检索。

目标用户是 MoonBit 时序模型、传感器周期与离线数值应用开发者。逐点误差和直接平均要求采样位置一致；调用者可以根据问题选择硬路径对齐、带梯度的软目标，或对未标记序列做分组。核心使用 MoonBit 标准库，不依赖 Python 运行时或外部学习服务；浏览器演示在本地 Worker 计算用户数据。

维护者 / 个人参赛申请人：**蒋琦**；GitHub / Mooncakes：**JQ-ai-nb**。Apache-2.0。设计、编码与测试使用 AI 辅助，维护者负责理解与核实成果。算法来自公开论文，**不宣称算法首创或世界唯一**。

## 快速运行

需要 MoonBit SDK、Node.js ≥22；Python ≥3.10 用于独立验证，不是核心运行依赖。记录的本机工具链：moon 0.1.20261021 / moonc 0.10.17+093cb8f9c。CI 使用官方安装器的当前稳定 SDK，并在日志中记录实际版本。

```text
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
moon run cmd/demo --target js
moon run cmd/calibrate --target js
moon run cmd/series_pipeline --target js
node scripts/build.mjs
node bin/warpfit.mjs examples/align.json
node bin/warpfit.mjs examples/dba.json
node bin/warpfit.mjs examples/clusters.json
node bin/warpfit.mjs examples/pipeline.json
node bin/warpfit.mjs examples/uci-room.json
node bin/warpfit.mjs examples/subsequence.json
node bin/warpfit.mjs examples/prototype.json
node bin/warpfit.mjs examples/training.json --out result.json
node bin/warpfit.mjs examples/retrieval.json
node scripts/serve.mjs
```

最后打开 <http://127.0.0.1:4194>：选择场景，编辑 / 导入 JSON，运行后查看曲线、目标轨迹、梯度、热图或排序，下载完整结果。选择“训练并保存模型”可自动选择初始样本、训练、下载模型，再导入该文件并预测新数据。可终止 Worker 取消计算；输入仅在本机内存中处理，模型与结果由使用者主动下载。

保存和复用模型的文件流程（先构建引擎；模型输出文件需尚不存在）：

```text
node -e "require('node:fs').mkdirSync('work',{recursive:true})"
node bin/warpfit-model.mjs train examples/model_train.json work/cluster-model.json
node bin/warpfit-model.mjs predict work/cluster-model.json examples/model_predict_data.json
```

示例新数据的预测标签为 `[0,1,0]`。模型同时保存预处理和对齐参数；新数据可以只落在其中一个簇。簇编号只是到已学习中心的最近分配，没有监督分类或概率含义。模型 CLI 拒绝覆盖已有文件；训练预算耗尽时不写模型，返回退出码3及停止状态。

另有训练与验证分开的公开传感器数据流程：`node scripts/evaluate_holdout.mjs`。16段较早记录用于训练，另16段不重叠的后续记录用于文件模型加载后的预测；脚本输出训练状态、测试距离及训练初始中心的基线，完整方法见 [真实数据说明](docs/REAL_DATA.md)。单次固定划分只证明对应输入的结果，不能解读为分类准确率或生产效果。

库包导入：`"JQ-ai-nb/warpfit/core" @warpfit`。此前发布并验证的 0.1.2 **没有本地新增的 0.2.0 接口**；[Mooncakes 包页面](https://mooncakes.io/docs/JQ-ai-nb/warpfit)当前状态尚需复核，不能用 `moon add` 假称已安装本地修订版。类型化示例见 [cmd/series_pipeline](cmd/series_pipeline/main.mbt)，签名见 [pkg.generated.mbti](core/pkg.generated.mbti)，JSON 与 CLI 契约见 [API.md](docs/API.md)。

## 三个完整工作流

以下新增示例是本地 0.2.0 的合成数据，执行前先运行 `node scripts/build.mjs`：

| 使用者及问题 | 输入 / 操作 | 已验证输出 |
|---|---|---|
| 生产信号分析开发者：周期信号存在有限的时间偏移 | `examples/align.json`，两条四点序列和 `window=1` | 返回完整硬 DTW 路径与距离 0；改为 `window=0` 时平方路径代价为 2 |
| 传感器模板开发者：重复动作长度不一致 | `examples/dba.json`，三条观测和四点初始模板 | 经硬 DTW 路径与 DBA 更新，目标从约 0.166667 降至 0.118056；返回模板、轨迹与终止原因 |
| 多设备分析开发者：量纲、长度不同且需按形状分组 | `examples/pipeline.json`，四条序列、两个初始样本下标 | 重采样、逐维标准化后分组标签 `[0,0,1,1]`，返回每条预处理统计、中心、目标和预算状态 |
| 离线数据应用开发者：希望训练一次后复用分组规则 | `examples/model_train.json` 自动初始化并保存模型；用 `examples/model_predict_data.json` 预测新批次 | 模型文件重新读取后返回标签 `[0,1,0]` 及到各中心距离；文件流程、预算和同簇预测有测试 |
| 片段检索开发者：查询信号只占长记录的一小段 | `examples/subsequence.json`，query=`[0,1,0]`，target=`[9,9,0,1,0,9,9]` | 距离0、匹配区间零基闭区间 `[2,4]` 及完整对齐路径；独立枚举与 tslearn 验证 |

原有 0.1.x 工作流在本地仍可运行：

| 使用者及问题 | 输入 / 操作 | 可验证输出 |
|---|---|---|
| 传感器 / 重复动作模板开发者：不同节奏无法直接按下标平均 | 两条不同长度观测、四点 seed；运行 `examples/prototype.json` | 返回四点模板、每步目标、停止原因、评估 / 工作量；固定合成例目标从 6.7241967 降至 0.08787918 |
| 时序模型开发者：需要能更新预测参数的损失 | 二维预测 / 目标运行 `examples/training.json`；`cmd/calibrate` 展示梯度接入独立增益 / 偏置模型 | 返回双方同形梯度与占用矩阵；校准示例目标从 1.1964749 降至 0.4136583，链式梯度有有限差分检查 |
| 离线数值应用开发者：要比较查询周期和候选形状 | 查询、三个候选、统一 gamma；运行 `examples/retrieval.json` | 全候选评分后返回排序，相同序列第一；不将分数当作分类概率 |

详见 [场景输入、输出及验证方法](docs/SCENARIOS.md)。上述三个场景使用可复现的合成数值；另有 [UCI 房间传感器真实数据节选](docs/REAL_DATA.md) 可运行完整分组流程。真实数据示例不代表设备采用、用户访谈或业务准确率证据。

## 实现范围

- 硬 DTW：加权平方局部代价、完整路径、确定性并列顺序及 Sakoe-Chiba 窗口；不等长窗口沿较长轴延伸。距离专用接口只保留两行 DP，并只计算允许的带内格点，供聚类分配与预测使用。
- 子序列 DTW：消费完整查询，允许目标的起止点开放，返回一个最小代价连续区间和路径；并列时选最早结束位置。支持多变量权重与矩阵预算，当前不支持窗口约束或多结果检索。
- 加权 DBA：按硬对齐路径迭代更新固定长度模板；明确记录目标、预算和停止原因，支持不同长度及特征权重。
- DTW k-means：调用方给初始中心，或在模型接口选择确定性最远点初始化；反复执行最近中心分配和 DBA 更新，空簇明确报错。自动初始化的工作量计入同一训练预算；未提供随机 k-means++ 或自动选簇数。
- 可保存的版本化模型：训练时保留中心、预处理策略和对齐参数，读取后直接预测新批次，输出簇编号及到全部中心的距离。模型文件经过严格 schema 和参数验证。
- 线性重采样、逐序列逐特征标准化，以及组合为“预处理 → 聚类”的类型接口和 JSON 工作流。
- 纯 MoonBit 数值核心，仅使用标准库；多变量平方欧氏代价、可配置非负特征权重、稳定 soft-min 前向和逆序求导。
- 原始目标与自项校正严格区分；校正梯度包含自项的两侧导数，不对结果任意截零。
- 带权模板拟合：缓存固定示例自项，Armijo 回溯、明确容忍度和六种停止原因；返回最后一个完整评估点。
- 完整候选排名：唯一 ID、稳定并列顺序、预先检查总预算，不返回部分排序。
- 严格、带版本的 JSON API；拒绝未知字段、重复键、不规则数组和错误预算类型。Node 文件 / stdin CLI 与浏览器使用同一个 MoonBit 引擎。
- DTW 等分析输入每条 1..512 采样、1..16 特征，值域 ±10000；预处理允许每条最多 8192 个原始采样点，但超过 512 点时必须先指定 1..512 个输出点。子序列定位的原始目标可达 8192 点，仍须满足查询长度×目标长度≤262144。每矩阵最多 262144 个格点。fit / rank / 模型批次最多 32 条；各操作的迭代上限见接口文档，逻辑工作量 ≤1e8。

复杂度和边界见 [SEMANTICS.md](docs/SEMANTICS.md)。工作量按完整矩阵格点 × 特征数保守计费，不是墙钟时限；预处理另受数据规模限制，不计入聚类工作量。完整路径接口仍分配完整 DP 矩阵；仅求距离的接口采用两行空间，`max_cells` 仍按完整逻辑矩阵保守限制。原始 Soft-DTW 可为负；DBA / 聚类不保证全局最优，初始中心与尺度选择会影响结果。重采样基于样本下标，不支持真实时间戳、抗混叠或缺失值；没有 GPU、实时设备接入、自动确定簇数或大规模索引。

## 验证与可复现性

```text
python verify.py
python exhaustive_oracle.py --check
node --test tests/model.test.mjs tests/model_cli.test.mjs tests/auto_model.test.mjs tests/subsequence.test.mjs tests/distance_only.test.mjs tests/long_input.test.mjs
node scripts/benchmark_hard.mjs
```

本地执行结果与真实命令见 [VALIDATION.md](docs/VALIDATION.md)，包含 Wasm / Wasm-GC / JS、文件 CLI 和浏览器检查。本机缺 MSVC，**新版 native 运行和三系统远程 CI 尚未验证**。`verify.py --native` 需要先配置 C 编译工具。旧版的 [远程 CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/41191496193) 不代表本地新代码已通过远程检查。

此前 0.1.2 的注册表独立消费测试和线上演示已经验证；本地 0.2.0 尚未发布，不得声称新增功能已完成注册表安装测试。待授权推送并发布后，再用 `python scripts/registry_consumer.py` 验证发布版。

新增硬 DTW 有 240 组小样例通过全路径穷举；另对照 tslearn 0.6.4 验证 160 组硬 DTW、80 组单步 DBA、9 组聚类、100 组预处理及一个完整流程。常量特征采用本库明确的阈值归零语义，与参考库的浮点边界行为有差异，单独披露于 [VALIDATION.md](docs/VALIDATION.md)。数值一致性不证明业务效果。

子序列定位另有256组独立路径枚举与120组 tslearn 参考对照；仅求距离的实现与完整路径实现对比1200组输入，并覆盖长度比例极端的窗口边界。没有据此宣称性能领先；结果见验证文档。

UCI 的六段真实环境传感器序列也已执行预处理与聚类，并用 tslearn 复算最终样本到中心的 12 个距离。数据按 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) 引用，抽取方式与局限见 [REAL_DATA.md](docs/REAL_DATA.md)；它不是人数预测或实际产品采用证明。

新增16段训练 / 16段验证的模型文件流程，参考验证覆盖独立插值 / 标准化后的4608个数值、64个 DTW 距离和最终最近中心标签；详见 [固定划分实验](docs/REAL_DATA.md#训练后预测不重叠的后续数据)。该基线比较不代表与其他工具的性能或准确率比较。

## 与已有工作的关系

Soft-DTW 和自项校正来自 [Cuturi / Blondel 2017](https://proceedings.mlr.press/v70/cuturi17a.html) 与 [Blondel 等 2021](https://proceedings.mlr.press/v130/blondel21a.html)。其他语言已有成熟实现，不能把用 MoonBit 重写本身当作算法创新。

查证的 [MoonSTRtree 轨迹公开接口](https://github.com/LING71671/MoonSTRtree/blob/main/src/extensions/trajectory/pkg.generated.mbti)已有普通 DTW / Fréchet；[moon-geometry 的二维轨迹接口](https://github.com/walkzzz/moon-geometry/blob/main/spatial/dtw/pkg.generated.mbti)已有普通及窗口 DTW。两者与本项目存在实际重合；WarpFit 面向多变量数值序列，提供硬 / 软对齐、模板拟合、预处理到聚类的组合。[tslearn](https://github.com/tslearn-team/tslearn)已覆盖更广的相关算法，本项目不声称比它更完整、更快或更准确，也不把 MoonBit 重写、窗口 DTW 或 DBA 宣称为算法首创。

[Augurs 的 JS / WebAssembly 示例](https://github.com/grafana/augurs/blob/main/js/testpkg/clustering.test.ts)也已经使用 DTW 距离矩阵与聚类，因此不能把在浏览器中运行这些能力说成独有。更多已查明的相关项目和具体接口边界见下文的比较说明。

详细比较、检索限制及与既往工程的关系见 [RELATED_WORK.md](docs/RELATED_WORK.md)。未发现同类不等于生态不存在；没有完整审计全部公开 / 私有工程。本项目从论文公式独立编写数值核心，没有复制上述工程源码或测试夹具。许可与分发说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

![本地原型拟合工作台](docs/screenshots/desktop.png)
