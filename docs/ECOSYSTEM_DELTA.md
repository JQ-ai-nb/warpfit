# 生态增量与差异边界

> 目的：回答“MoonBit 生态已有 DTW / 时序库时，WarpFit 增加了什么”。本文只陈述可核对的重合与差异，不宣称算法原创、性能领先或功能唯一。

## 已有工作

| 项目 | 已有能力 | 与 WarpFit 的重合 |
|---|---|---|
| [moon-geometry](https://github.com/walkzzz/moon-geometry) | 二维轨迹的普通 / 窗口 DTW | 窗口 DTW、路径对齐 |
| [MoonSTRtree](https://github.com/LING71671/MoonSTRtree) | 轨迹 DTW / Fréchet 接口 | 轨迹距离 |
| [tslearn](https://github.com/tslearn-team/tslearn) | Python 生态的 Soft-DTW、DBA、聚类、分类 | 算法族完整度更高 |
| [Augurs](https://github.com/grafana/augurs) | JS / Wasm 示例中的 DTW 距离矩阵与聚类 | 浏览器内聚类示例 |

## WarpFit 的增量

1. **MoonBit 原生数值内核**：核心只依赖 `moonbitlang/core`，同一份源码编译到 Wasm / Wasm-GC / JS / native；不是 Python 绑定或 FFI 包装。
2. **完整工作流而非单个距离函数**：预处理 → 硬/软对齐 → DBA 模板 → 聚类 → 最近邻分类 → 候选簇数选择 → 模型保存/复用 → 子序列定位，CLI、库、浏览器共用同一引擎。
3. **有界预算与可复核边界**：原始输入、矩阵格点、成对距离、训练批次都有明确上限；超限返回结构化错误，不返回部分结果。
4. **可验证的交付**：当前 main 四后端各 113 项 MoonBit（0.2.0 发布包 82 项）、43 项 Node、24 项浏览器检查；独立穷举、tslearn 对照、UCI 固定划分实验与 Mooncakes 注册表安装验证。
5. **浏览器本地计算**：静态页面加载单文件引擎，数据不上传、不需要后端；对“不能引入 Python 运行时”的 MoonBit/Wasm 场景是直接可用的部署形态。

## 不构成增量的部分

- 不把“用 MoonBit 重写”本身当作算法创新；Soft-DTW、DBA、DTW k-means、轮廓系数均来自公开论文或成熟实现。
- 不声称比 tslearn 更完整、更快或更准确；tslearn 的算法覆盖更广。
- 不声称窗口 DTW、轨迹距离或浏览器聚类在生态中唯一；moon-geometry、MoonSTRtree、Augurs 已有实际重合。
- 不把合成数据或固定划分实验解释为业务准确率、生产效果或用户采用证明。

## 适用判断

如果需求是“在 MoonBit / Wasm / 浏览器里直接嵌入一条可复现的时序对齐到聚类工作流，并且要能核对预算、边界和失败原因”，WarpFit 提供的是这条工作流及其验证契约。  
如果需求是“覆盖尽可能多的时序算法”或“需要 Python 生态的模型与工具”，tslearn 更合适；两者不是替代关系。

详细的重合接口、检索限制与来源披露见 [RELATED_WORK.md](RELATED_WORK.md)、[VALIDATION.md](VALIDATION.md) 和 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。
