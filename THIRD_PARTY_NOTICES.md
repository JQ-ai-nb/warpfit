# 来源和依赖

## MoonBit 标准库

实验仅使用 `moonbitlang/core` 的数学、数组和基础类型，标准库采用 Apache-2.0。
本地验证使用安装工具链附带的匹配版本。`node scripts/build.mjs` 将匹配标准库的 LICENSE 和 NOTICE 随生成的 Node / 浏览器引擎复制；对外分发这些编译产物时应一并保留。生成目录同时保留本项目 Apache-2.0 许可证。

## 算法来源

- Cuturi、Blondel，Soft-DTW: a Differentiable Loss Function for Time-Series，ICML 2017：<https://proceedings.mlr.press/v70/cuturi17a.html>。
- Blondel、Mensch、Vert，Differentiable Divergences Between Time Series，AISTATS 2021：<https://proceedings.mlr.press/v130/blondel21a.html>。

实验从公式独立实现前向 soft-min、其逆序自动微分和自项校正，不声称算法首创。Python 对照使用全部单调对齐路径的直接枚举，不使用相同的动态规划递推。

## 已比较的参考工程

- `mblondel/soft-dtw`：BSD-2-Clause。
- `google-research/soft-dtw-divergences`：Apache-2.0。
- `tslearn-team/tslearn`：BSD-2-Clause。
- `LING71671/MoonSTRtree`：Apache-2.0。

上述项目的功能与许可证通过公开资料核对。没有将其源码或测试夹具复制到本实验中；后续如发生移植、代码复用或数据引用，应逐项更新来源和许可说明。
