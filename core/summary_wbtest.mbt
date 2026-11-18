///|
test "summary reports per-feature mean variance and constants" {
  let series : Series = {
    count: 2,
    dimensions: 2,
    values: [1.0, 2.0, 3.0, 2.0],
  }
  let summary = summarize_series(series).unwrap()
  assert_eq(summary.count, 2)
  assert_eq(summary.dimensions, 2)
  assert_eq(summary.features.length(), 2)
  assert_eq(summary.features[0].mean, 2.0)
  assert_eq(summary.features[0].variance, 1.0)
  assert_eq(summary.features[0].standard_deviation, 1.0)
  assert_eq(summary.features[0].constant, false)
  assert_eq(summary.features[1].mean, 2.0)
  assert_eq(summary.features[1].variance, 0.0)
  assert_eq(summary.features[1].constant, true)
  assert_eq(feature_range(summary, 0).unwrap(), 2.0)
  assert_true(
    match feature_range(summary, 2) {
      Err(_) => true
      Ok(_) => false
    },
  )
}

///|
test "summary rejects empty and ragged series" {
  assert_true(
    match summarize_series({ count: 0, dimensions: 1, values: [], }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match summarize_series({ count: 2, dimensions: 2, values: [1.0, 2.0], }) {
      Err(_) => true
      Ok(_) => false
    },
  )
}

///|
test "a constant feature reports exactly zero spread" {
  // Naive sum-then-mean left a 1-ulp residue: 0.1*3/3 came back as
  // 0.10000000000000002 and the reported stddev was 1.4e-17 while
  // `constant` was true. A report that says "constant" must say zero.
  let series : Series = { count: 3, dimensions: 1, values: [0.1, 0.1, 0.1], }
  let feature = summarize_series(series).unwrap().features[0]
  assert_true(feature.constant)
  assert_eq(feature.variance, 0.0)
  assert_eq(feature.standard_deviation, 0.0)
  assert_true((feature.mean - 0.1).abs() <= 1.0e-15)
}
