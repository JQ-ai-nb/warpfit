# 来源和依赖

## MoonBit 标准库

实验仅使用 `moonbitlang/core` 的数学、数组和基础类型，标准库采用 Apache-2.0。
本地验证使用安装工具链附带的匹配版本。`node scripts/build.mjs` 将匹配标准库的 LICENSE 和 NOTICE 随生成的 Node / 浏览器引擎复制；对外分发这些编译产物时应一并保留。生成目录同时保留本项目 Apache-2.0 许可证。

## 算法来源

- Cuturi、Blondel，Soft-DTW: a Differentiable Loss Function for Time-Series，ICML 2017：<https://proceedings.mlr.press/v70/cuturi17a.html>。
- Blondel、Mensch、Vert，Differentiable Divergences Between Time Series，AISTATS 2021：<https://proceedings.mlr.press/v130/blondel21a.html>。
- Petitjean、Ketterlin、Gançarski，A global averaging method for dynamic time warping, with applications to clustering，Pattern Recognition 44(3)，2011；参考 [tslearn DBA 文档](https://tslearn.readthedocs.io/en/stable/gen_modules/barycenters/tslearn.barycenters.dtw_barycenter_averaging.html) 的算法及接口描述。

实验从公式独立实现前向 soft-min、其逆序自动微分和自项校正，不声称算法首创。Python 对照使用全部单调对齐路径的直接枚举，不使用相同的动态规划递推。

## 已比较的参考工程

- `mblondel/soft-dtw`：BSD-2-Clause。
- `google-research/soft-dtw-divergences`：Apache-2.0。
- `tslearn-team/tslearn`：BSD-2-Clause。
- `LING71671/MoonSTRtree`：Apache-2.0。
- `walkzzz/moon-geometry`：MIT；其二维轨迹模块已有普通和窗口约束 DTW，与本项目存在功能重合。
- `grafana/augurs`：Apache-2.0 或 MIT；已提供 DTW 与聚类的 JavaScript / WebAssembly 接口。
- `wannesm/dtaidistance`：Apache-2.0；提供 DTW、子序列匹配和距离矩阵等能力。
- `aeon-toolkit/aeon`：BSD-3-Clause；提供多种时序距离与聚类功能。
- `DynamicTimeWarping/dtw-python`：GPL-3.0；此处仅作功能比较，没有复制其代码。
- `myc1234567/moon_metric_lab`、`liuminyuan/moon-missingness`：Apache-2.0；提供相关的聚类评价和缺失值处理能力。

上述项目的功能与许可证通过公开资料核对。没有将其源码或测试夹具复制到本实验中；后续如发生移植或代码复用，应逐项更新来源和许可说明。公开数据的引用单独列于下文。

## 公开数据示例

`examples/uci-room.json`、`examples/uci-model-train.json`、`examples/uci-model-test-data.json` 取自 Singh、Chaudhari 的 [Room Occupancy Estimation](https://doi.org/10.24432/C5P605) 数据集，并经过列选择和固定区间抽取；`uci-model-split.json` 记录后两者的划分与来源。数据集及其衍生示例采用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)，原始来源、修改方法和使用限制见 [docs/REAL_DATA.md](docs/REAL_DATA.md)；该数据与本项目 Apache-2.0 代码分开标注。
