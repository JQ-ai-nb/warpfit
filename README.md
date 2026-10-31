# WarpFit — 可微分时序对齐与原型拟合

**状态：开发中，核心数值实验已通过；完整接口、工作流和发布验证正在补齐。**

维护者和本次申请人：蒋琦；GitHub / Mooncakes：`JQ-ai-nb`。个人参赛。开发使用 AI 辅助，参与者负责理解、核对和维护成果。

给定长度和节奏不同的数值序列，计算 Soft-DTW 损失、两侧输入梯度、对齐占用矩阵，以及自相似项校正目标；再通过有界回溯梯度下降拟合一条固定长度的参考模板。目标用户是时序模型、传感器应用和离线数值工具开发者。

算法来自公开论文，不宣称原创算法或世界唯一。当前用独立 MoonBit 实现验证核心公式；不是其他项目的插件，不调用 Python/FFmpeg/外部学习服务完成核心计算。Python 仅枚举小样本的全部对齐路径来验证结果。

## 本地运行

验证环境：MoonBit compiler `0.10.17+093cb8f9c`，moon `0.1.20261021`。

```text
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target js --deny-warn
moon run cmd/demo --target js
```

重建独立对照夹具：`python exhaustive_oracle.py`，然后重新运行测试。

演示中的固定合成输入得到：

```text
identical_raw=-0.5514447139320511
identical_corrected=0
prototype_initial=6.724196713736497
prototype_final=0.08787917729654145
accepted_steps=30
training_loss=0.7998364090182977
training_gradient_first=-0.11180129274548832
query_same=0
query_stretched=0.1813520905973129
query_changed=1.7031942663182167
```

这些数字只证明该输入下的计算与优化行为，不证明分类准确率、真实设备效果、全局最优或生产采用。原始 Soft-DTW 可以为负；不得将它直接解释为普通距离、置信度或通过/失败结论。

## 已实现的实验范围

- 非空、同特征维度的有限数值序列；每条 1..128 个采样点、1..8 个特征，值域 ±10000。
- 平方欧氏局部代价，正有限平滑参数；数值稳定的 soft-min 前向与反向计算。
- 对两侧原始数值的梯度；对齐矩阵表示格点访问占用，行和不一定为 1。
- 自项校正值及其两侧梯度；不会将任意参数组合包装为已经证明满足度量公理。
- 最多 16 个示例、100 次迭代的固定长度模板拟合；接受步满足计算目标下降。
- 7 项 MoonBit 测试，其中一项涵盖 40 组独立穷举对照，检查值、两侧梯度和占用矩阵；另有有限差分与输入边界检查。

## 仍未完成

三个固定合成数值场景的实际输入和输出见 [SCENARIOS.md](docs/SCENARIOS.md)。完整参赛交付还需要：版本化 JSON/文件 CLI、面向用户的场景操作入口、可视化界面、完整终止状态与工作预算、成熟实现数值交叉验证、规模基准、公共 API 文档、CI 以及账号绑定后的发布。

本次按维护者指定绑定 `JQ-ai-nb/warpfit`。公开仓库、远程 CI 与 Mooncakes 的真实状态在完成后记录；本页当前不将计划中的地址当作已完成发布，也不声称已经报名或通过审核。

## 调研、来源与许可

- 完整选题调查和当前规则核对在 `D:\CodexProjects\WageKitNextResearch_20261031`。
- [Soft-DTW 论文，2017](https://proceedings.mlr.press/v70/cuturi17a.html)。
- [自相似项校正目标论文，2021](https://proceedings.mlr.press/v130/blondel21a.html)。
- [Google Research 参考实现，Apache-2.0](https://github.com/google-research/soft-dtw-divergences)。
- [tslearn，BSD-2-Clause](https://github.com/tslearn-team/tslearn)。
- [MoonSTRtree 已有的轨迹接口](https://github.com/LING71671/MoonSTRtree/blob/main/src/extensions/trajectory/pkg.generated.mbti)包括普通 DTW；本项目不以普通 DTW 距离主张新增价值。

本实验源码采用 Apache-2.0，AI 辅助设计、编码和测试。算法关系如实披露；研究目录保存的外部文档不属于本项目原创代码。主实现仅依赖 MoonBit 标准库，其许可说明见 `THIRD_PARTY_NOTICES.md`。报名材料按维护者转述的工作人员允许 AI 辅助的口径准备，提交与诚信承诺由本人核实完成。
