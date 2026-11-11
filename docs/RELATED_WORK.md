# 相关工作、独立价值和排重边界

补充核对日期：2026-11-11；原项目发表于10月，本次是在原仓库基础上的本地扩展。主要证据是公开 README、接口、论文和注册表元数据；未声称对整个生态完整穷尽检索。名字不同、增加界面或用 MoonBit 重写都不足以独立证明创新性。

| 项目 / 来源 | 已核对能力 / 许可 | WarpFit 的关系和区别 |
|---|---|---|
| [MoonSTRtree 轨迹包接口](https://github.com/LING71671/MoonSTRtree/blob/main/src/extensions/trajectory/pkg.generated.mbti) | 普通 / 归一化 DTW、Fréchet 等轨迹计算；Apache-2.0；另有空间点 DBSCAN | 存在实际重合；核对的轨迹接口未见本项目的 DBA 时序中心、Soft-DTW 梯度与组合流程。该结论不代表完整审计其全部包 |
| [moon-geometry 的 DTW 公共接口](https://github.com/walkzzz/moon-geometry/blob/main/spatial/dtw/pkg.generated.mbti) | MIT；`Point2D` 轨迹的普通、归一化及带窗口 DTW 距离 | 硬 DTW 与窗口约束已在 MoonBit 中存在，不能声称生态首创。核对的该模块公开接口只列出二维点距离相关函数；本项目还提供多变量数值、路径、软对齐、DBA 和聚类组合，未全面审计其余模块 |
| [moonbit-seqkit](https://github.com/clhhhhhh/moonbit-seqkit) | 数值序列统计、变换、清洗、滑窗与距离等；MIT | 应用数据相邻；本项目专注可微分对齐与实际优化，不替代通用序列工具 |
| [mblondel/soft-dtw](https://github.com/mblondel/soft-dtw) | Soft-DTW、梯度、时序平均；BSD-2-Clause | 已有成熟的算法实现，不声称算法创新；未复制源代码 |
| [Google soft-dtw-divergences](https://github.com/google-research/soft-dtw-divergences) | 校正值及梯度；Apache-2.0，仓库归档 | 校正算法参考来源，不把自项校正冒称新发明；独立实现并验证 |
| [tslearn](https://github.com/tslearn-team/tslearn) / [DBA 接口](https://tslearn.readthedocs.io/en/stable/gen_modules/barycenters/tslearn.barycenters.dtw_barycenter_averaging.html) | BSD-2-Clause；成熟 Python 工具，覆盖预处理、窗口 DTW、Soft-DTW、DBA 和聚类 | 多项能力与本项目直接重合，tslearn 的覆盖范围更广。本项目用0.6.4版本做数值交叉验证；不声称功能更全、速度更快或算法原创 |

算法参考：[Soft-DTW 2017](https://proceedings.mlr.press/v70/cuturi17a.html)、[Differentiable Divergences 2021](https://proceedings.mlr.press/v130/blondel21a.html)、[DBA 及参考文献](https://tslearn.readthedocs.io/en/stable/gen_modules/barycenters/tslearn.barycenters.dtw_barycenter_averaging.html)。2026-11-11 使用 `moon search dtw` / `moon search barycenter` 及公开接口检索；命中受搜索索引、包描述和可访问范围限制。私有、未发布、未索引项目仍可能存在，未命中不能推出不存在。

## 本次实际交付的贡献

1. 可直接供 MoonBit 程序使用的本地数值内核：硬 / 软对齐、两侧求导、硬路径 DBA、用户指定中心的聚类与简单预处理，依赖仅标准库。
2. 可核对的输入与资源契约：矩阵和总逻辑工作量、空簇错误、固定并列顺序、停止状态；预算耗尽保留最后完整优化点。预算不是精确时间预测。
3. 同一核心驱动类型接口、版本化 JSON、文件 / stdin CLI 和浏览器 Worker；实际串联预处理与聚类，并使用穷举及外部参考进行交叉验证。

这些是已有项目的实现与集成扩展，不是新发明。两项普通 / 窗口 DTW 功能与现有 MoonBit 模块重合，tslearn 覆盖更广；评委可能仍认为增量不足。能否按本期报名方向修改、是否具有足够独立价值由组委会判断。尚无生产采用或真实用户需求访谈，不保证初审或季度评选。

## 与本人既往项目的关系

本项目的数值核心、拟合器、候选排名和测试从公式独立编写，没有从既往参赛工程复制核心后改名。它不以 Wasm 体积分析、MCP 安全包装、审核证据工具、表关联预检或事件窗口为主功能。通用安装 / CI 配置采用常见工程做法，不将其当作算法贡献。开发使用 AI 辅助，不隐瞒这一过程。

本地排重还核对了当前设备可访问的近期工程与记录；没有访问其他账号的私有聊天或私有代码，因此无法证明与不可访问内容绝无重合。AgentCanary 仅作为既往项目核对，未把它称为已被驳回项目。
