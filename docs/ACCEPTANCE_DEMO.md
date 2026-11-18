# WarpFit 验收演示路径

> 目标：让评审在 60 秒内看到项目可运行，在 5 分钟内复现核心结果。所有命令在仓库根目录执行；`dist/` 未入库，首次运行先构建。

## 60 秒在线路径

1. 打开 <https://jq-ai-nb.github.io/warpfit/>。
2. 选择 `align`：输出距离 0 与完整路径；把请求里的 `window` 改为 0，平方代价变为 2。
3. 选择 `knn`：输出标签 `rise`、投票 `[2,1]`。
4. 选择 `select-k`：输出 `best_k=3`、轮廓系数 `0.7379` / `0.9544`。
5. 页面无后端请求；数据在浏览器 Worker 内计算。

## 5 分钟本地路径

```text
moon check --target all --deny-warn
moon test --target wasm-gc --deny-warn
node scripts/build.mjs
node bin/warpfit.mjs examples/align.json
node bin/warpfit.mjs examples/dba.json
node bin/warpfit.mjs examples/knn.json
node bin/warpfit.mjs examples/select-k.json
node bin/warpfit.mjs examples/pipeline.json
```

预期：

| 命令 | 关键输出 |
|---|---|
| `align` | 距离 0；`window=0` 时平方代价 2 |
| `dba` | 目标约 0.166667 → 0.118056 |
| `knn` | 标签 `rise`，投票 `[2,1]` |
| `select-k` | `best_k=3`，轮廓系数 0.9544 |
| `pipeline` | 标签 `[0,0,1,1]` |

模型文件流程：

```text
node -e "require('node:fs').mkdirSync('work',{recursive:true})"
node bin/warpfit-model.mjs train examples/model_train.json work/cluster-model.json
node bin/warpfit-model.mjs predict work/cluster-model.json examples/model_predict_data.json
```

预期新数据标签 `[0,1,0]`。

## 证据

- CI（0.2.0 源码 `8195d88`）：<https://github.com/JQ-ai-nb/warpfit/actions/runs/44095202653>；main 最新 CI 见 <https://github.com/JQ-ai-nb/warpfit/actions>
- CI（0.2.0 源码 `8195d88`）：<https://github.com/JQ-ai-nb/warpfit/actions/runs/44095202653>
- Mooncakes：<https://mooncakes.io/docs/JQ-ai-nb/warpfit>（0.2.3）
- 注册表安装验证：`python scripts/registry_consumer.py --version 0.2.3` → `registry install verified: True`，记录见 [evidence/consumer-registry-0.2.3-20261118.json](evidence/consumer-registry-0.2.3-20261118.json)
- 验证记录：[VALIDATION.md](VALIDATION.md)；验收自查：[ACCEPTANCE.md](ACCEPTANCE.md)
- 演示入口：在线工作台（本节第 1 部分）与本地 5 分钟路径（第 2 部分）；仓库不再附带独立演示压缩包。

## 边界

- 示例均为合成数据或 UCI 固定划分实验，不代表业务准确率或生产效果。
- 聚类不保证全局最优；DBA 是局部迭代，初值会影响结果。
- 不支持 GPU、实时流、大规模索引、缺失值插值或自动确定原型长度。
