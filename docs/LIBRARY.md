# 作为 MoonBit 库使用

JSON / CLI 只是这层核心的其中一个消费端。核心包 `JQ-ai-nb/warpfit/core` 可以直接被 MoonBit 项目引用，不经过 Node，也不需要 JSON。

运行 `moon run cmd/library_demo --target js --deny-warn` 可看到两个中心和新批次标签 `[0, 1]`。 [完整示例](../cmd/library_demo/main.mbt)

## 安装与引用

```text
moon add JQ-ai-nb/warpfit
```

```moonbit
import {
  "JQ-ai-nb/warpfit/core" @warpfit,
}
```

## 构造数据

`Series` 是行主序的多元序列：`count` 个时间步，每步 `dimensions` 个特征。不要手写 record，用构造函数：

```moonbit
let series = match @warpfit.Series::from_rows([[0.0], [1.0], [0.0]]) {
  Ok(value) => value
  Err(error) => {
    println(error.to_string())
    return
  }
}
println(series.count.to_string())     // 3
println(series.at(1, 0).to_string())  // 1
let rows = series.to_rows()  // [[0.0], [1.0], [0.0]]
```

`from_rows` 自 0.2.4 提供，接受 1 至 512 步、1 至 16 个特征，行长度须相同。形状错误返回 `series_shape`，非有限或超出 ±10000 的值返回 `series_value`。需要使用更长的原始序列时，可构造行主序 `Series` 后调用接收长输入的预处理接口。使用 `at` 时，调用方须确保行与特征下标分别在有效范围内。`to_rows` 返回独立数组。

## 典型路径：训练一次，预测多次

```moonbit
let options : @warpfit.PipelineOptions = {
  preprocessing: @warpfit.preprocess_options(),
  clustering: @warpfit.cluster_options(),
}
let fit = match @warpfit.train_cluster_model(data, [0, 2], options) {
  Ok(value) => value
  Err(error) => {
    println(error.to_string())
    return
  }
}
let prediction = match @warpfit.predict_clusters(fit.model, later, 20000000) {
  Ok(value) => value
  Err(error) => {
    println(error.to_string())
    return
  }
}
let labels = prediction.labels          // 每个新样本的簇编号
let distances = prediction.distances    // 到所选中心的 DTW 距离
```

模型同时保存预处理参数与对齐参数，所以 `later` 只需要是原始序列；不需要在调用方重复一遍重采样和标准化。

注意这条路径与 `prepare_and_cluster` 的区别：后者返回 `PipelineFit`，用于一次性分析，**不能**直接预测新样本。要预测就用 `train_cluster_model` / `train_cluster_model_auto`。

## 常用入口

| 任务 | 入口 | 说明 |
| --- | --- | --- |
| 对齐两条序列 | `dtw_distance(a, b, dtw_options())` | 返回距离；`dtw_path` 另给完整路径 |
| 学一个模板 | `dba_fit(seed, examples, dba_options())` | 目标单调下降，带停止原因 |
| 聚类（给定初始中心） | `dtw_kmeans(data, centers, cluster_options())` | 空簇会报错，不返回半个结果 |
| 聚类（自动初始化） | `train_cluster_model_auto(data, k, 0, options)` | 确定性最远点初始化 |
| 选簇数 | `select_cluster_count(data, candidates, auto_k_options())` | 只在给定候选内按轮廓系数选 |
| 分类 | `knn_classify(query, training, knn_options())` | 输出投票，不是概率 |
| 子序列定位 | `subsequence_dtw(query, target, dtw_options())` | 目标端点开放，返回最早结束的最优区间 |
| 统计 | `summarize_series(series)` | 总体方差、标准差、常量标记 |
| 预处理 | `prepare_series(series, preprocess_options())` | 默认逐维标准化，可设置 `target_count` 重采样 |

每个入口都返回 `Result[..., WarpError]`，不抛异常、不修改调用者传入的数组。

## 错误处理

`WarpError` 有两个字段：

```moonbit
match @warpfit.dtw_distance(a, b, options) {
  Ok(value) => println(value.distance.to_string())
  Err(error) => {
    // code 是稳定的，用来分支；message 是给人看的，可能随版本细化
    if error.code == "cell_limit" {
      println("请缩短输入或调整 max_cells")
    }
    println(error.to_string())   // "cell_limit: ..."
  }
}
```

常见的 `code`：`series_shape`（形状/长度）、`series_value`（取值越界）、`cell_limit`（矩阵超过 `max_cells`）、`work_budget`（工作量超过 `max_work_units`）、`empty_cluster`、`seed_distinct`、`model_version`。

## 预算

矩阵算法和迭代流程各有预算参数。以硬 DTW 与聚类为例：

- `max_cells`：单次矩阵的格点数上限，默认 262144。
- `max_work_units`：一次调用的逻辑工作量上限，默认 2000 万。

矩阵超限返回 `cell_limit`，初始工作超过额度时可能返回 `work_budget`。若迭代中耗尽预算，拟合或 DBA 等操作可能返回最近一次完整结果，调用方应检查 `stop`。`predict_clusters` 将预算作为直接参数。

## 与 JSON 层的关系

`api/` 把同一套核心包装成 22 个 JSON 操作，字段与错误码见 [API.md](API.md)。如果你在自己的服务里用 MoonBit，直接调核心即可；只有跨语言或跨进程时才需要 JSON 层。
