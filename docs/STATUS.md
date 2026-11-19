# WarpFit 版本与验收验证

汇总于 2026-11-19（UTC+8）。参赛人蒋琦，项目登记名为 **WarpFit：时序对齐、模板学习与聚类**，账号与包命名空间为 `JQ-ai-nb`。参赛者提供的十一月通知确认**报名初审已通过**，最终验收以组委会通知为准。

Mooncakes 已发布 `JQ-ai-nb/warpfit@0.2.4`，发布基线为 `v0.2.4`（`8e56c0f`）。GitHub `main` 汇集后续验收文档和源码修复。以下验证记录标明实际验证的包版本或源码提交。

## 版本与交付

| 项目 | 已核对事实 | 依据 |
| --- | --- | --- |
| 参赛仓库 | `JQ-ai-nb/warpfit`，公开，默认分支 `main` | [GitHub 参赛仓库](https://github.com/JQ-ai-nb/warpfit) · [公开版本核查](evidence/release-0.2.4-20261119.json) |
| 版本标签 | 公开标签 `v0.2.4` 指向 `8e56c0f` | [该标签的源码](https://github.com/JQ-ai-nb/warpfit/tree/v0.2.4) · [公开版本核查](evidence/release-0.2.4-20261119.json) |
| 仓库模块元数据 | `moon.mod` 与 `package.json` 均声明 `0.2.4` | [模块声明](../moon.mod) · [Node 工具元数据](../package.json) |
| Mooncakes | `JQ-ai-nb/warpfit@0.2.4` 已可下载，构建状态 `success` | [0.2.4 包页面](https://mooncakes.io/docs/JQ-ai-nb/warpfit@0.2.4) · [公开版本核查](evidence/release-0.2.4-20261119.json) |
| 独立安装 | 空注册表缓存安装精确版本 `0.2.4`，Wasm、Wasm-GC、JS 各通过 10 组公共接口检查。库示例也在该环境中返回两个中心和标签 `[0, 1]` | [空缓存的安装证据](evidence/consumer-registry-0.2.4-20261118.json) · [另一次安装记录](evidence/consumer-registry-0.2.4-20261119.json) |
| 远程 CI | 发布提交 `8e56c0f` 和验收文档更新 `7796505` 均通过 Linux、macOS、Windows 的检查、构建和测试 | [发布提交 CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089456) · [验收文档更新 CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/44431383508) · [main 的 CI 列表](https://github.com/JQ-ai-nb/warpfit/actions/workflows/ci.yml?query=branch%3Amain) |
| 工作台 | 公开提交 `7796505` 的 Pages 部署后复测通过 | [部署记录](https://github.com/JQ-ai-nb/warpfit/actions/runs/44431383824) · [在线工作台](https://jq-ai-nb.github.io/warpfit/) |

0.1.2 是十月公开原型。十一月版本加入约束 DTW、DBA、聚类与模型复用、分类和子序列检索，0.2.1 至 0.2.4 继续补全与修复。各版本变更见 [CHANGELOG.md](../CHANGELOG.md) 和 [十一月新增说明](NOVEMBER.md)。

## 本地实测

本机工具链为 MoonBit CLI 0.1.20261021、moonc 0.10.17+093cb8f9c、Node v24.22.1。记录对应 `8e56c0f` 的数值核心。远程 CI 与本地复跑各自对应表内的环境。

| 层 | 已测结果 | 依据 |
| --- | --- | --- |
| MoonBit 源码 | 四目标静态检查、格式及接口无差异。Wasm、Wasm-GC、JS 各 125/125 项测试及构建通过 | [本机验证](evidence/validation-0.2.4-20261119.json) |
| Node CLI | 45/45 项测试通过 | [本机验证](evidence/validation-0.2.4-20261119.json) |
| CLI 示例与接口 | 24 个请求各运行两次且输出一致，另外 3 个 JSON 仅作数据输入。22 个操作均有请求示例及 API 文档条目 | [本机验证](evidence/validation-0.2.4-20261119.json) |
| 预算和确定性 | 22 个接收预算的示例通过收紧与放宽检查。12 个生成请求各连续运行两次且输出逐字节一致 | [本机验证](evidence/validation-0.2.4-20261119.json) |
| 本地发布格式归档 | 实际 MoonBit 归档通过内容检查与隔离消费。`registry_install_verified: false`，归档检查使用本地 ZIP | [本机验证](evidence/validation-0.2.4-20261119.json) |
| 独立演示包 | 解压到新目录后运行 Node，在 PATH 中无 MoonBit 的条件下通过 10 组检查 | [本机验证](evidence/validation-0.2.4-20261119.json) |
| 本地浏览器 | 对解压演示包运行 24/24 项 Chromium 检查，页面错误及外部网络请求均为 0 | [本地浏览器证据](evidence/browser-0.2.4-20261119.json) |

本机未运行 native 测试或构建。基线在远程 CI 的三个操作系统上已运行对应检查。CLI 从 Mooncakes 下载的包另有独立安装记录。

## 发布后的源码维护

`5408228` 改善了命令行保存结果和生成演示包的行为。输入与输出指向同一文件时，CLI 会保留原输入。演示 ZIP 通过解压自检后才替换旧包。

该提交的本机全量验证通过。Wasm、Wasm-GC、JS 各通过 125 项 MoonBit 测试，Node 通过 46 项。24 个 CLI 请求示例和解压演示包的 10 组检查全部通过。另验证了候选 ZIP 自检失败时旧包的内容保持一致。 [本轮源码验证](evidence/file-preservation-5408228.json)

## 复核命令

在源码根目录运行。登记中的浏览器和注册表证据按 `moon.mod` 的确切版本查找，缺少当期结果时会标记待记录。可加 `--json` 输出给其他脚本使用。

```text
python verify.py
python exhaustive_oracle.py --check
node scripts/evidence_report.mjs
node scripts/check_examples.mjs
node scripts/budget_check.mjs
node scripts/determinism_check.mjs
node scripts/api_coverage.mjs
```

## 核心实现与参考验证

`git ls-files '*.mbt'` 统计 `8e56c0f` 的已跟踪 MoonBit 文件。产品与示例源码 28 个文件，5,898 行，其中 5,264 行非空且不以 `//` 开头。按相同口径，30 个 `*_wbtest.mbt` 测试文件共 5,228 行，4,948 行非空且非行注释。这些数字供定位和复核，不作为成绩或创新指标。

| 核对项 | 固定用例范围 | 来源 |
| --- | --- | --- |
| tslearn 0.6.4 对照 | 硬 DTW 160 组、单步 DBA 80 组、聚类 9 组、预处理 100 组、完整流程 1 组 | [硬 DTW 对照](evidence/hard-reference.json) · [Soft-DTW 对照](evidence/tslearn.json) |
| 独立枚举和距离交叉核对 | 240 组硬 DTW 路径、256 组子序列路径，另有 1,200 组两行 DP 与完整路径对照。计数取自测试名称 | [测试原始输出](evidence/clean-current.json) |
| 子序列和最近邻参考 | 120 组子序列 tslearn 对照、24 组 kNN 参考 | [子序列](evidence/subsequence-reference.json) · [kNN](evidence/knn-reference.json) |
| 真实传感器固定划分 | 16 段训练，16 段不重叠的留出窗口。对照 4,608 个预处理数值和 64 个 DTW 距离 | [数据方法](REAL_DATA.md) · [距离对照](evidence/uci-model-holdout-reference.json) |

独立数值对照与历史记录见 [验证记录](VALIDATION.md)。本期验收所需材料见 [验收自查](ACCEPTANCE.md)。
