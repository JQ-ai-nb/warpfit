# WarpFit 0.2.0 本期新增（2026 年 11 月）

> 本文只列本期新申报版本的事实与证据，不替代申报书。0.1.2 是 2026 年 10 月已公开的原型；0.2.0 是在其之上的本期实质新增，不是把旧项目改名后重复提交。

## 本期边界

- **0.1.2（公开原型）**：Soft-DTW 损失、自项校正梯度、带权模板拟合、完整候选排序、typed API、Node CLI 与浏览器工作台。
- **0.2.0（本期新申报版本）**：在原型上新增硬 DTW 约束对齐、DBA 模板、DTW/DBA 聚类、预处理、模型保存与复用、子序列定位、最近邻分类、候选簇数选择，并把浏览器场景扩至 12 个。
- **源码提交**：`8195d88`，相对 `8695d8a` 为 26 个功能提交、43 个文件、+2532/-64 行。
- **发布文档提交**：`faf9119`（发布前中性化）、`fbd17a5`（发布后状态同步）。
- **main 最新提交**：以仓库为准；**0.2.0 源码提交**：`8195d88`；**tag**：`v0.2.0`（指向 `faf9119`）。

## 新增能力

| 任务族 | 入口 | 本期新增 |
|---|---|---|
| 约束对齐 | `examples/align.json` | 多变量带权硬 DTW、Sakoe-Chiba 窗口、完整路径与并列规则 |
| 模板学习 | `examples/dba.json` | 带权 DBA、不同长度、目标轨迹、停止原因与预算 |
| 预处理 + 聚类 | `examples/pipeline.json` | 线性重采样、逐维标准化、DTW k-means、确定性最远点初始化 |
| 最近邻分类 | `examples/knn.json` | 硬 DTW k 近邻投票、邻居下标/距离、确定性决胜 |
| 候选簇数选择 | `examples/select-k.json` | 共享成对距离矩阵、平均轮廓系数、空簇候选缺席 |
| 模型保存与复用 | `bin/warpfit-model.mjs` | 保存中心/预处理/对齐参数，加载后预测新批次 |
| 子序列定位 | `examples/subsequence.json` | 完整查询、开放目标端点、最小代价连续区间 |
| 浏览器工作台 | `https://jq-ai-nb.github.io/warpfit/` | 12 个场景、模型文件往返、取消、移动布局 |

## 验证证据

- **MoonBit**：0.2.0 发布包四后端各 82/82；main 后续新增 4 项边界测试，当前四后端各 86/86（本机三后端各 86/86，native 由远程 CI 覆盖）。
- **Node**：43/43。
- **浏览器**：24/24，覆盖 12 个场景、模型文件往返、错误输入、预算、取消和 390px 布局；线上页面无 pageerror、无外部数据请求。
- **CI**：0.2.0 源码 `8195d88` 的 [44095202653](https://github.com/JQ-ai-nb/warpfit/actions/runs/44095202653)；发布文档提交 `fbd17a5` 的 [44106313819](https://github.com/JQ-ai-nb/warpfit/actions/runs/44106313819) 也通过；main 最新 CI 见 [Actions](https://github.com/JQ-ai-nb/warpfit/actions)。
- **Mooncakes**：`JQ-ai-nb/warpfit@0.2.0`，`build_status: success`；`python scripts/registry_consumer.py --version 0.2.0` 返回 `registry install verified: True`。
- **独立参考**：硬 DTW 240 组全路径穷举；tslearn 对照 160 组硬 DTW、80 组单步 DBA、9 组聚类、100 组预处理；子序列 256 组枚举 + 120 组 tslearn；UCI 16 段训练 / 16 段后续验证与 64 个距离复算。

## 范围外与未完成事项

- 不做 GPU 加速、实时流接入、大规模索引、缺失值插值或自动确定原型长度。
- 聚类不保证全局最优；DBA 是局部迭代，初值会影响结果。
- 重采样按样本下标，不读取真实时间戳，也不做抗混叠。
- 不宣称算法原创、性能领先或功能唯一；与 tslearn / moon-geometry / MoonSTRtree / Augurs 的重合与差异见 [RELATED_WORK.md](RELATED_WORK.md) 和 [ECOSYSTEM_DELTA.md](ECOSYSTEM_DELTA.md)。

## 与旧版关系

0.1.2 的 Soft-DTW、梯度、模板拟合和候选排序仍保留并有测试；0.2.0 的新增通过独立文件与接口提供，没有替换旧版 API。旧版发布记录仍可在 Mooncakes 的版本历史中核对。
