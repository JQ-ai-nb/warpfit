# 验收差距复核（2026-11-19）

对照材料：报名初审通过邮件（要求「保持项目仓库的提交记录、README、许可证和使用说明清晰完整」，最终验收按**项目完成度、代码质量、开源合规性、与 MoonBit 生态的相关性**评估）；赛事官网的六条验收标准与四维度评分口径（映射见 [ACCEPTANCE.md](ACCEPTANCE.md)）。

结论：**工程侧可闭环的差距已在本次复核中全部闭环；剩下的是需要参赛者本人或组委会确认的事项，以及一项许可证版权归属确认。**

---

## 一、已闭环（本轮实际动作）

| 维度 | 复核结果 | 证据 / 动作 |
| --- | --- | --- |
| 提交记录 | 公开 main 与本地同指 `8e56c0f`，94 个提交，作者单一（蒋琦 / JQ-ai-nb），待推 0 | `git rev-list --count HEAD`、GitHub commits API、`scripts/evidence_report.mjs` |
| 远程 CI | 当前 main 三系统 × Wasm / Wasm-GC / JS / native 全绿 | [CI run 44321089456](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089456) |
| 工作台部署 | 同提交 Pages 部署成功 | [run 44321089959](https://github.com/JQ-ai-nb/warpfit/actions/runs/44321089959) |
| 本地测试 | `moon fmt --check`、`moon check --target all --deny-warn`、Wasm / Wasm-GC / JS 各 **125/125**、Node **45/45** | 本机全量复跑 |
| 交付检查 | 示例 **24/24**、预算 **22/22**、确定性 **12/12**、API 覆盖 **22/22**、证据一致性 **19/19** | `npm run check` |
| Mooncakes | 页面显示 **0.2.4** / Apache-2.0；上一轮发布记录为 build success | <https://mooncakes.io/docs/JQ-ai-nb/warpfit> |
| 注册表消费 | 0.2.4 独立工程安装验证 **通过**，10/10，wasm / wasm-gc / js 三目标 | [`consumer-registry-0.2.4-20261119.json`](evidence/consumer-registry-0.2.4-20261119.json) |
| 版本 tag | `v0.2.4` 已指向当前 HEAD；因本机 `github.com:443` 不稳定，经 Git Data API 创建远程 ref | GitHub tags API |
| 仓库描述 | GitHub repo description 从 0.1.x 旧定位更新为当前 22 操作 / 工作台 / 0.2.4 | GitHub repo API |
| 文档口径 | `docs/STATUS.md`、README、ACCEPTANCE、ACCEPTANCE_DEMO、DEMO、ECOSYSTEM_DELTA、API、VALIDATION 统一到 0.2.4；数字只在 STATUS 维护 | 本轮文档一致性改动 |

本轮凭据只在本机内存中用于推送 tag、更新仓库描述和文档提交，未写入仓库、交接包或任何文件。

---

## 二、仍需处理（按优先级）

### 1. 许可证版权归属需本人确认（开源合规）

`LICENSE` 的 Apache-2.0 附录写的是 `Copyright 2025 International Digital Economy Academy`，看起来是 MoonBit 模板遗留，与本项目维护者（蒋琦 / JQ-ai-nb）不一致。**这是唯一可能影响开源合规的实质问题。**

建议：确认版权归属后，把附录改为项目实际版权声明，并视情况新增 `NOTICE` 文件。因为涉及法律归属，本轮未擅自改动。

### 2. 申报材料版本措辞（本人处理）

申报书正文写的是 **0.2.0**，当前实际版本为 **0.2.4**。仓库已能自洽，但报名材料不在仓库内；是否同步更新申报书，需按报名表要求由参赛者决定。

### 3. 十一月验收截止日（组委会确认）

赛事官网写「本期赛程 · 11 月赛季 · 截止日期以官方通知为准」。初审通过邮件未给出具体日期。需以组委会通知或群公告为准，仓库侧无法推定。

### 4. 线上工作台的当前版本浏览器证据

现有浏览器证据是：本地 `127.0.0.1:4194` **24/24**（0.2.2 证据），线上公开 **22/22**（0.2.0 部署时证据）。当前 0.2.4 的线上页面尚未补一份公开浏览器检查记录。若评审看线上工作台，建议补 `browser-public-0.2.4-<date>.json`。

### 5. 三系统注册表手动工作流

`Verify published package` 工作流自建立以来运行次数为 0。本地 0.2.4 注册表消费验证已通过，但不能写成「三系统远程已验证」。需要时用 workflow_dispatch 输入 `0.2.4` 触发。

### 6. 历史文档的旧时态

`docs/NOVEMBER.md`、`docs/SCENARIOS.md`、`docs/VALIDATION.md` 的历史段落仍含 0.2.0 / 0.2.3 与 82 / 110 / 113 / 117 等旧数字。`VALIDATION.md` 顶部已加当前版本复核段并声明下方为历史；其余文档保留为历史记录，**当前数字一律以 [STATUS.md](STATUS.md) 为准**，不必删除历史。

---

## 三、最终验收自查命令

```text
git status --short
git rev-parse HEAD
git ls-remote origin refs/heads/main

moon fmt --check
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target wasm --deny-warn
moon test --target js --deny-warn
node --test tests/*.test.mjs
npm run check

python scripts/registry_consumer.py --version 0.2.4
```

通过标准：本地命令全绿、远程 main 与本地一致、CI / Pages 为 success、Mooncakes 0.2.4、注册表验证 `registry_install_verified: True`、19 项声明与证据一致。
