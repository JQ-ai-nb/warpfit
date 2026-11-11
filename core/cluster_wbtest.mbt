///|
test "DTW k-means really groups samples and updates centers by DBA" {
  let data = [
    univariate([0.0]),
    univariate([2.0]),
    univariate([9.0]),
    univariate([11.0]),
  ]
  let seeds = [univariate([0.0]), univariate([10.0])]
  let result = dtw_kmeans(data, seeds, cluster_options()).unwrap()
  assert_eq(result.labels, [0, 0, 1, 1])
  near(result.centers[0].values[0], 1.0)
  near(result.centers[1].values[0], 10.0)
  near(result.history[0], 1.5)
  near(result.inertia, 1.0)
  assert_eq(result.history.length(), result.iterations + 1)
  for i = 1; i < result.history.length(); i = i + 1 {
    assert_true(result.history[i] <= result.history[i - 1])
  }
  near(seeds[0].values[0], 0.0)
  near(data[1].values[0], 2.0)
}

///|
test "cluster handles unequal length inputs and a constrained alignment" {
  let data = [
    univariate([0.0, 0.0, 1.0]),
    univariate([0.0, 1.0]),
    univariate([8.0, 8.0, 9.0, 9.0]),
    univariate([8.0, 9.0]),
  ]
  let seeds = [univariate([0.0, 1.0]), univariate([8.0, 9.0])]
  let options = {
    ..cluster_options(),
    alignment: { ..dtw_options(), window: 1, },
  }
  let result = dtw_kmeans(data, seeds, options).unwrap()
  assert_eq(result.labels, [0, 0, 1, 1])
  near(result.inertia, 0.0)
  assert_eq(result.centers[0].count, 2)
  assert_eq(result.centers[1].count, 2)
}

///|
test "cluster returns only the last complete state when shared budget runs out" {
  let data = [
    univariate([0.0]),
    univariate([2.0]),
    univariate([9.0]),
    univariate([11.0]),
  ]
  let seeds = [univariate([0.0]), univariate([10.0])]
  let initial = dtw_kmeans(data, seeds, {
    ..cluster_options(),
    max_work_units: 8,
  }).unwrap()
  assert_eq(initial.stop, "work_budget")
  assert_eq(initial.work_units, 8)
  assert_eq(initial.iterations, 0)
  near(initial.inertia, 1.5)
  assert_eq(initial.labels, [0, 0, 1, 1])
  let partial_dba = dtw_kmeans(data, seeds, {
    ..cluster_options(),
    max_work_units: 12,
  }).unwrap()
  assert_eq(partial_dba.stop, "work_budget")
  assert_eq(partial_dba.work_units, 12)
  assert_eq(partial_dba.iterations, 0)
  near(partial_dba.centers[0].values[0], 0.0)
  near(partial_dba.inertia, 1.5)
  assert_true(
    failed(dtw_kmeans(data, seeds, { ..cluster_options(), max_work_units: 7, })),
  )
}

///|
test "empty cluster is an explicit error instead of fake results" {
  let data = [univariate([0.0]), univariate([0.0])]
  let seeds = [univariate([0.0]), univariate([0.0])]
  match dtw_kmeans(data, seeds, cluster_options()) {
    Err(e) => assert_eq(e.code, "empty_cluster")
    Ok(_) => abort("duplicate seeds must expose empty cluster")
  }
}

///|
test "cluster rejects invalid counts dimensions and options" {
  let x = univariate([1.0])
  let options = cluster_options()
  assert_true(failed(dtw_kmeans([], [x], options)))
  assert_true(failed(dtw_kmeans([x], [], options)))
  assert_true(failed(dtw_kmeans([x], [x, x], options)))
  assert_true(failed(dtw_kmeans([x], [x], { ..options, max_iterations: 51, })))
  assert_true(failed(dtw_kmeans([x], [x], { ..options, max_dba_steps: 0, })))
  assert_true(failed(dtw_kmeans([x], [x], { ..options, tolerance: -1.0, })))
  assert_true(
    failed(
      dtw_kmeans(
        [x],
        [{ count: 1, dimensions: 2, values: [1.0, 2.0], }],
        options,
      ),
    ),
  )
}
