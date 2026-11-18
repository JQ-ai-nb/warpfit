# 当前状态（单一事实源）

本文件是项目所有可量化结论的**唯一出处**。其他文档只引用结论与命令，不重复数字；改数字只改这里，并在同一提交内更新对应证据文件。

记录时间：2026-11-18（UTC+8）｜提交：`a319d66`｜工作树：干净

## 版本与发布

| 项 | 值 | 依据 |
| --- | --- | --- |
| 包名 | `JQ-ai-nb/warpfit` | `moon.mod` |
| 当前版本 | **0.2.2** | `moon.mod` / `package.json` |
| Mooncakes 构建 | `success` | 注册表 API `build_status` |
| 注册表独立消费验证 | **通过**（`registry_install_verified: true`，10 组检查） | [`evidence/consumer-registry-0.2.2-20261118.json`](evidence/consumer-registry-0.2.2-20261118.json) |
| 本地仓库写入证据 | 4 个提交未推送（凭据受限） | `git rev-list --count origin/main..HEAD` |

版本历史：0.1.2 为原型；0.2.0 本期实质新增；0.2.1 增加 7 个 JSON 操作；0.2.2 修正并列剪枝、top-k 压缩回退、重复样本，并加入 motif 排除半径与分层分折。

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
| `node scripts/check_examples.mjs` | `examples/` 全部 23 个文件：20 个请求断言 `ok:true`、`operation` 匹配、两次运行逐字节一致；3 个数据文件按设计跳过 | 列出失败文件，退出 1 |

```text
node scripts/evidence_report.mjs
node scripts/check_examples.mjs
```

## 测试矩阵

| 层 | 范围 | 结果 | 证据 |
| --- | --- | --- | --- |
| MoonBit（本机） | `wasm-gc` / `wasm` / `js` | **117 / 117**，三后端一致 | 本节命令 |
| MoonBit（远程） | Linux / macOS / Windows × 四目标 + `native` | 由 CI 覆盖；本机缺 MSVC | Actions |
| Node / CLI | `tests/*.test.mjs` | **43 / 43** | 本节命令 |
| 浏览器工作台 | 本地 4194，系统 Chrome 158 | **24 / 24**，0 pageerror，0 外部请求 | [`evidence/browser-0.2.2-20261118.json`](evidence/browser-0.2.2-20261118.json) |
| 注册表消费 | 隔离工程，从 Mooncakes 安装 | 10 / 10，三目标通过 | [`evidence/consumer-registry-0.2.2-20261118.json`](evidence/consumer-registry-0.2.2-20261118.json) |

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

1. **4 个提交未推送**：`git push` 目前被 `DWS-ai-nb` 凭据拒绝，远程 main 停在 `9c3a102`。CI 尚未验证这 4 个提交。
2. **本机未跑 `native`**：缺 MSVC，由远程 CI 覆盖；本文件不把远程结果写成本机结果。
3. **证据文件曾落后于结论**：0.2.2 发布后 `docs/evidence/` 仍只有 0.2.0 的消费记录（`verified:false`），本次已补 0.2.2 实测文件；旧文件保留作为历史，不代表当前版本。
4. **浏览器检查是本地页面**：24 项针对本地 `127.0.0.1:4194`，不构成对已部署站点的断言。
