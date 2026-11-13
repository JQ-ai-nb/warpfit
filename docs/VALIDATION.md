# 已运行的验证与结果

## 0.2.0 本次维护（2026-11-13，未推送 / 未发布）

- `python verify.py` 实际通过：Windows 本地的 `moon check --target all --deny-warn`、格式与生成接口检查；Wasm、Wasm-GC、JS 各71项 MoonBit 测试及构建；三个类型示例；构建共用 JSON 引擎；38项 Node 测试和实际 Mooncakes 打包内容检查。命令及输出见 [validation-current.json](evidence/validation-current.json)。这是测试函数数量，下面列出的批量样本数量另算，没有混称为独立测试函数。
- 本轮先复现再修复模型 / 数据文档边界问题：原来独立无效的文件 `模型JSON + ,"options":{...}` 可被拼成合法请求并影响预测参数。现在每个文件先验证为单个完整 JSON，保留原文供 MoonBit 进一步检测重复键。回归测试覆盖模型和数据文件各自附加字段、连续文档；原始重复键拒绝及文件往返测试继续通过，网页导入也拒绝并保留当前请求。
- 新增16段训练 / 16段不重叠后续输入的公开数据实验，训练后经过实际模型文件保存、读取及CLI预测，结果与直接调用一致。基线与学习中心均仅来自训练输入；后续平均平方DTW代价由135.3533878965变为83.9299692157。独立NumPy / tslearn复核4608个预处理数值、64个距离及标签，最大距离绝对差约4.80e-14。原始ZIP校验及衍生数据逐项比较通过，来源、划分、限制和证据见 [REAL_DATA.md](REAL_DATA.md#训练后预测不重叠的后续数据)。该实验没有业务标签或准确率含义，也不能保证换数据仍改善。
- `tests/subsequence.test.mjs` 独立枚举256组完整查询 / 开放目标路径，检查最小代价、返回路径和最早结束；另验证2000点目标的匹配位置、窗口拒绝和矩阵预算。`tests/subsequence_reference.py` 与 tslearn 0.6.4 对照120组带权多变量输入，距离最大绝对差 `8.881784197001252e-16`、终点一致；不要求并列回溯路径相同：[subsequence-reference.json](evidence/subsequence-reference.json)。
- 距离专用两行 DP 与完整路径实现比较1200组不同长度、维数、权重和窗口的输入，并额外比较1/512等极端长度比例；相同的路径代价、距离和访问格点计数均通过。它是内部不同实现的一致性验证，不能取代独立路径枚举及外部参考，也不是性能优于其他项目的证据。
- 模型相关测试实际执行自动 / 手动初始化比较、文件保存及重新读取、全新批次预测、全部新样本同簇、初始化与训练共享预算、预算中断不写模型、错误版本与重复键、拒绝文件覆盖。长输入测试验证2880点显式重采样到100点，以及600点数据的分析流程；超过8192点拒绝，原有普通 DTW 的512点限制仍有效。
- 本地 Chromium 148.0.7778.96 实际完成22项浏览器检查，包含10个内置场景、模型下载和重新导入、重复键、拒绝多文档模型、延迟导入与切换请求、8192点×16特征的预处理与绘图、预算提示、Worker取消及390px布局。无 pageerror 或外部数据请求。见 [browser-nov.json](evidence/browser-nov.json) 和 [模型界面](screenshots/model.png) / [子序列界面](screenshots/subsequence.png)。
- 从本地提交 `ccb83ce` 用 `git archive` 重新导出到空目录，不复制构建缓存；全部目标检查、格式、JS的71项 MoonBit测试、35项 Node测试、80组 Soft-DTW 夹具独立重算和打包内容检查通过：[clean-current.json](evidence/clean-current.json)。初次打包为空：导出目录位于父仓库忽略的 work 下，继承了父 Git 根目录。构建和测试均在无 .git 状态执行；打包前为导出目录建立独立 Git 索引并暂存源文件后通过，没有制造提交或修改源码。记录保留初次失败及处理方式。这仍是同机工具链验证，不是远程检出或跨系统结果。
- 本机缺少 MSVC，native 运行和新版远程多系统 CI **尚未验证**；本次仍未推送 / 发布，所以也没有新增接口的注册表安装结果。完整检查的原始输出保存在忽略目录 `artifacts/validation.json`；公开证据仅将本机 Python 可执行文件的绝对路径改成可移植的 `python`，其余命令参数与结果不变。

## 0.2.0 前一阶段的独立数值与数据验证

- 前一阶段从提交 `0360c4b` 用 `git archive` 导出源码到新目录，复用本机工具链重新检查全部目标、构建 JS 并运行 JS 的59项 MoonBit 测试及24项 Node 测试；另对照单独下载的 UCI 原始数据校验衍生样本，均通过。[历史记录](evidence/clean-copy-real.json)。该历史记录尚不包含本次新增接口；当前源码的重新导出验证见上文。导出源码测试不代表远程检出或其他机器上的结果。
- `tests/exhaustive_hard.test.mjs` 逐一枚举 240 组长度1..4的硬 DTW 合法完整路径，覆盖全部16种长度组合、一维/二维、无窗口及不同窗口，检查最小代价、实际路径和边界。80组 DBA 与30组聚类性质用例另复算目标、逐点最近中心和预算停止状态。
- `tests/reference_hard.py` 使用 tslearn 0.6.4 / NumPy 2.2.6 对照160组带权硬 DTW、80组单步带权 DBA（含不等长和窗口）、9组聚类、100组预处理及1组完整流程。非例外比较的最大绝对差约2.57e-15，断言容差 rtol=atol=1e-8；结果见 [hard-reference.json](evidence/hard-reference.json)。DBA 是单步对照，不能据此声称任意初始化和收敛行为完全一致。
- **常量特征的参考差异：**100组预处理对照中有常量维；本项目按标准差≤1e-12归零。tslearn 0.6.4 对其中7个常量特征因浮点舍入输出非零，本项目依照自身明确语义直接验证为0；这些维度没有被当作“与 tslearn 一致”，最大原始差异约2.236。其他维度按参考值比较，详情见证据文件。
- `node scripts/benchmark_hard.mjs` 在本机 Node v24.22.1 记录长度32/128/512、1/3特征的窗口与无窗口硬 DTW，以及16条64点序列的组合流程。数据为合成输入，JSON处理计入耗时；见 [benchmark-hard.json](evidence/benchmark-hard.json)，不当作 SLA 或与竞品的公平性能比较。
- 另使用 [UCI 房间环境传感器公开数据的六个固定窗口](REAL_DATA.md) 实际运行三维预处理与聚类；tslearn 对返回的样本与中心复算12个距离并复核标签、平均目标，绝对差约7.1e-15：[证据](evidence/uci-room-reference.json)。这是一个受控实验的小样本，不构成人数预测或业务效果证明。
- 缺口：尚无用户试用、聚类质量基准、生产采用或初审通过证明。截图中评审意见的后半段不可见，需要继续核对完整要求。扩展并不保证审核结果。

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

旧版验证使用合成 / 数学样例；新版另有上文所述公开传感器数据的小样本。没有真实部署、医疗 / 工业决策、生产采用、准确率、吞吐 SLA 或全局收敛证据。数值一致性不能推出用户业务结论；资源工作量也不是 CPU / 内存精确上界。后续应围绕实际调用者数据补充需求、尺度选择和效果验证。
