///|
fn outlier_series(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "outlier scores rank an isolated sample first" {
  let data : Array[Series] = [
    outlier_series([0.0, 0.0, 0.0]),
    outlier_series([0.0, 0.1, 0.0]),
    outlier_series([9.0, 9.0, 9.0]),
  ]
  let result = dtw_outlier_scores(data, outlier_options()).unwrap()
  assert_eq(result.scores.length(), 3)
  assert_true(result.scores[2].score > result.scores[0].score)
  assert_true(result.scores[2].score > result.scores[1].score)
  assert_eq(result.scores[2].neighbor_indices.length(), 1)
  assert_true(result.work_units > 0)
}

///|
test "outlier scores reject invalid k and budgets" {
  let data : Array[Series] = [
    outlier_series([0.0]),
    outlier_series([1.0]),
    outlier_series([2.0]),
  ]
  assert_true(
    match dtw_outlier_scores(data, { ..outlier_options(), k: 0, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match dtw_outlier_scores(data, { ..outlier_options(), k: 3, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      dtw_outlier_scores(data, { ..outlier_options(), max_work_units: 0, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
}
