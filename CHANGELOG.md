# 版本记录

## 0.2.3

- 文档：README 重写首屏（一句话定位、60 秒路径、架构图），把“给谁解决什么”放到第 3 行；截图与示例命令前置。
- 文档：新增 `docs/STATUS.md` 作为所有实测数字的单一事实源，其余文档改为引用，消除 113/117、0.2.0/0.2.2、22/24 三处口径漂移。
- 工具：新增 `scripts/evidence_report.mjs`（19 项声明与证据文件逐项比对）与 `scripts/check_examples.mjs`（20 个示例各跑两次、断言输出逐字节一致），并接入 CI。
- 文档：`docs/ACCEPTANCE.md` 增加“官方要求 → 证据 → 复核命令”对照表；`docs/AI_AND_DECISIONS.md` 记录本轮五项判断的取舍与备选方案。
- 无接口与算法变更。

## 0.2.2

修复（均由复现用例先确认）：

- `knn_pruned`：平方阈值回代会把距离精确相等的候选判成更远（`sqrt(6)^2 = 5.999999999999999`），导致剪枝版邻居与 `knn` 不一致；阈值比较加入相对容差后两者逐条一致。
- `subsequence_topk`：无约束最优路径压缩查询点时，该终点被整体丢弃，合法输入会返回空 `matches`；现改为评估以该终点结尾的最短合法窗口，并计入 `work_units`。
- `medoids`：重复/常量样本不再以 `seed_distinct` 失败，改取最小未选下标补齐，代价为 0。

新增：

- `motifs` 的 `options.min_gap` 排除半径（默认 -1 取窗口长度，0 关闭）：top-K 不再返回同一区域的平移副本。
- `cross_validate` 改为按标签分层轮转分折：标签排列不再决定某折训练集是否缺类。
- 4 条回归测试（并列剪枝、top-k 回退、常量 medoids、标签顺序）。

发布时本机三后端各 117 项；源码规模按可复核口径记录于 `docs/STATUS.md`。

## 0.2.1

- 2026-11-18：0.2.1 已发布到 Mooncakes（Server status 200 OK）；tag `v0.2.1`；`registry_consumer --version 0.2.1` 返回 `registry install verified: True`。
- 新增 `knn_pruned`、`subsequence_topk`、`cross_validate`、`medoids`、`motifs`、`outliers`、`describe` 七个 JSON 操作与对应核心模块；有效 MoonBit 源码约 5,002 行，测试 110 项（四后端 110/110）。
- `knn_pruned` 使用 LB_Keogh 下界排序和精确 early abandon，结果与 `knn` 一致，并返回下界检查/完整距离调用计数。
- `subsequence_topk` 要求返回区间长度不小于查询长度；`cross_validate` 使用按下标确定性分折，输出混淆矩阵与每类 precision/recall/F1。
- `medoids` 为确定性 PAM 风格 k-medoids；`motifs` 为有界固定窗口自相似对；`outliers` 为 k 近邻平均距离分数；`describe` 输出逐特征统计。
- 示例见 `examples/{knn-pruned,subsequence-topk,cross-validate,medoids,motifs,outliers,describe}.json`。

## 0.2.0

- 2026-11-17：0.2.0 源码推送至公开 main（`8195d88`），Linux / macOS / Windows CI 通过；0.2.0 已发布到 Mooncakes，`registry_consumer --version 0.2.0` 注册表安装验证通过。
- 浏览器工作台新增 `knn` / `select_k` 两个场景，场景数扩至 12 个；本机 Chromium 浏览器检查覆盖 12 个场景、共 24 项。
- 演示包补齐 12 个网页示例，解压后自检覆盖 10 组检查。
- 修复 `select_k` 成对距离预算的 Int32 溢出：累计改用 Int64，32 × 512 × 16 的最坏情形（2^32）不再回绕为 0，超限在任何 DTW 计算前即拒绝。
- 归档消费检查由 8 组扩至 10 组，新增 `knn_classify` 与 `select_cluster_count` 的断言；归档验证仍不等同于 Mooncakes 安装验证。
- `tests/knn_reference.py` 默认改写忽略目录 `artifacts/knn-reference.json`，`python verify.py` 不再弄脏工作树；证据改为显式更新：`--evidence` 写 `docs/evidence/knn-reference.json`（LF 换行，无实质变化时跳过并打印 `evidence: unchanged`），`--check-evidence` 比较后以 0 / 1 返回 `evidence: current` / `evidence: STALE` 并列出差异键。报告新增只作来源标记的 `engine_commit`，默认运行末尾也会提示证据是否落后。
- 新增硬 DTW 最近邻分类（`knn`）：k 个邻居、投票分布与距离，票数 / 距离并列时按邻居顺序确定性决胜；属于对齐之外的新任务族，输出明确不是概率。
- 新增按轮廓系数选择簇数（`select_k`）：候选 k 共享一份成对 DTW 距离矩阵，确定性最远点初始化，空簇候选记为缺席，整体预算不足直接报错。
- 本地验收维护新增公共接口消费示例、实际归档包的独立workspace检查与三后端运行；默认注册表消费覆盖新增能力，另备发布后的手动验证工作流。2026-11-14本轮未推送、未发布，不能声称新的注册表消费或远程工作流已通过。
- 修复模型CLI和网页导入的文档边界：模型 / 预测数据文件必须各自包含完整的独立JSON，保留原文校验重复键，拒绝尾部附加字段或文档。
- 新增UCI公开传感器数据的16段训练 / 16段后续验证文件、来源划分清单、模型文件往返及初始中心基线；增加独立插值、标准化和64个DTW距离的参考复算，不当作准确率或生产效果。
- 新增完整查询的多变量子序列 DTW 定位、明确区间与并列规则；提供查询×目标预算和独立参考验证。
- 新增可保存的聚类模型、加载后预测新批次及专用文件 CLI；保存预处理与对齐参数，预测允许所有样本落入同一簇。
- 新增确定性的最远点自动初始化（`select_farthest_seeds` / `auto_train_model`），共享训练预算；不是随机 k-means++，也不在这条训练路径中推断簇数——候选簇数由 `select_k` 在调用方给定范围内按轮廓系数选择。
- 距离专用 DTW 使用两行 DP 并只遍历窗口内格点，供分配、初始化及预测使用；完整路径算法保留原实现，逻辑规模和预算仍保守计费。
- 预处理先验证最多8192点原始输入，再显式重采样到不超过512点；补模型下载 / 导入 / 预测界面及文件往返、长输入、预算中断和路径边界测试。
- 新增窗口约束硬 DTW 及完整路径、带权 DBA、用户提供初始中心的 DTW/DBA 聚类。
- 新增按样本下标线性重采样、逐特征标准化和预处理到聚类的组合接口；扩展 JSON、文件 CLI 和浏览器工作台。
- 新增小规模路径穷举、tslearn 数值交叉验证、预算 / 空簇 / 常量特征边界及文件与浏览器场景；旧 0.1.2 功能继续保留。
- 新增 UCI 公开传感器数据的六段三维窗口示例、来源许可和复算，不能据此推断人数或业务准确率。
- 相近能力与 moon-geometry、MoonSTRtree 和 tslearn 存在实际重合，详见相关工作；算法与集成贡献不应称为原创算法。

## 0.1.2

- 更改 / 导入 / 切换输入后，清除过期结果和下载状态；计算期间将请求设为只读，使结果与启动时的输入保持对应。
- 文档修正 JSON 默认 gamma 为实际的0.5，并补充省略该参数时的独立解析值断言。

## 0.1.1

- 补充发布包的独立消费验证脚本，可在新模块从 Mooncakes 下载并验证值 / 梯度 / 拟合 / 排序及 JS / Wasm-GC 运行。
- 浏览器自动化等待远程示例异步加载，避免仅在本机快响应时成立的检查。
- CLI 版本从包元数据读取，减少多处版本号不一致；修正接口文档中错误字段回显范围的说明。
- 留存三系统四后端和线上浏览器的实际验证来源。

## 0.1.0

首次公开版本：纯 MoonBit Soft-DTW / 自项校正、双方梯度、带权原型拟合和完整候选排序；typed API、严格 JSON、Node CLI、浏览器 Worker 工作台；独立穷举 / tslearn 对照、三系统 CI 和 Apache-2.0 许可。
