///|
fn series(values : Array[Double]) -> @warpfit.Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
/// This same executable is copied into a separate consumer module by the
/// package-validation script. It uses only public interfaces, not internals.
fn main raise {
  let x = series([0.0, 0.0, 1.0, 2.0])
  let y = series([0.0, 1.0, 2.0, 2.0])
  let alignment = { ..@warpfit.dtw_options(), window: 1, }
  let path = @warpfit.dtw_path(x, y, alignment).unwrap()
  assert_eq(path.distance, 0.0)
  assert_eq(path.path[0].x_index, 0)
  assert_eq(path.path[path.path.length() - 1].y_index, 3)
  let distance = @warpfit.dtw_distance(x, y, alignment).unwrap()
  assert_eq(distance.squared_cost, path.squared_cost)

  let average = @warpfit.dba_fit(
    series([10.0]),
    [series([0.0]), series([4.0])],
    { ..@warpfit.dba_options(), example_weights: [3.0, 1.0], },
  ).unwrap()
  assert_true((average.prototype.values[0] - 1.0).abs() < 1.0e-8)

  let options = {
    ..@warpfit.pipeline_options(),
    preprocessing: { ..@warpfit.preprocess_options(), normalize: false, },
  }
  let fit = @warpfit.train_cluster_model_auto(
    [series([0.0]), series([2.0]), series([9.0]), series([11.0])],
    2,
    0,
    options,
  ).unwrap()
  assert_eq(fit.seed_indices, [0, 3])
  assert_eq(fit.fitted.training.clustering.labels, [0, 0, 1, 1])
  let predicted = @warpfit.predict_clusters(
    fit.fitted.model,
    [series([1.0]), series([2.0])],
    10000,
  ).unwrap()
  assert_eq(predicted.labels, [0, 0])
  assert_true(predicted.distances[0].abs() < 1.0e-8)

  let segment = @warpfit.subsequence_dtw(
    series([0.0, 1.0, 0.0]),
    series([9.0, 9.0, 0.0, 1.0, 0.0, 9.0, 9.0]),
    @warpfit.dtw_options(),
  ).unwrap()
  assert_eq(segment.start, 2)
  assert_eq(segment.end, 4)
  assert_eq(segment.distance, 0.0)

  let prepared = @warpfit.prepare_series(series(Array::make(600, 2.0)), {
    ..@warpfit.preprocess_options(),
    target_count: 5,
  }).unwrap()
  assert_eq(prepared.series.count, 5)
  assert_eq(prepared.constant_features, [true])
  assert_true(prepared.series.values.iter().all(fn(value) { value == 0.0 }))

  let single_x = series([2.0])
  let single_y = series([5.0])
  let loss = @warpfit.divergence(single_x, single_y, 1.0).unwrap()
  assert_true((loss.value - 9.0).abs() < 1.0e-8)
  assert_true((loss.gradient_x[0] + 6.0).abs() < 1.0e-8)
  let learned = @warpfit.fit(single_x, [single_y], 0.5, 30).unwrap()
  assert_true((learned.prototype.values[0] - 5.0).abs() < 1.0e-6)
  let ranked = @warpfit.rank_candidates(
    single_x,
    [{ id: "exact", series: single_x, }, { id: "other", series: single_y, }],
    @warpfit.alignment_options(0.5),
    2,
    100,
  ).unwrap()
  assert_eq(ranked.matches[0].id, "exact")

  let nearest = @warpfit.knn_classify(
    series([0.1]),
    [
      { label: "a", series: series([0.0]), },
      { label: "a", series: series([0.2]), },
      { label: "b", series: series([9.0]), },
    ],
    { ..@warpfit.knn_options(), k: 3, },
  ).unwrap()
  assert_eq(nearest.label, "a")
  assert_eq(nearest.neighbors.length(), 3)
  assert_eq(nearest.votes, [2, 1])

  let selection = @warpfit.select_cluster_count(
    [
      series([0.0]),
      series([0.1]),
      series([5.0]),
      series([5.1]),
      series([10.0]),
      series([10.1]),
    ],
    [2, 3],
    @warpfit.auto_k_options(),
  ).unwrap()
  assert_eq(selection.best_k, 3)
  assert_eq(selection.scores.length(), 2)
  println(
    "warpfit_consumer_ok: dtw, distance_only, dba, cluster_model, subsequence, long_preprocess, soft_gradient, fit_rank, knn, select_k",
  )
}
