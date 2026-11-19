# WarpFit 验收后续核对

2026-11-19 复核。蒋琦的 **WarpFit：时序对齐、模板学习与聚类** 已通过十一月报名初审。发布基线、复核时的公开 `main` 和本地维护记录可按提交查阅。 [参赛仓库](https://github.com/JQ-ai-nb/warpfit) · [版本与验证状态](STATUS.md)

- **提交安排。** 初审通知要求继续按原方向开发，并保持提交、README、许可证和说明完整。最终提交时间及是否要补充新版材料，以组委会通知为准。已通过初审的申报内容可留作历史记录。
- **许可证与署名。** 项目根 `LICENSE` 与本机匹配 SDK 的 `moonbitlang/core` 许可证全文一致（比较时统一换行），末尾保留其上游版权行。`moon new` 生成的新模块许可证与该文件不同。此处记录文件来源的可核对事实，项目单独的版权声明须依据实际权属确认。参赛与开发记录中的维护身份为蒋琦 / `JQ-ai-nb`。 [根许可证](../LICENSE) · [第三方声明](../THIRD_PARTY_NOTICES.md) · [Apache-2.0 正文](https://www.apache.org/licenses/LICENSE-2.0.txt)
- **部署与浏览器。** 已公开代码的 Pages 部署成功。本轮 24 项浏览器检查实际运行于解压后的本地演示包。 [部署记录](https://github.com/JQ-ai-nb/warpfit/actions/runs/44347124171) · [本地实测](evidence/browser-0.2.4-20261119.json)
- **注册表与平台。** Windows 上的独立工程已完成指定版本安装并运行 Wasm、Wasm-GC、JS。公开源码 CI 覆盖三系统和 native。公开的三系统注册表验证工作流在 2026-11-19 核查时尚无运行记录。 [空缓存安装记录](evidence/consumer-registry-0.2.4-20261118.json) · [公开状态核查](evidence/release-0.2.4-20261119.json)
