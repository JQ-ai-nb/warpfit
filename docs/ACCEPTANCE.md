# 十一月验收自查与维护记录

检查日期：2026-11-14。参赛人：蒋琦；GitHub / Mooncakes 模块命名：JQ-ai-nb。

## 验收对照表（2026-11-18 复核）

官方口径来自[赛事官网](https://moonbitlang.github.io/Hackathon2026/)与[章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)列出的六条，加上章程验收段落的发布与 CI 要求。数字只在 [STATUS.md](STATUS.md) 维护，本表只做映射。

| 要求 | 状态 | 可核对的东西 | 复核方式 |
| --- | --- | --- | --- |
| MoonBit 为主要实现 | 具备 | 核心 27 个 `.mbt`（排除测试）；Node 只做文件、页面与 Worker 包装 | STATUS.md「代码规模」 |
| 公开仓库与开发记录 | 具备：远程 main 与本地一致，提交作者单一（JQ-ai-nb） | 提交历史、CHANGELOG | `git rev-parse HEAD` 与 `git ls-remote origin main` |
| 可运行、可检查、可测试 | 具备 | 117 项 × 三后端、43 项 Node、24 项浏览器、20 个示例 | `node scripts/check_examples.mjs` |
| 本期实质新增 | 具备 | 0.2.0：26 个功能提交 / 43 文件 / +2,532 行；0.2.1–0.2.2：7 个新操作 + 5 项修复 | CHANGELOG.md、NOVEMBER.md |
| 开源合规 | 具备 | Apache-2.0；四类来源声明；UCI 数据 CC BY 4.0（含 DOI 与校验和） | THIRD_PARTY_NOTICES.md、REAL_DATA.md |
| AI 可解释 | 具备 | 目标与边界、关键取舍、AI 参与环节、人工核对边界 | AI_AND_DECISIONS.md、SEMANTICS.md、WALKTHROUGH.md |
| 发布到 mooncakes.io | 具备 | 0.2.3，构建 `success`，独立消费验证 `verified: true` | `evidence/consumer-registry-0.2.3-20261118.json` |
| CI 覆盖检查、构建、测试 | 具备 | 三系统 × 四目标 + 浏览器 + 证据一致性 + 示例稳定性；提交 `a9734c3` 全绿 | [run 44312371517](https://github.com/JQ-ai-nb/warpfit/actions/runs/44312371517) |

### 仍差的事项（截至 2026-11-18）

1. **发布通道**：`github.com:443` 在本机不稳定（直连超时、代理 502），必要时用 Git Data API 发布；仓库内容与 CI 结果不受影响。
1. **申报材料的版本措辞**：申报书正文写的是 0.2.0，当前实际为 0.2.3。是否需要改由参赛者按报名表要求决定。
2. **十一月确切截止日**：官网写「以官方通知为准」，需按组委会通知核对。

---

以下为历史记录，保留当时状态。


2026-11-17 更新：0.2.0 源码（`8195d88`）已推送；后续文档提交不改变源码，三系统 CI 均通过（main 最新 CI 见 Actions）；Mooncakes 0.2.0 已发布，注册表安装验证通过。以下 2026-11-14 记录保留当时状态：本轮按用户要求只做本地维护，未推送或发布；最近已公开的源码提交当时是 `8695d8a`，其三系统四后端 CI 与在线页面验证见 [VALIDATION.md](VALIDATION.md)。本轮新增独立消费样例和包验证，结果另行记录，不冒充线上版本已有能力。

2026-11-18 更新：0.2.1 已发布（tag `v0.2.1` 指向 `d6c15e4`），四后端各 110 项测试与注册表安装验证通过（该次记录为 113 项；main 现为 117 项，以 [STATUS.md](STATUS.md) 为准）；新增 `knn_pruned`、`subsequence_topk`、`cross_validate`、`medoids`、`motifs`、`outliers`、`describe`。

## 规则来源及适用范围

直接核对了[十一月赛事官网](https://moonbitlang.github.io/Hackathon2026/)及其链接的[黑客松章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)。官网列出MoonBit为主、公开可追踪、可运行与测试、实质新增、开源合规及AI可解释；章程的验收段落还要求发布到mooncakes.io，并使用CI覆盖检查、构建和测试。

本地 `osc2026-guide` 的通用工程清单仅作辅助；其八月时间、提交数量与活动限定不代替十一月规则。现行章程仍混有九月及十月日期，官网十一月截止时间明确以官方通知为准，不能据旧日期推定当前期限。维护方向报名状态、完整初审意见及具体提交期限仍需参赛者以组委会记录核对。

## 逐项核对

| 项目 | 已有证据 / 本轮处理 | 结论 |
|---|---|---|
| MoonBit为主要实现语言 | 数值核心、版本化JSON入口、类型示例在core/api/cmd；Node负责文件、网页和Worker包装 | 具备；不以生成代码或测试行数证明创新 |
| 公开仓库及开发记录 | JQ-ai-nb/warpfit公开main已含DTW、DBA、聚类、模型和子序列；保留十月0.1.2基础及十一月实质新增关系 | 0.2.0 源码 `8195d88` 已推送；CI 44095202653 与文档提交 CI 44106313819 均通过 |
| 可检查、构建、测试 | 已公开修订三系统四后端CI通过；本轮verify.py增加消费示例和实际归档包的外部工程验证 | 本轮结果见验证记录；未执行新版远程CI |
| 至少一个完整可运行示例 | 已有对齐、DBA、聚类、模型文件流程和真实数据；新增cmd/consumer统一演示10组公共能力（含最近邻分类与选簇数） | 可在本地运行 |
| 申报主要功能真实有效 | DTW约束、DBA和聚类均有核心实现；模型、子序列及有界长输入有测试和独立参考 | 已覆盖可见邮件中的功能建议；独立价值仍由评审判断 |
| 发布到Mooncakes | 0.2.0 已于 2026-11-17 发布；注册表安装验证返回 `registry install verified: True` | **已完成 0.2.0 发布及注册表消费验证** |
| 包内容、安装可用性 | 检查正确版本包、公共接口、许可证和数据归属文件；独立工程只依赖解出的归档包，通过冻结本地workspace验证 | 这是归档包验证，不能替代Mooncakes安装 |
| 开源合规 | Apache-2.0代码、标准库分发声明、UCI数据CC BY 4.0、参考项目及许可证有独立说明 | 具备说明；继续保持来源更新 |
| AI可解释与维护责任 | 提供数值语义、算法讲解、真实反例与复现命令 | 参赛者须亲自掌握目标、实现和边界，工具无法代替本人理解 |
| 隐私和身份 | 姓名与项目账号统一；电话、私人邮箱、认证文件不进入公开源码及发布包 | 每次推送与发布前继续检查 |

## 本轮补齐的消费验证

旧消费脚本只检查0.1.x的损失、梯度、拟合和排序；新版调用窗口DTW、距离专用计算、带权DBA、自动初始化与聚类模型、新批次同簇预测、子序列、600点输入重采样，并保留旧能力断言；后又加入最近邻分类（`knn_classify`，断言`label=="a"`、3个邻居、`votes==[2,1]`）与簇数选择（`select_cluster_count`，断言`best_k==3`、两条候选结果），共10组。

```text
moon run cmd/consumer --target js --deny-warn
python scripts/package_check.py
python scripts/registry_consumer.py --packaged
```

归档模式解压实际包，在独立目录创建consumer和local workspace，校对模块名与版本后执行 `--frozen` 检查及Wasm / Wasm-GC / JS运行。源码通过公开的Series结构和接口使用库，不依赖库内部测试辅助函数。不拉取注册表索引，不复制工作区core到consumer工程；依赖来源就是解出的归档包。它明确输出 `registry_install_verified: false`。

将来完成注册表发布后，再执行默认模式：

```text
python scripts/registry_consumer.py --version 0.2.0
```

该模式仅将consumer列为隔离workspace成员，不包含WarpFit本地模块或path替换，指定版本从Mooncakes安装并运行同一个示例，避免上级工程覆盖依赖。新增的手动 `Verify published package` 工作流可在发布后检查三系统及native；该工作流随 0.2.0 源码推送，尚未执行，不能称为已通过。

## 验收前仍需本人处理

在明确允许发布后，用JQ-ai-nb完成Mooncakes授权，发布经过验证的0.2.0包并检查注册表安装；同步本轮源码后等待相应CI。报名、群昵称、个人及收款资料和申报内容由蒋琦本人核对，仓库字段只填一个纯地址。参赛人曾说明官方允许AI辅助申报书，现行章程同时存在相关限制文字，应保留适用答复并对材料承担责任。

这份报告是有证据边界的工程自查，不是组委会验收结论，不保证初审或获奖。
