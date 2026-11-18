///|
fn topk_univariate(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "top-k subsequence finds the planted interval first" {
  let query = topk_univariate([0.0, 1.0, 0.0])
  let target = topk_univariate([9.0, 9.0, 0.0, 1.0, 0.0, 9.0, 9.0])
  let result = subsequence_topk(query, target, 2, dtw_options()).unwrap()
  assert_true(result.matches.length() >= 1)
  let best = result.matches[0]
  assert_eq(best.start, 2)
  assert_eq(best.end, 4)
  assert_true((best.distance - 0.0).abs() <= 1.0e-9)
  for match_ in result.matches {
    assert_true(match_.end - match_.start + 1 >= 3)
  }
  assert_eq(result.visited_cells, 21)
  assert_true(result.work_units > 0)
}

///|
test "top-k subsequence returns both repeated zero-cost intervals" {
  let query = topk_univariate([0.0, 1.0, 0.0])
  let target = topk_univariate([0.0, 1.0, 0.0, 9.0, 0.0, 1.0, 0.0])
  let result = subsequence_topk(query, target, 2, dtw_options()).unwrap()
  assert_eq(result.matches.length(), 2)
  assert_true((result.matches[0].distance - 0.0).abs() <= 1.0e-9)
  assert_true((result.matches[1].distance - 0.0).abs() <= 1.0e-9)
  assert_eq(result.matches[0].start, 0)
  assert_eq(result.matches[0].end, 2)
  assert_eq(result.matches[1].start, 4)
  assert_eq(result.matches[1].end, 6)
}

///|
test "top-k subsequence validates k, window and target length" {
  let query = topk_univariate([0.0, 1.0, 0.0])
  let target = topk_univariate([0.0, 1.0, 0.0])
  assert_true(
    match subsequence_topk(query, target, 0, dtw_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match subsequence_topk(query, target, 17, dtw_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match subsequence_topk(query, target, 2, { ..dtw_options(), window: 0, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      subsequence_topk(
        topk_univariate([0.0, 1.0, 0.0, 1.0]),
        target,
        2,
        dtw_options(),
      ) {
      Err(_) => true
      Ok(_) => false
    },
  )
}
