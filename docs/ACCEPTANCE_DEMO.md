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
moon run cmd/library_demo --target js --deny-warn
node scripts/build.mjs
node bin/warpfit.mjs examples/align.json
node bin/warpfit.mjs examples/dba.json
node bin/warpfit.mjs examples/knn.json
node bin/warpfit.mjs examples/select-k.json
node bin/warpfit.mjs examples/pipeline.json
```

库示例将打印 `centers: 2` 和 `labels: [0, 1]`。其余命令的主要输出如下。

| 命令 | 关键输出 |
|---|---|
| `align` | 距离 0；`window=0` 时平方代价 2 |
| `dba` | 目标约 0.166667 → 0.118056 |
| `knn` | 标签 `rise`，投票 `[2,1]` |
| `select-k` | `best_k=3`，轮廓系数 0.9544 |
| `pipeline` | 标签 `[0,0,1,1]` |

以下命令保存并重新加载模型，输出路径需尚不存在。

```text
node -e "require('node:fs').mkdirSync('work',{recursive:true})"
node bin/warpfit-model.mjs train examples/model_train.json work/cluster-model.json
node bin/warpfit-model.mjs predict work/cluster-model.json examples/model_predict_data.json
```

预期新数据标签 `[0,1,0]`。

## 证据

- 从注册表独立安装已发布的 `0.2.4`，可运行 `python scripts/registry_consumer.py --version 0.2.4`。 [Mooncakes](https://mooncakes.io/docs/JQ-ai-nb/warpfit) · [安装记录](evidence/consumer-registry-0.2.4-20261119.json)
- 想离线演示时，可以运行 `python scripts/package_demo.py` 生成 `deliverables/` 下的本地 ZIP。解压后用 Node.js ≥22 运行。 [演示包说明](DEMO.md)
- 按版本与提交核对 CI、部署、浏览器与本机结果。 [状态与证据](STATUS.md) · [验收自查](ACCEPTANCE.md)

## 边界

- 示例均为合成数据或 UCI 固定划分实验，不代表业务准确率或生产效果。
- 聚类不保证全局最优；DBA 是局部迭代，初值会影响结果。
- 不支持 GPU、实时流、大规模索引、缺失值插值或自动确定原型长度。
