# 当前状态（单一事实源）

本文件是项目所有可量化结论的**唯一出处**。其他文档只引用结论与命令，不重复数字；改数字只改这里，并在同一提交内更新对应证据文件。

记录时间：2026-11-19（UTC+8）｜工作树：干净。本文件不绑定提交哈希——那会在下一次提交后立刻失效；需要定位版本时用 `git log -1`。

## 版本与发布

| 项 | 值 | 依据 |
| --- | --- | --- |
| 包名 | `JQ-ai-nb/warpfit` | `moon.mod` |
| 当前版本 | **0.2.4** | `moon.mod` / `package.json` |
| Mooncakes 构建 | `success` | 注册表 API `build_status` |
| 注册表独立消费验证 | **通过**（`registry_install_verified: true`，10 组检查） | [`evidence/consumer-registry-0.2.4-20261119.json`](evidence/consumer-registry-0.2.4-20261119.json) |
| 发布 tag | `v0.2.0`–`v0.2.4` 均已推送；`v0.2.4` 指向当前 HEAD | `git tag --list "v0.2*"` 与 GitHub tags API |
| 推送状态 | 已推送；远程与本地指向同一提交（两条命令的输出应相同） | `git rev-parse HEAD` 与 `git ls-remote origin main` |

版本历史：0.1.2 为原型；0.2.0 本期实质新增；0.2.1 增加 7 个 JSON 操作；0.2.2 修正并列剪枝、top-k 压缩回退、重复样本，并加入 motif 排除半径与分层分折；0.2.3 重写 README 首屏、统一数字出处、新增两条证据命令（无接口变更）；0.2.4 修复六项缺陷、补齐库入口与 22 操作示例，并新增预算/确定性/覆盖三项检查。

## 代码规模（可复核口径）

统计命令见本节末。范围：仓库内 `*.mbt`，排除 `_build/` 与 `work/`。

| 口径 | 文件数 | 总行 | 空行 | 注释 | 有效代码 |
| --- | --- | --- | --- | --- | --- |
| 源码（排除 `*_wbtest.mbt`） | 27 | 5,681 | 167 | 411 | **5,103** |
| 测试（`*_wbtest.mbt`） | 29 | 5,114 | 103 | 151 | 4,860 |
| 合计 | 56 | 10,795 | 270 | 562 | 9,963 |

```text
python - <<'EOF'
import pathlib
fs=[p for p in pathlib.Path(".").rglob("*.mbt") if "_build" not in p.parts and "work" not in p.parts]
for label,g in (("src",[p for p in fs if "wbtest" not in p.name]),("test",[p for p in fs if "wbtest" in p.name])):
    lines=[l for p in g for l in p.read_text(encoding="utf-8").splitlines()]
    code=[l for l in lines if l.strip() and not l.strip().startswith("//")]
    print(label, len(g), len(lines), len(code))
EOF
```

## 自查命令

两条命令覆盖本文件的大部分结论，CI 每次都跑：

| 命令 | 检查什么 | 失败行为 |
| --- | --- | --- |
| `node scripts/evidence_report.mjs` | 19 项声明与本目录 `evidence/*.json` 逐项比对（用例数、误差、浏览器项数、注册表验证） | 列出不一致项，退出 1 |
| `node scripts/check_examples.mjs` | `examples/` 全部 27 个文件：24 个请求断言 `ok:true`、`operation` 匹配、两次运行逐字节一致；3 个数据文件按设计跳过 | 列出失败文件，退出 1 |
| `node scripts/api_coverage.mjs` | 22 个 JSON 操作每个都有可运行示例，且出现在 `docs/API.md`；示例不得引用未知操作 | 列出缺口，退出 1 |
| `node scripts/budget_check.mjs` | 所有接收预算的示例（当前 22 个）：预算=1 必须拒绝（`work_budget` 或 `cell_limit`），宽裕预算必须成功 | 列出失败项，退出 1 |
| `node scripts/determinism_check.mjs` | 12 个生成请求在同一进程内连续跑两次，输出必须逐字节相同（同时暴露跨调用残留状态） | 列出失败项，退出 1 |

```text
node scripts/evidence_report.mjs
node scripts/check_examples.mjs
node scripts/budget_check.mjs
node scripts/determinism_check.mjs
node scripts/api_coverage.mjs
```

## 测试矩阵

| 层 | 范围 | 结果 | 证据 |
| --- | --- | --- | --- |
| MoonBit（本机） | `wasm-gc` / `wasm` / `js` | **125 / 125**，三后端一致 | 本节命令 |
| MoonBit（远程） | Linux / macOS / Windows × 四目标 + `native` | 提交 `8e56c0f` 三系统全绿（[run 44321089456](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089456)）；同提交 Pages 部署 [44321089959](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089959) 成功 | Actions |
| Node / CLI | `tests/*.test.mjs` | **45 / 45** | 本节命令 |
| 浏览器工作台 | 本地 4194，系统 Chrome 158 | **24 / 24**，0 pageerror，0 外部请求 | [`evidence/browser-0.2.2-20261118.json`](evidence/browser-0.2.2-20261118.json) |
| 注册表消费 | 隔离工程，从 Mooncakes 安装 | 10 / 10，三目标通过 | [`evidence/consumer-registry-0.2.4-20261119.json`](evidence/consumer-registry-0.2.4-20261119.json) |

```text
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target wasm --deny-warn
moon test --target js --deny-warn
node --test tests/*.test.mjs
```

## 数值正确性证据

| 结论 | 用例量 | 证据文件 |
| --- | --- | --- |
| 与 tslearn 0.6.4 逐项对照 | 160 组硬 DTW / 80 组单步 DBA / 9 组聚类 / 100 组预处理 | `evidence/hard-reference.json`、`evidence/tslearn.json` |
| 小样例全路径穷举 | 240 组 | `evidence/validation-current.json` |
| 子序列定位独立枚举 | 256 组路径 + 120 组 tslearn | `evidence/subsequence-reference.json` |
| 两行 DP vs 完整矩阵 | 1,200 组 | `evidence/validation-current.json` |
| kNN 参考实现 | 24 组 | `evidence/knn-reference.json` |
| 真实传感器数据固定划分 | 16 训练 / 16 测试，4,608 个插值数值 + 64 个 DTW 距离 | `evidence/uci-model-holdout.json` |

`validation-current.json` 中的 240 / 256 / 1200 只出现在 `results[].stdout` 文本里，没有独立字段；引用时按文本核对，脚本改名会让它们失效。

## 已知缺口

1. **`github.com:443` 不稳定**：本机直连超时、代理返回 502；0.2.4 的 tag 改由 Git Data API 创建。仓库内容、CI 与 Pages 结果不受影响。
2. **本机未跑 `native`**：缺 MSVC，由远程 CI 覆盖；本文件不把远程结果写成本机结果。
3. **证据文件曾落后于结论**：0.2.2 发布后 `docs/evidence/` 仍只有 0.2.0 的消费记录（`verified:false`）。现每次发布都补一份 `consumer-registry-<版本>-<日期>.json`；0.2.4 的消费证据已于 2026-11-19 补齐并通过，旧文件保留作为历史，不代表当前版本。
4. **浏览器检查是本地页面**：24 项针对本地 `127.0.0.1:4194`；线上工作台最新公开证据仍是 0.2.0 部署时的 22 项，两者不互相替代。
5. **三系统注册表工作流未运行**：`Verify published package` 手动工作流仍为 0 次运行；本地 0.2.4 注册表消费验证已通过，但不能写成远程三系统已验证。
