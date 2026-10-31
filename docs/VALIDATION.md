# 已运行的验证与结果

本地记录日期：2026-10-31。机器：Windows x64 / Intel Core i7-14650HX，Node v24.22.1，Python3.12；moon0.1.20261021，moonc0.10.17+093cb8f9c。CI 使用官方稳定安装器，日志保留实际版本，不能由本机版本假定未来工具链一致。

## 实际检查

- `moon check --target all --deny-warn`、`moon fmt --check`、`moon info` 与接口差异检查：通过。
- `moon test` 的 wasm / wasm-gc / js 目标：各31项通过；对应 build 和两个 cmd 示例实际运行通过。
- `node --test tests/cli.test.mjs tests/numerical.test.mjs`：13项通过。
- 浏览器自动化：三个场景、图形、下载、重复键错误、Worker取消、390px布局无横向溢出；无 pageerror、无向外部的数据请求。[记录](evidence/browser.json)。
- 实际 `moon package --list` 及 zip 内容检查：包含核心 / README / 许可，排除 work、deliverables、artifacts、.git 和 node_modules。
- 原生目标本机因缺 MSVC 无法运行；CI 配置在 Linux / macOS / Windows 检查四个后端，远程真实状态以 [Actions](https://github.com/JQ-ai-nb/warpfit/actions) 对应提交为准。不能把 CI 文件存在当作验证已通过。

## 独立数值对照

**完整路径枚举**：`python exhaustive_oracle.py` 以固定种子20261031生成80组小序列，长度1..4、维数1..2，包含零 / 非等权特征。对每种可能的单调对齐路径直接求成本与 Gibbs 权重，不使用主程序相同的 DP 递推；验证 raw / corrected 值、两侧梯度和占用。夹具重新生成后由 CI 检查无差异，并同时在 MoonBit 测试与 JSON 引擎中验证。1个 MoonBit 测试包含80组夹具，未把它写成80个测试函数。

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
