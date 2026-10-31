# 相关工作、独立价值和排重边界

核对日期：2026-10-31。主要证据是公开 README、接口、论文和注册表元数据；未声称对整个生态完整穷尽检索。名字不同、增加界面或用 MoonBit 重写都不足以独立证明创新性。

| 项目 / 来源 | 已核对能力 / 许可 | WarpFit 的关系和区别 |
|---|---|---|
| [MoonSTRtree 轨迹包接口](https://github.com/LING71671/MoonSTRtree/blob/main/src/extensions/trajectory/pkg.generated.mbti) | 普通 / 归一化 DTW、Fréchet 等轨迹计算；Apache-2.0 | 普通 DTW 不再主张空白；核对接口未见平滑双向梯度、自项校正或原型学习。WarpFit 不依赖该包，不复制其代码 |
| [moonbit-seqkit](https://github.com/clhhhhhh/moonbit-seqkit) | 数值序列统计、变换、清洗、滑窗与距离等；MIT | 应用数据相邻；本项目专注可微分对齐与实际优化，不替代通用序列工具 |
| [mblondel/soft-dtw](https://github.com/mblondel/soft-dtw) | Soft-DTW、梯度、时序平均；BSD-2-Clause | 已有成熟的算法实现，不声称算法创新；未复制源代码 |
| [Google soft-dtw-divergences](https://github.com/google-research/soft-dtw-divergences) | 校正值及梯度；Apache-2.0，仓库归档 | 校正算法参考来源，不把自项校正冒称新发明；独立实现并验证 |
| [tslearn](https://github.com/tslearn-team/tslearn) / [原型接口](https://tslearn.readthedocs.io/en/stable/gen_modules/barycenters/tslearn.barycenters.softdtw_barycenter.html) | 更广的 Python 时序学习、Soft-DTW、原型与聚类；BSD-2-Clause | 真正竞争 / 替代方案。用0.6.4版本对值、双方梯度、占用交叉验证；不声称功能更全或速度更快 |

算法论文：[Soft-DTW 2017](https://proceedings.mlr.press/v70/cuturi17a.html)、[Differentiable Divergences 2021](https://proceedings.mlr.press/v130/blondel21a.html)。查证 Mooncakes 名称 / 描述 / 关键词和 GitHub 公开检索；私有、未发布、未索引项目仍可能存在。未命中不能推出不存在，后续发现相近工程应继续披露。

## 本次实际交付的贡献

1. 可直接供 MoonBit 程序使用的独立学习内核：稳定求值、两侧求导、正确处理自项梯度、带权模板实际优化。依赖仅标准库，不需要 Python 服务。
2. 可核对的输入与资源契约：每矩阵与总逻辑工作量、完整候选排序、明确终止状态，预算耗尽保留最后完整优化点。预算是可解释的计算控制，不冒充精确时间预测。
3. 同一核心驱动 typed API、版本化 JSON、文件 / stdin CLI 和浏览器 Worker；有从文件输入到结果下载的完整工作流与独立数值证据。

这些是实现与集成方面的贡献，能否达到竞赛的新项目价值要求由评委判断。尚无生产采用或真实用户需求访谈，不保证初审或季度评选。

## 与本人既往项目的关系

本项目的数值核心、拟合器、候选排名和测试从公式独立编写，没有从既往参赛工程复制核心后改名。它不以 Wasm 体积分析、MCP 安全包装、审核证据工具、表关联预检或事件窗口为主功能。通用安装 / CI 配置采用常见工程做法，不将其当作算法贡献。开发使用 AI 辅助，不隐瞒这一过程。

本地排重还核对了当前设备可访问的近期工程与记录；没有访问其他账号的私有聊天或私有代码，因此无法证明与不可访问内容绝无重合。AgentCanary 仅作为既往项目核对，未把它称为已被驳回项目。
