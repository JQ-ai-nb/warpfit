# 真实传感器数据示例及许可

本目录随项目提供的 `examples/uci-room.json` 是从公开数据集中选择的**小规模衍生样本**，用于复现数值处理和聚类流程。它不是本项目采集的数据，不包含原始日期、时间或房间人数标签。

## 来源与许可

Singh, A. & Chaudhari, S. (2018). *Room Occupancy Estimation* [Dataset], UCI Machine Learning Repository, <https://doi.org/10.24432/C5P605>。数据集页面：<https://archive.ics.uci.edu/dataset/864/room+occupancy+estimation>。UCI 页面标明原始数据采用 [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)；本衍生数据保留相同的来源和许可声明。WarpFit 自有程序代码仍使用仓库的 Apache-2.0 许可证，不能将数据集默认归入该代码许可证。

原数据来自受控实验中的房间环境传感器，数据集网站描述为每约 30 秒采集一次，传感器包括温度、光照、声音和 CO₂。此处仅选择 S1 温度、S1 光照、S5 CO₂ 三个数值列；未使用人数标签。由使用者从公共数据导出的样本可能包含测量值，仍应按照实际业务情境处理数据权限。

## 选择方式和可复现性

下载 UCI 页面提供的 ZIP 后，使用 `python scripts/derive_uci_room.py 路径/room-occupancy-estimation.zip --check` 校对衍生数据。已验证的原始压缩包 SHA-256 为 `a0db79ee96ea297c22458ac77a28fba20d41246e75d24b2655ca3ab624cc08fd`；若上游重新打包，请先人工核对修订，脚本不会默默接受校验和不同的数据。

从 CSV 表头之后的第 0、1800、3600、5400、7200、9000 行开始，各取连续 60 行，按原先顺序保留三个列的数值，组成 6 条三维序列。没有使用人数标签选种子或计算标签；这只是固定步长抽取的小样本，不保证具有总体代表性。输入 JSON 设置重采样至 48 点、逐序列逐维标准化、窗口 4、以第 0 和第 3 条作为初始中心，执行 DTW / DBA 聚类。

```text
node scripts/build.mjs
node bin/warpfit.mjs examples/uci-room.json
```

也可运行 `node scripts/serve.mjs`，选择“真实传感器数据”场景。一次本机运行得到分组 `[0,1,0,1,1,1]`，平均平方 DTW 代价约 `47.7270816929`，初始目标约 `115.0709036811`，3 次完整迭代后以 `improvement_tolerance` 停止。几条样本的部分特征为常量，标准化时按记录的策略设为 0。

`tests/uci_room_reference.py` 使用 tslearn 0.6.4 对**本项目返回的处理后样本与中心**重新计算 12 个硬 DTW 距离，得到相同最近中心标签和约 `47.7270816929` 的平均平方代价；不对完整训练轨迹或真实人数作推断。结果见 `docs/evidence/uci-room-reference.json`。

标准化会抹去每条窗口的绝对水平和尺度，尤其不适合直接据此判断室内人数、设备是否异常或作控制决策。重采样按样本下标而不理解真实采集时间；多个窗口来自同一受控实验，不能证明泛化能力、生产实用性或准确率。真实业务需另外评估时间间隔、尺度选择、标注、数据许可和有效性。

## 训练后预测不重叠的后续数据

新增三个相同来源、相同 CC BY 4.0 许可的衍生文件：[uci-model-train.json](../examples/uci-model-train.json)、[uci-model-test-data.json](../examples/uci-model-test-data.json)、[uci-model-split.json](../examples/uci-model-split.json)。后者记录列名、原始 ZIP 校验和和所有零基起始行。使用同一份10129行的CSV，训练起点为0..4500、每300行取一个60行窗口，共16段；测试起点为5000..9500、间隔相同，共16段。全部训练行早于测试行，各段之间不重叠；没有根据人数标签或最终结果选择窗口。

配置固定为3个特征、按下标重采样至48点、逐序列独立标准化、窗口4、2个簇、首样本0、最多10次聚类更新和每簇5次DBA、逻辑预算20000000。后续数据不用于选择中心或更新中心；每条后续序列仅独立计算自己的标准化统计。仍不能把该实验解释为预测未来数值，因为输入是完整窗口。

复现完整文件模型流程与基线报告：

```text
node scripts/build.mjs
node scripts/evaluate_holdout.mjs
```

脚本训练后将模型写入独立临时文件，再调用模型CLI加载并预测测试数据；文件返回结果与直接调用一致。临时文件在结束后清理，报告留在 `artifacts/uci-model-holdout.json`。也可以自行执行：

```text
node bin/warpfit-model.mjs train examples/uci-model-train.json work/uci-model.json
node bin/warpfit-model.mjs predict work/uci-model.json examples/uci-model-test-data.json
```

上面两个命令需要 work 目录存在，且模型输出文件尚不存在。重新校验衍生数据：`python scripts/derive_uci_holdout.py work/uci-room-occupancy.zip --check`；该命令检查原始压缩包SHA-256，并逐项比较32段数值及划分清单，原始ZIP不随项目分发。

本次固定划分结果：

| 数值量 | 初始中心 | DBA训练后的中心 |
|---|---:|---:|
| 16段训练输入到最近中心的平均平方DTW代价 | 115.3205589088 | 70.1786517873 |
| 16段后续输入到最近中心的平均平方DTW代价 | 135.3533878965 | 83.9299692157 |

初始中心由训练输入的确定性最远点选择得到（本次下标0、13）；两组中心使用完全相同的预处理、对齐窗口和距离定义。后续输入到中心的平均平方代价是距离指标，没有类别标签或业务阈值；这里只记录单次划分中数值下降，不保证换数据后仍下降。训练以 `improvement_tolerance` 停止，训练簇规模为8/8；后续分配为5/11。这是对“训练后文件复用”的实际验证，不是与其他算法或产品的优劣比较。

`tests/uci_model_holdout_reference.py` 以NumPy独立插值 / 标准化全部32段，检查4608个处理后数值，再用tslearn0.6.4复算两组中心到测试样本的64个距离及标签。最大预处理绝对差约2.33e-13，最大距离绝对差约4.80e-14；参考均值约83.9299692157和135.3533878965，与报告一致。记录见 [工作流结果](evidence/uci-model-holdout.json) 和 [参考复算](evidence/uci-model-holdout-reference.json)。

本实验只使用同一房间受控记录中的少量固定片段，没有跨房间、跨设备、多个划分、用户试用或业务标签验证；相邻记录仍可能有时间相关性，不能推断泛化能力。标准化消除绝对量纲的限制也继续适用。
