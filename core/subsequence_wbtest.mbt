///|
test "subsequence DTW finds the matching interval instead of aligning both ends" {
  let q = univariate([0.0, 1.0, 0.0])
  let target = univariate([9.0, 9.0, 0.0, 1.0, 0.0, 9.0, 9.0])
  let result = subsequence_dtw(q, target, dtw_options()).unwrap()
  near(result.distance, 0.0)
  assert_eq(result.start, 2)
  assert_eq(result.end, 4)
  assert_eq(result.path.length(), 3)
  assert_eq(result.path[0].x_index, 0)
  assert_eq(result.path[0].y_index, 2)
  assert_eq(result.path[2].x_index, 2)
  assert_eq(result.path[2].y_index, 4)
  assert_true(dtw_path(q, target, dtw_options()).unwrap().distance > 0.0)
}

///|
test "subsequence DTW has deterministic endpoints and handles multiple features" {
  let tied = subsequence_dtw(
    univariate([1.0]),
    univariate([1.0, 1.0]),
    dtw_options(),
  ).unwrap()
  assert_eq(tied.start, 0)
  assert_eq(tied.end, 0)
  let query : Series = {
    count: 2,
    dimensions: 2,
    values: [1.0, 50.0, 2.0, 60.0],
  }
  let target : Series = {
    count: 4,
    dimensions: 2,
    values: [7.0, 7.0, 1.0, -9.0, 2.0, -9.0, 8.0, 8.0],
  }
  let result = subsequence_dtw(query, target, {
    ..dtw_options(),
    feature_weights: [1.0, 0.0],
  }).unwrap()
  assert_eq(result.start, 1)
  assert_eq(result.end, 2)
  near(result.distance, 0.0)
}

///|
test "subsequence validates lengths weights and unsupported window" {
  let query = univariate([1.0, 2.0, 3.0])
  let target = univariate([1.0, 2.0])
  assert_true(!failed(subsequence_dtw(query, target, dtw_options())))
  assert_true(
    failed(subsequence_dtw(query, target, { ..dtw_options(), window: 0, })),
  )
  assert_true(
    failed(subsequence_dtw(query, target, { ..dtw_options(), max_cells: 5, })),
  )
  assert_true(
    failed(
      subsequence_dtw(query, target, {
        ..dtw_options(),
        feature_weights: [0.0],
      }),
    ),
  )
  assert_true(failed(subsequence_dtw(query, univariate([]), dtw_options())))
}
