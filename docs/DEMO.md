# WarpFit 本地演示包

本包供解压运行和验收复现，来源是蒋琦 / JQ-ai-nb 维护的 [WarpFit 参赛仓库](https://github.com/JQ-ai-nb/warpfit)。它是现有项目的十一月维护版本，不是另一个新项目。**本地打包不代表已推送，也不代表已发布到 Mooncakes**；注册表地址为 [JQ-ai-nb/warpfit](https://mooncakes.io/docs/JQ-ai-nb/warpfit)，那里已有的 0.1.2 不包含全部 0.2.0 新接口。

需要 Node.js ≥22；数值核心是由 MoonBit 编译的 JavaScript，Node 负责文件和 HTTP 包装。解压后的演示不需要 MoonBit SDK、Python、npm 安装或外部计算服务。完整的 MoonBit 源码、类型接口和开发测试应查看参赛仓库或另行提供的源码包；不要将本运行包作为 Mooncakes 源码包上传。

## 一键复现

在解压后的 `WarpFit-demo-0.2.0` 目录打开终端：

```text
node scripts/check_demo.mjs
```

脚本核对文件 SHA-256、CLI 版本、约束对齐、DBA 模板、预处理与分组、模型文件往返、子序列定位、固定真实数据划分以及静态网页资源，共9组检查。结果写入 `artifacts/demo-check.json`，成功时 `status` 为 `passed`。它使用本包文件，创建并清理自己的模型临时文件，不需要访问互联网；失败时请保留报告，不要手动把状态改成通过。

`DEMO_MANIFEST.json` 记录源码提交、打包时是否有未提交改动及各文件校验值，用于识别混用文件或损坏，**不是数字签名或第三方验收证明**。若打包时 PATH 中没有 MoonBit，报告的 `sdk_absence_verified` 为 true；日常运行时装有 SDK 也不影响使用。

## 三个完整使用场景

1. **有限偏移的周期对齐。** 信号分析开发者输入 `examples/align.json` 中两条四点序列，运行下列命令；窗口为1时得到距离0及完整路径。验证脚本还将窗口改为0，检查平方路径代价为2，展示约束确实影响结果。

   ```text
   node bin/warpfit.mjs examples/align.json
   ```

2. **学习重复观测的模板。** 传感器应用开发者输入 `examples/dba.json` 的三条不同长度观测和四点初始模板，运行下列命令；输出学习后的四点模板、目标轨迹、预算及停止状态。本固定示例目标由约0.166667降为0.118056；不能推断任意数据都改善。

   ```text
   node bin/warpfit.mjs examples/dba.json
   ```

3. **训练后保存模型，供新数据分组。** 离线应用开发者输入 `model_train.json`，学习两个中心并写入模型；再输入 `model_predict_data.json` 的新序列，预期标签为 `[0,1,0]`，同时返回距离。验证脚本实际保存、重新读取模型，并确认再次训练不会覆盖已有文件。手动操作前确保输出文件尚不存在：

   ```text
   node -e "require('node:fs').mkdirSync('work',{recursive:true})"
   node bin/warpfit-model.mjs train examples/model_train.json work/my-model.json
   node bin/warpfit-model.mjs predict work/my-model.json examples/model_predict_data.json
   ```

另可运行 `node bin/warpfit.mjs examples/subsequence.json`，查询 `[0,1,0]` 在目标记录中匹配区间为下标2..4，距离0。

## 真实数据与网页

```text
node scripts/evaluate_holdout.mjs
node scripts/serve.mjs
```

第一条使用已附带、无需下载的 UCI 房间传感器节选：16段较早输入训练，另16段不重叠的后续输入预测。初始中心的后续平均平方DTW距离约135.353388，学习中心约83.929969；这只是一组固定划分的距离比较，没有使用人数标签，**不是分类准确率、异常检测或实际用户采用证明**。来源、列选择、划分与 CC BY 4.0 声明见 `docs/REAL_DATA.md`。

第二条启动本地工作台，默认打开 <http://127.0.0.1:4194>，选择示例后运行，也可导入 JSON、下载模型及结果。网页仅在本机 Worker 计算；输入格式及规模受限，不接入设备或云端服务。在终端按 Ctrl+C 停止。`WARPFIT_PORT` 可指定其他端口，值为0时会分配并打印实际可用端口。启动后需用 HTTP 地址访问，不能直接双击 HTML。

运行包检查会核对网页文件及 HTTP 服务；完整的交互、取消、文件导入和窄屏验证另见源码的 `tests/browser.mjs`，需要额外安装 Playwright，因此不混入本包的无依赖检查。

## 边界与许可

分析序列最多512点、16维；预处理最多8192原始点且长输入须显式重采样。子序列目标最多8192点，仍受矩阵预算限制。逐序列标准化会移除绝对量纲；DBA、聚类及拟合不保证全局最优；不提供缺失值处理、真实时间戳、预测器或无候选的自动选簇数推断（`select_k` 仅在调用方给出的候选 k 中按轮廓系数选择）。详细语义见 `docs/SEMANTICS.md`。

代码为 Apache-2.0，保留根目录 LICENSE、第三方说明及两个引擎目录内的 MoonBit 标准库 LICENSE / NOTICE。UCI 数据示例单独采用 CC BY 4.0。算法来自公开研究，相关实现已有 tslearn 等成熟项目，不能将本包称为原创算法或世界唯一。设计、实现和测试使用 AI 辅助，由参赛者负责理解与核实。
