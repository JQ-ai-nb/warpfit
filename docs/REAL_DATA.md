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
