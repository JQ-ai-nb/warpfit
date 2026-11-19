# WarpFit 十一月验收自查

参赛人蒋琦，GitHub 和 Mooncakes 命名空间为 `JQ-ai-nb`。登记项目为 **WarpFit：时序对齐、模板学习与聚类**。参赛者提供的十一月通知确认报名初审已通过，后续按原申报方向维护。最终验收以组委会评估为准。参赛仓库为 [JQ-ai-nb/warpfit](https://github.com/JQ-ai-nb/warpfit)。

核对日期为 2026-11-19（UTC+8）。官网和章程说明项目开发、开源及验收要求，本页结合初审通知记录可复核材料。具体提交安排以组委会的十一月通知为准。 [赛事官网](https://moonbitlang.github.io/Hackathon2026/) · [黑客松章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)

| 核对项 | 当前可核对的材料 |
| --- | --- |
| 围绕已申报方向开发 | 同一 WarpFit 在十月公开原型上扩展了窗口对齐、DBA、分组及模型复用等流程。变更按版本列明。 [十一月新增](NOVEMBER.md) · [版本记录](../CHANGELOG.md) |
| MoonBit 主要实现与生态相关性 | 库接口、数值核心和 JSON 分发由 MoonBit 实现，供 MoonBit 调用方、Wasm 和本地网页复用。说明已有关联工具的实际重合。 [MoonBit 库用法](LIBRARY.md) · [相关工作](RELATED_WORK.md) |
| 公开提交记录、README 和使用说明 | 已发布源码及提交身份经公开仓库核对。本地维护说明与对应测试记录见状态页。 [README](../README.md) · [状态与证据](STATUS.md) |
| 可运行场景与代码质量 | 对齐、DBA、建模与预测都可从示例运行。`verify.py` 核对源码、构建、测试、归档及独立消费。 [验收演示](ACCEPTANCE_DEMO.md) · [验证记录](VALIDATION.md) |
| 发布和安装 | `0.2.4` 已发布并通过空缓存的指定版本安装检查。验证用的是公开包，许可和接口来源可追溯。 [包页面](https://mooncakes.io/docs/JQ-ai-nb/warpfit) · [安装证据](evidence/consumer-registry-0.2.4-20261118.json) |
| 持续集成 | `v0.2.4` 的发布提交及核查时的公开 `main` 均通过三系统 CI。本轮在独立本地分支验证维护改动。 [发布提交 CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089456) · [公开 main CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/44347124218) |
| 开源合规 | 代码采用 Apache-2.0。保留编译产物的标准库 LICENSE / NOTICE，UCI 原始来源与 CC BY 4.0 单列。 [许可证](../LICENSE) · [第三方声明](../THIRD_PARTY_NOTICES.md) · [数据说明](REAL_DATA.md) |
| AI 辅助与项目理解 | 保留选型和实验边界，参赛人可按讲解文档复跑并说明结果。 [AI 及设计取舍](AI_AND_DECISIONS.md) · [机制与演示](WALKTHROUGH.md) |

## 复现发布包与本地归档

```text
python scripts/registry_consumer.py --version 0.2.4
python scripts/package_check.py
python scripts/registry_consumer.py --packaged
python scripts/package_demo.py
```

第一条从 Mooncakes 下载指定版本并在独立工程调用公开接口。第二、三条生成并使用本地 MoonBit 归档，冻结依赖运行。最后一条生成 Node 可运行的离线演示 ZIP，并在解压目录执行检查。各自的报告以相应模块、版本和来源标记。

本轮维护核对版本与证据，修正验证工具及使用说明。登记方向、许可核对及待组委会明确的事项见 [验收后续核对](ACCEPTANCE_GAP.md)。
