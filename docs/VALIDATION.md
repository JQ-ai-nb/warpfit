# 已运行的验证与结果

> 本页分别记录远程验证和推送前的本地验证。历史记录中“未推送 / 未发布”描述当次检查时的状态，不应据此推断当前默认分支或注册表版本；远程结果均对应下列具体提交。2026-11-17 已将 0.2.0 源码推送至公开 main（`8195d88`），三系统 CI 通过。Mooncakes 0.2.0 已于 2026-11-17 发布，`registry_consumer.py --version 0.2.0` 返回 `registry install verified: True`；源码 CI 与注册表安装是两项独立验证。

## 2026-11-19 0.2.4 发布后复核（当前版本）

- 本地全量复跑：`moon fmt --check`、`moon check --target all --deny-warn`、Wasm / Wasm-GC / JS 各 125/125、Node 45/45、`npm run check` 五项全通过（示例 24/24、预算 22/22、确定性 12/12、API 覆盖 22/22、证据 19/19）。
- 远程：main `8e56c0f` 的 [CI](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089456) 三系统全绿，同提交 [工作台部署](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089959) 成功。
- Mooncakes：页面显示 0.2.4 / Apache-2.0；[注册表消费验证](evidence/consumer-registry-0.2.4-20261119.json) `registry_install_verified: True`，10/10，wasm / wasm-gc / js 三目标通过。
- 本机 native 仍未运行（缺 MSVC），由远程 CI 覆盖；浏览器 24/24 为本地证据，线上最新公开证据仍是 0.2.0 的 22 项。
- 以下各节为历史记录，其中的 82 / 110 / 113 / 117 项和 0.2.x 版本号只描述当时状态，当前数字以 [STATUS.md](STATUS.md) 为准。

## 2026-11-18 推送与三系统 CI

- 15:11（UTC+8）推送 10 个提交与 `v0.2.2`、`v0.2.3` 两个 tag 到 `JQ-ai-nb/warpfit`；远程 main 与本地一致。仓库全部提交的作者只有 `蒋琦 <314918884+JQ-ai-nb@users.noreply.github.com>`。
- 首次 CI（`a4e5883`）三系统同时失败，原因不是算法而是 `moon fmt --check`：最后几轮改动后没有格式化，`verify.py` 在第一步失败，后面的证据一致性、示例稳定性与浏览器检查都被跳过。已在 `a9734c3` 修复。
- `a9734c3` 的 CI 三系统全绿：<https://github.com/JQ-ai-nb/warpfit/actions/runs/44312371517>；Pages 部署成功：<https://github.com/JQ-ai-nb/warpfit/actions/runs/44312371459>。
- 期间 `github.com:443` 在本机不可达（直连超时、代理 CONNECT 502），修复提交改由 Git Data API 发布：blob → tree → commit → 更新 ref，本地与远程树一致，随后把同一个提交对象写回本地并更新 ref，`git rev-list --count origin/main..HEAD` 为 0。

## 2026-11-18 0.2.3 发布（文档与验证工具）

- 0.2.3 无接口与算法变更：README 首屏重写、`docs/STATUS.md` 成为数字的唯一出处、新增 `scripts/evidence_report.mjs` 与 `scripts/check_examples.mjs` 并接入 CI。
- `moon publish` 返回 `Server status: 200 OK`，Mooncakes 构建状态 `success`，`latest_version` 为 0.2.3。
- 注册表消费验证：首次执行因 `operation timed out` 失败，第二次通过，`registry install verified: True`，三目标均返回 0。记录见 `evidence/consumer-registry-0.2.3-20261118.json`。
- 发布前本机复跑：四目标类型检查通过，Wasm / Wasm-GC / JS 各 117/117，Node 43/43，示例 20/20 两次一致，证据一致性 19/19。

## 2026-11-18 0.2.2 发布

- 发布前本机复跑：四目标类型检查通过；Wasm / Wasm-GC / JS 各 117/117；Node 43/43；浏览器 24/24。
- `moon publish` 返回 Server status 200 OK，Mooncakes 构建状态 `success`。
- `python scripts/registry_consumer.py --version 0.2.2` 返回 `registry install verified: True`，隔离 workspace 中 Wasm / Wasm-GC / JS 均通过（首次尝试因网络 `operation timed out` 失败，重试通过，记录保留）。
- 0.2.2 相对 0.2.1 的实质变更：`knn_pruned` 并列代价、`subsequence_topk` 压缩回退、`medoids` 重复样本、`motifs` 排除半径、`cross_validate` 分层分折。

## 2026-11-18 验收前复跑（commit `9c3a102`）

> 本节是 `9c3a102` 当时的历史记录，表内为 113 项。此后新增 4 条回归测试（并列剪枝、top-k 回退、常量 medoids、标签顺序），当前 main 为 117 项，以 [STATUS.md](STATUS.md) 为准。

验收前对当前 main 做了一次完整复跑，命令与结果如下，均为本机实测（moon 0.1.20261021 / moonc 0.10.17 / Node 22 / Windows）：

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| 四目标类型检查 | `moon check --target all --deny-warn` | 通过 |
| MoonBit 测试（Wasm-GC） | `moon test --target wasm-gc --deny-warn` | 113/113 |
| MoonBit 测试（Wasm） | `moon test --target wasm --deny-warn` | 113/113 |
| MoonBit 测试（JS） | `moon test --target js --deny-warn` | 113/113 |
| Node 测试 | `node --test tests/*.test.mjs` | 43/43 |
| 浏览器工作台 | `node tests/browser.mjs`（本地 4194，系统 Chrome 158） | 24/24，0 pageerror，0 外部请求 |
| README 的 11 条 CLI 示例 | `node bin/warpfit.mjs examples/*.json` | 11/11 `ok:true` |
| 畸形输入 16 例 | 空、截断、`null`、数组顶层、未知 operation、operation 为数字、缺字段、类型错、空序列、`NaN`、重复键、80 层嵌套、5 万元素、未知字段、schema 不匹配 | 全部返回 `ok:false`，无进程崩溃 |

本机 native 未运行（缺 MSVC），由远程 CI 覆盖。源码规模按可复核口径统计：5,631 行（27 个 `.mbt`，排除 `*_wbtest.mbt`；其中有效代码 5,068 行，不含空行与注释；含测试共 10,666 行）。

## 2026-11-17 推送与远程 CI

- `8195d88` 已推送至公开 main；[CI 44095202653](https://github.com/JQ-ai-nb/warpfit/actions/runs/44095202653) 在 Linux / macOS / Windows 全部通过，包含 `verify.py --native`、独立数值对照和 Linux 浏览器检查。
- 本机 Wasm / Wasm-GC / JS 各 82 项 MoonBit 测试、Node 43 项、Chromium 24 项通过；本机 native 缺 MSVC，远程 native 已通过。
- Mooncakes 0.2.0 已发布；`python scripts/registry_consumer.py --version 0.2.0` 通过（`registry install verified: True`），隔离 workspace 中 Wasm / Wasm-GC / JS 均通过。

## 2026-11-18 边界测试增强

- 新增 4 项边界回归测试（`core/robustness_wbtest.mbt`，72 行）：极端 gamma、k 等于训练集大小且距离全等、窗口覆盖全矩阵、8192→512 重采样。
- 当前 main 的四后端各 110/110（2026-11-18 复跑后为 113/113）；0.2.1 发布包（tag `v0.2.1`）为 110/110；0.2.0 发布包为 82/82。
- 新增 JSON 操作：`knn_pruned`、`subsequence_topk`、`cross_validate`、`medoids`、`motifs`、`outliers`、`describe`；这些已包含在 0.2.1，0.2.0 不包含。
- 2026-11-18：0.2.1 已发布到 Mooncakes；tag `v0.2.1` 指向 `d6c15e4`；`registry_consumer --version 0.2.1` 返回 `registry install verified: True`。

## 2026-11-15 DBA 与逐点平均对照（未推送 / 未发布）

- 2026-11-15 新增 DBA 与逐点平均的对照测试（`tests/auto_model.test.mjs`）：两条错位单峰序列在 DTW 下距离为 0，逐点平均模板峰值为 0.5、目标 0.5；以样例为初值的 DBA 保持峰值 1、目标 0。本机 MoonBit 仍 82 项，Node 测试增至 43 项；相关提交未推送，远程记录仍为 71 / 38 项。

## 2026-11-15 参考证据改为显式更新（未推送 / 未发布）

- 2026-11-15 本轮把 `tests/knn_reference.py` 的证据写入改成显式操作，避免每次 `python verify.py` 都改写受版本控制的证据文件。默认模式只写忽略目录 `artifacts/knn-reference.json` 并在末尾打印 `evidence: current` 或 `evidence: STALE`（不改变退出码）；实测连续执行两次后 `git status --short` 只显示本轮改动的 `tests/knn_reference.py`，忽略目录无输出。`--evidence` 才写 `docs/evidence/knn-reference.json`，固定 `newline="\n"`（提交后复核文件为 LF 且以换行结尾），除 `recorded_at_utc` / `python` 外无变化时跳过并打印 `evidence: unchanged`；本轮首次执行打印 `evidence: updated`，`git diff` 只多出 `recorded_at_utc` 与新增的 `engine_commit`，24 组随机 KNN 复算、邻居下标 / 距离、`best_k` 与两组轮廓系数逐位未变。`--check-evidence` 只读比较、忽略 `recorded_at_utc` / `python` / 仅表示来源的 `engine_commit`，提交证据后运行退出码 0 并打印 `evidence: current`；手工把 `randomized_knn_cases` 改为 25、`select_k_example.best_k` 改为 4 后运行，退出码 1、打印 `evidence: STALE` 并列出 `randomized_knn_cases` 与 `select_k_example.best_k` 两个差异键，随后已还原原文件。`engine_commit` 取自 `git rev-parse --short HEAD`（失败记 `unknown`），因为它随提交变化，故不参与一致性判定，只作来源标记。同一工作树的 `python verify.py` 22 条命令全部通过，结束后的 `git status --short` 为空。上述仍是本机本地检查，未推送 / 未发布，不推断远程 CI 或注册表状态。

## 2026-11-14 本地验收维护（未推送 / 未发布）

- 2026-11-15 网页工作台新增“最近邻分类”与“自动选簇数”后，对本地提交 `ba9f16e` 的工作树运行（`8695d8a` 之后共 9 个本地提交，本条对应其中最后两个） `node tests/browser.mjs`：Chromium 148.0.7778.96 实际完成 **12 个场景 / 24 项浏览器检查**，全部通过。新增检查分别断言 `label=rise`、`votes=[2,1]`、`best_k=3`、`scores` 长度 2 且第二个 `silhouette` 更大，并确认邻居表与按 k 表格已渲染；无 pageerror、无外部数据请求。同一工作树的 `moon test --deny-warn`（80 项）、`node --test tests/cli.test.mjs`（13 项）、`node scripts/build.mjs` 与 `python verify.py`（22 条命令）均通过。Playwright 以 `npm i --no-save --no-package-lock` 临时安装，未改 `package.json`；浏览器二进制复用本机缓存并通过 `CHROME_PATH` 指定。原始输出在忽略目录 `artifacts/browser.json`，本条仍为本地运行，未推送 / 未发布。
- 2026-11-15 本地新增最近邻分类（`knn`）与轮廓系数选簇数（`select_k`）后，`python verify.py` 再次完整通过：Wasm / Wasm-GC / JS 各 80 项 MoonBit 测试、42 项 Node 测试、`tests/knn_reference.py` 的 24 组随机 KNN 复算与轮廓系数独立重算。相关提交仍在本地，未推送；远程 CI 记录仍对应 71 / 38 项，两者不可混称。
- `python verify.py` 完整通过：所有目标静态检查、格式、接口；Wasm / Wasm-GC / JS各71项MoonBit测试和构建；38项Node测试；四个类型示例；实际包检查；3项消费脚本边界测试及独立归档消费。记录见 [acceptance-local-20261114.json](evidence/acceptance-local-20261114.json)。原有测试函数数量未把新增示例的断言混算进去。
- `cmd/consumer` 只使用公开接口。实际0.2.0包解压后，在独立workspace执行冻结依赖检查和三个后端运行，8组能力均通过：约束DTW、距离专用计算、DBA、聚类模型和同簇预测、子序列、长输入预处理、软梯度、拟合 / 排序。[归档消费记录](evidence/consumer-package-20261114.json)明确 `registry_install_verified: false`，不是Mooncakes安装证明。
- 包验证脚本的3项集成测试检查：拒绝版本中的manifest片段、拒绝归档与请求版本不一致、拒绝ZIP路径越界。手动注册表消费工作流已准备且YAML解析通过，尚未推送或执行；不能把它写成新远程CI已通过。
- 本轮没有改变数值算法，也没有重新宣称业务准确率。之前公开源码的远程CI和在线22项浏览器结果保留在下文；本轮新增消费样例的native运行、注册表0.2.0发布和安装仍待后续完成。

官方要求、证据及需本人核对的事项见 [验收自查](ACCEPTANCE.md)，可运行的机制说明见 [讲解与演示](WALKTHROUGH.md)。

## 2026-11-15 本地基准扩展（未推送 / 未发布）

- 2026-11-15 本机把 `knn` 与 `select_k` 加入 `node scripts/benchmark_hard.mjs` 后，先 `node scripts/build.mjs` 再连续执行两次：两次结果除 `*_ms` 与 `recorded_at_utc` 外完全相同，`label=rise`、`neighbor_indices=[7,4,1]`、两组候选的 `best_k=3`、`work_units`（6291456 / 14241792 / 19021824）及轮廓系数（0.7376476627063869 / 0.9904726456141449 / 0.9684146792639692）逐位一致。数据全为合成输入：32 条 256 点 × 3 维训练序列（`rise` 单调升、`fall` 单调降、`flat` 常数 0.5 带极小抖动、`bump` 单峰，各 8 条，用幅度 0.9 / 1.0 / 1.1 与轻微相位抖动区分，三维为同一形状的缩放加偏移）的单次 k=3 查询，以及 32 条 64 点一维序列在 `[2,3]` / `[2,3,4]` 上的选簇；本机单进程中调用同一 JS 引擎，耗时含 JSON 解析与序列化，一行 `ok:true` 断言失败即抛错，脚本还会在 `dist/engine.mjs` 早于 `core` / `api` 源文件时以退出码 1 提示先构建。两轮中位数分别为 knn 61.00 / 61.24ms、`[2,3]` 129.65 / 137.97ms、`[2,3,4]` 183.43 / 189.30ms（证据文件记录第二轮）。新行追加在 [benchmark-hard.json](evidence/benchmark-hard.json) 末尾，原有 DTW / 流程行与顶层元数据保留。这是本机单次测量记录，不是 SLA，也不跨机器可比、没有与竞品做公平性能比较。同轮 `python verify.py` 的 22 条命令全部通过。

## 2026-11-15 归档包消费扩展（未推送 / 未发布）

- 2026-11-15 `cmd/consumer` 在原有8组之后追加两组公开接口断言：`a:[0.0]`、`a:[0.2]`、`b:[9.0]` 训练、查询 `[0.1]`、`k=3` 断言 `label=="a"`、`neighbors.length()==3`、`votes==[2,1]`（不断言浮点距离）；六条一维序列 `[0.0, 0.1, 5.0, 5.1, 10.0, 10.1]` 在候选 `[2,3]` 上断言 `best_k==3`、`scores.length()==2`。标记行只在尾部追加 `, knn, select_k`，原有名称不变。重新执行 `moon package` 生成归档后：`python scripts/package_check.py` 检查150个文件，并要求归档包含 `core/classify.mbt`、`core/autok.mbt` 且 `core/pkg.generated.mbti` 含 `pub fn knn_classify` 与 `pub fn select_cluster_count`；`python scripts/registry_consumer.py --packaged` 的冻结依赖检查与 Wasm / Wasm-GC / JS 三次运行均返回0，三个后端末行均为 `warpfit_consumer_ok: dtw, distance_only, dba, cluster_model, subsequence, long_preprocess, soft_gradient, fit_rank, knn, select_k`。记录见 [归档消费记录](evidence/consumer-package-20261115.json)，仍是归档包验证（`registry_install_verified: false`），不是Mooncakes安装结果。同一工作树的 `python verify.py` 22 条命令全部通过。本机仍缺MSVC，`--native` 未运行，native 未验证。

## 0.2.0 公开源码与远程验证（2026-11-13，历史记录）

- 授权服务端、仓库所有者、提交作者及提交者均核对为 `JQ-ai-nb`；源码修订 `bb8c309b286eb7d5ebfa25b268426db7b6a4ddc5` 已推送公开默认分支 main，窗口DTW、DBA、聚类、模型与子序列等文件均已逐项核对存在。
- [CI 43449875490](https://github.com/JQ-ai-nb/warpfit/actions/runs/43449875490) 的 Linux、macOS、Windows 三个任务全部成功。下载三个真实验证产物检查：每系统的 Wasm / Wasm-GC / JS / native 各71项 MoonBit测试及构建通过，Node各38项通过；Linux另完成22项浏览器检查。[真实产物摘要](evidence/remote-validation-0.2.0.json)。这是新版远程结果，区别于下文0.1.2的历史CI。
- [工作台部署 43449875437](https://github.com/JQ-ai-nb/warpfit/actions/runs/43449875437) 成功后，对实际公开地址 <https://jq-ai-nb.github.io/warpfit/> 执行完整浏览器流程：22项通过，覆盖10个场景、模型文件往返、输入错误、预算、取消和390px布局；无页面错误或外部数据请求。[在线页面验证](evidence/browser-public-0.2.0.json)。
- 这是 2026-11-13 的历史结论；2026-11-17 已发布 0.2.0，并通过注册表安装验证。没有虚构业务准确率或审核结果。

## 0.2.0 本次维护（2026-11-13，历史记录）

- `python verify.py` 实际通过：Windows 本地的 `moon check --target all --deny-warn`、格式与生成接口检查；Wasm、Wasm-GC、JS 各71项 MoonBit 测试及构建；三个类型示例；构建共用 JSON 引擎；38项 Node 测试和实际 Mooncakes 打包内容检查。命令及输出见 [validation-current.json](evidence/validation-current.json)。这是测试函数数量，下面列出的批量样本数量另算，没有混称为独立测试函数。
- 本轮先复现再修复模型 / 数据文档边界问题：原来独立无效的文件 `模型JSON + ,"options":{...}` 可被拼成合法请求并影响预测参数。现在每个文件先验证为单个完整 JSON，保留原文供 MoonBit 进一步检测重复键。回归测试覆盖模型和数据文件各自附加字段、连续文档；原始重复键拒绝及文件往返测试继续通过，网页导入也拒绝并保留当前请求。
- 新增16段训练 / 16段不重叠后续输入的公开数据实验，训练后经过实际模型文件保存、读取及CLI预测，结果与直接调用一致。基线与学习中心均仅来自训练输入；后续平均平方DTW代价由135.3533878965变为83.9299692157。独立NumPy / tslearn复核4608个预处理数值、64个距离及标签，最大距离绝对差约4.80e-14。原始ZIP校验及衍生数据逐项比较通过，来源、划分、限制和证据见 [REAL_DATA.md](REAL_DATA.md#训练后预测不重叠的后续数据)。该实验没有业务标签或准确率含义，也不能保证换数据仍改善。
- 本轮从提交 `9a6cee2` 重新导出到空目录，全部目标检查、格式、JS的71项 MoonBit测试、38项 Node测试、80组夹具独立重算和实际打包检查通过：[clean-holdout.json](evidence/clean-holdout.json)。构建 / 测试未复制缓存，打包前为导出目录建立独立Git索引；没有创建提交。它包含本次文件边界修复、真实数据划分及新增脚本；仍只是同机工具链验证。
- `tests/subsequence.test.mjs` 独立枚举256组完整查询 / 开放目标路径，检查最小代价、返回路径和最早结束；另验证2000点目标的匹配位置、窗口拒绝和矩阵预算。`tests/subsequence_reference.py` 与 tslearn 0.6.4 对照120组带权多变量输入，距离最大绝对差 `8.881784197001252e-16`、终点一致；不要求并列回溯路径相同：[subsequence-reference.json](evidence/subsequence-reference.json)。
- 距离专用两行 DP 与完整路径实现比较1200组不同长度、维数、权重和窗口的输入，并额外比较1/512等极端长度比例；相同的路径代价、距离和访问格点计数均通过。它是内部不同实现的一致性验证，不能取代独立路径枚举及外部参考，也不是性能优于其他项目的证据。
- 模型相关测试实际执行自动 / 手动初始化比较、文件保存及重新读取、全新批次预测、全部新样本同簇、初始化与训练共享预算、预算中断不写模型、错误版本与重复键、拒绝文件覆盖。长输入测试验证2880点显式重采样到100点，以及600点数据的分析流程；超过8192点拒绝，原有普通 DTW 的512点限制仍有效。
- 本地 Chromium 148.0.7778.96 实际完成22项浏览器检查，包含10个内置场景、模型下载和重新导入、重复键、拒绝多文档模型、延迟导入与切换请求、8192点×16特征的预处理与绘图、预算提示、Worker取消及390px布局。无 pageerror 或外部数据请求。见 [browser-nov.json](evidence/browser-nov.json) 和 [模型界面](screenshots/model.png) / [子序列界面](screenshots/subsequence.png)。
- 从本地提交 `ccb83ce` 用 `git archive` 重新导出到空目录，不复制构建缓存；全部目标检查、格式、JS的71项 MoonBit测试、35项 Node测试、80组 Soft-DTW 夹具独立重算和打包内容检查通过：[clean-current.json](evidence/clean-current.json)。初次打包为空：导出目录位于父仓库忽略的 work 下，继承了父 Git 根目录。构建和测试均在无 .git 状态执行；打包前为导出目录建立独立 Git 索引并暂存源文件后通过，没有制造提交或修改源码。记录保留初次失败及处理方式。这仍是同机工具链验证，不是远程检出或跨系统结果。
- 本机缺少 MSVC，native 运行在 2026-11-13 尚未验证；2026-11-17 的远程 CI 已覆盖 native，0.2.0 也已发布并通过注册表安装验证。完整检查的原始输出保存在忽略目录 `artifacts/validation.json`；公开证据仅将本机 Python 可执行文件的绝对路径改成可移植的 `python`，其余命令参数与结果不变。

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
