# 已运行的验证与结果

## 0.2.0 本地扩展（2026-11-11，未推送 / 未发布）

- 本地 Windows 的 `moon check --target all --deny-warn`、格式与生成接口检查通过；Wasm、Wasm-GC、JS 目标各执行 59 项 MoonBit 测试并构建通过。本机缺少 MSVC，native 运行和新版远程多系统 CI **尚未验证**。
- Node CLI / 数值测试共23项通过；本地 Chrome 覆盖7个页面场景、导入、计算、预算提示、取消、下载及390px布局，无页面错误和外部请求。浏览器证据见 [browser-nov.json](evidence/browser-nov.json)。
- `tests/exhaustive_hard.test.mjs` 逐一枚举 240 组长度1..4的硬 DTW 合法完整路径，覆盖全部16种长度组合、一维/二维、无窗口及不同窗口，检查最小代价、实际路径和边界。80组 DBA 与30组聚类性质用例另复算目标、逐点最近中心和预算停止状态。
- `tests/reference_hard.py` 使用 tslearn 0.6.4 / NumPy 2.2.6 对照160组带权硬 DTW、80组单步带权 DBA（含不等长和窗口）、9组聚类、100组预处理及1组完整流程。非例外比较的最大绝对差约2.57e-15，断言容差 rtol=atol=1e-8；结果见 [hard-reference.json](evidence/hard-reference.json)。DBA 是单步对照，不能据此声称任意初始化和收敛行为完全一致。
- **常量特征的参考差异：**100组预处理对照中有常量维；本项目按标准差≤1e-12归零。tslearn 0.6.4 对其中7个常量特征因浮点舍入输出非零，本项目依照自身明确语义直接验证为0；这些维度没有被当作“与 tslearn 一致”，最大原始差异约2.236。其他维度按参考值比较，详情见证据文件。
- `node scripts/benchmark_hard.mjs` 在本机 Node v24.22.1 记录长度32/128/512、1/3特征的窗口与无窗口硬 DTW，以及16条64点序列的组合流程。数据为合成输入，JSON处理计入耗时；见 [benchmark-hard.json](evidence/benchmark-hard.json)，不当作 SLA 或与竞品的公平性能比较。
- 缺口：尚无真实设备数据、用户试用、聚类质量基准、生产采用或初审通过证明。截图中评审意见的后半段不可见，需要继续核对完整要求。扩展并不保证审核结果。

## 以下为 0.1.2 已发布版本的历史记录

本地记录日期：2026-10-31。机器：Windows x64 / Intel Core i7-14650HX，Node v24.22.1，Python3.12；moon0.1.20261021，moonc0.10.17+093cb8f9c。CI 使用官方稳定安装器，日志保留实际版本，不能由本机版本假定未来工具链一致。

## 实际检查

- `moon check --target all --deny-warn`、`moon fmt --check`、`moon info` 与接口差异检查：通过。
- `moon test` 的 wasm / wasm-gc / js 目标：各31项通过；对应 build 和两个 cmd 示例实际运行通过。
- `node --test tests/cli.test.mjs tests/numerical.test.mjs`：13项通过。
- 浏览器自动化：三个场景、图形、下载、重复键错误、Worker取消、390px布局无横向溢出；无 pageerror、无向外部的数据请求。[记录](evidence/browser.json)。
- 实际 `moon package --list` 及 zip 内容检查：包含核心 / README / 许可，排除 work、deliverables、artifacts、.git 和 node_modules。
- 原生目标本机因缺 MSVC 无法运行；[d16e3a4 的远程 CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/41190749483) 已实际通过 Linux / macOS / Windows 三系统、四后端的检查 / 构建 / 测试，Linux 浏览器流程也通过。最新状态以 [Actions](https://github.com/JQ-ai-nb/warpfit/actions) 对应提交为准。
- Mooncakes 0.1.0 已实际发布，并在全新模块中从注册表下载，check all、JS / Wasm-GC 运行均通过：解析损失9、预测梯度-6、拟合目标点5、排序首项 exact。当前版本发布后可用 `python scripts/registry_consumer.py` 独立复验；它读取 moon.mod 中的版本，没有 path 依赖或复制本地核心。
- 公开 [Pages 页面](https://jq-ai-nb.github.io/warpfit/) 已实际运行同一套浏览器用例，三个场景、结果下载、错误处理、取消与移动布局均通过。

## 独立数值对照

**完整路径枚举**：`python exhaustive_oracle.py` 以固定种子20261031生成80组小序列，长度1..4、维数1..2，包含零 / 非等权特征。对每种可能的单调对齐路径直接求成本与 Gibbs 权重，不使用主程序相同的 DP 递推；验证 raw / corrected 值、两侧梯度和占用。CI 用 `python exhaustive_oracle.py --check` 重新独立计算，输入与参数逐项精确比较，数值结果按 `1e-12*(1+abs(expected))` 比较，容忍不同系统 libm 的末位舍入差异；不将浮点夹具字节相同当作正确性条件。夹具同时在 MoonBit 测试与 JSON 引擎验证。1个 MoonBit 测试包含80组夹具，未把它写成80个测试函数。

**成熟实现交叉对照**：tslearn0.6.4 / NumPy2.2.6，固定种子1031、60组长度1..14 / 维数1..4的加权输入，各检查 raw / corrected，共120个目标。tslearn 的 raw occupancy 在 sqrt(weight) 缩放轴上计算；由该占用独立得到输入梯度，自项导数两侧都计入。值、双方梯度和占用的最大绝对差 `1.3159251466277055e-11`，阈值 atol / rtol 均2e-8。[实际记录](evidence/tslearn.json)。没有移植 tslearn 的优化器，也没有将其原型函数结果冒充相同校正目标的最优解。

可选复现（依赖仅供参考验证，主程序不依赖）：

```text
python -m pip install --target work/reference-deps tslearn==0.6.4
node scripts/build.mjs
python tests/tslearn_reference.py
```

**解析 / 差分 / 性质测试**：单点平方损失及梯度、带权单点模板均值、多变量中心有限差分、外部模型链式梯度、平移不变性、梯度总和平衡、极小 gamma / 受支持极值的有限结果。另测预算耗尽不返回试探点，完整排序与并列稳定次序，输入数组不变。

## 可复现规模测量

`node scripts/benchmark.mjs` 测本机 JS 引擎的 corrected loss（含双方梯度、占用及 JSON 处理），2次预热、7次计时。32 / 128 / 512采样、1和3特征；512采样的中位数约124–127ms。完整机器、参数和各次范围见 [benchmark.json](evidence/benchmark.json)。不同维数的近似耗时受 JIT、垃圾回收和系统负载影响；这不是跨机器保证，也没有与竞品做公平性能比较。

## 证据限制

所有随附数据为合成 / 数学样例。没有真实设备、医疗 / 工业决策、生产采用、准确率、吞吐 SLA 或全局收敛证据。数值一致性不能推出用户业务结论；资源工作量也不是 CPU / 内存精确上界。后续应围绕实际调用者数据补充需求、尺度选择和效果验证。
