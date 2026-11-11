///|
test "raw series with different scales and lengths are prepared then clustered by shape" {
  let data = [
    univariate([2.0, 4.0, 6.0]),
    univariate([100.0, 200.0, 300.0, 400.0, 500.0]),
    univariate([6.0, 4.0, 2.0]),
    univariate([500.0, 400.0, 300.0, 200.0, 100.0]),
  ]
  let options = {
    preprocessing: { ..preprocess_options(), target_count: 5, },
    clustering: {
      ..cluster_options(),
      alignment: { ..dtw_options(), window: 0, },
    },
  }
  let result = prepare_and_cluster(data, [0, 2], options).unwrap()
  assert_eq(result.clustering.labels, [0, 0, 1, 1])
  near(result.clustering.inertia, 0.0)
  assert_eq(result.prepared[0].series.count, 5)
  near(result.prepared[0].means[0], 4.0)
  near(result.prepared[1].means[0], 300.0)
  assert_eq(result.prepared[0].constant_features, [false])
  near(data[0].values[0], 2.0)
}

///|
test "preparation can preserve lengths and skip standardization" {
  let input = univariate([2.0, 4.0])
  let prepared = prepare_series(input, {
    ..preprocess_options(),
    normalize: false,
  }).unwrap()
  assert_true(!prepared.normalized)
  assert_eq(prepared.series.values, [2.0, 4.0])
  assert_true(prepared.means.is_empty())
  prepared.series.values[0] = 9.0
  near(input.values[0], 2.0)
}

///|
test "pipeline rejects invalid seeds options and duplicate-normalized clusters" {
  let a = univariate([0.0, 1.0])
  let b = univariate([1.0, 0.0])
  assert_true(failed(prepare_and_cluster([a, b], [0, 0], pipeline_options())))
  assert_true(failed(prepare_and_cluster([a, b], [0, 2], pipeline_options())))
  assert_true(failed(prepare_and_cluster([a, b], [-1, 1], pipeline_options())))
  assert_true(failed(prepare_and_cluster([a, b], [], pipeline_options())))
  assert_true(
    failed(prepare_series(a, { ..preprocess_options(), target_count: 513, })),
  )
  assert_true(
    failed(
      prepare_series(a, {
        ..preprocess_options(),
        normalize: false,
        epsilon: -1.0,
      }),
    ),
  )
  match
    prepare_and_cluster(
      [univariate([1.0, 2.0]), univariate([2.0, 4.0])],
      [0, 1],
      pipeline_options(),
    ) {
    Err(e) => assert_eq(e.code, "empty_cluster")
    Ok(_) =>
      abort("identical standardized series should report an empty cluster")
  }
}
