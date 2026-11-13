///|
test "linear resampling preserves endpoints and interpolates each feature" {
  let input : Series = {
    count: 2,
    dimensions: 2,
    values: [0.0, 2.0, 4.0, 6.0],
  }
  let result = resample_linear(input, 5).unwrap()
  let expected = [0.0, 2.0, 1.0, 3.0, 2.0, 4.0, 3.0, 5.0, 4.0, 6.0]
  for i, value in expected {
    near(result.values[i], value)
  }
  assert_eq(result.count, 5)
  near(input.values[0], 0.0)
}

///|
test "resampling defines one-point and invalid inputs explicitly" {
  let one = univariate([7.0])
  let repeated = resample_linear(one, 4).unwrap()
  assert_eq(repeated.values, [7.0, 7.0, 7.0, 7.0])
  let first = resample_linear(univariate([3.0, 9.0]), 1).unwrap()
  near(first.values[0], 3.0)
  assert_true(failed(resample_linear(one, 0)))
  assert_true(failed(resample_linear(one, 513)))
  assert_true(failed(resample_linear(univariate([]), 3)))
}

///|
test "bounded raw inputs can be downsampled without relaxing DTW limits" {
  let values : Array[Double] = []
  for i = 0; i < 2880; i = i + 1 {
    values.push(i.to_double())
  }
  let raw = univariate(values)
  assert_true(failed(validate_series(raw)))
  assert_true(!failed(validate_raw_series(raw)))
  let sampled = resample_linear(raw, 100).unwrap()
  assert_eq(sampled.count, 100)
  near(sampled.values[0], 0.0)
  near(sampled.values[99], 2879.0)
  assert_true(failed(prepare_series(raw, preprocess_options())))
  let prepared = prepare_series(raw, {
    ..preprocess_options(),
    target_count: 100,
    normalize: false,
  }).unwrap()
  near(prepared.series.values[99], 2879.0)
  let oversized : Series = {
    count: 8193,
    dimensions: 1,
    values: Array::make(8193, 0.0),
  }
  assert_true(failed(resample_linear(oversized, 100)))
}

///|
test "z-normalization returns per-feature population statistics" {
  let input : Series = {
    count: 3,
    dimensions: 2,
    values: [1.0, 5.0, 2.0, 5.0, 3.0, 5.0],
  }
  let result = standardize(input, 1.0e-12).unwrap()
  near(result.means[0], 2.0)
  near(result.standard_deviations[0], (2.0 / 3.0).sqrt())
  near(result.means[1], 5.0)
  near(result.standard_deviations[1], 0.0)
  assert_eq(result.constant_features, [false, true])
  near(result.series.values[0], -1.5.sqrt())
  near(result.series.values[2], 0.0)
  near(result.series.values[4], 1.5.sqrt())
  near(result.series.values[1], 0.0)
  near(input.values[0], 1.0)
}

///|
test "constant threshold uses deviation and does not mutate the input" {
  let input = univariate([1.0, 1.2])
  let r = standardize(input, 0.11).unwrap()
  assert_eq(r.constant_features, [true])
  near(r.series.values[0], 0.0)
  near(r.standard_deviations[0], 0.1)
  let zero = standardize(univariate([2.0]), 0.0).unwrap()
  assert_eq(zero.constant_features, [true])
  let identical = standardize(univariate([0.1, 0.1, 0.1]), 0.0).unwrap()
  assert_eq(identical.constant_features, [true])
  near(identical.standard_deviations[0], 0.0)
  near(identical.series.values[0], 0.0)
  assert_true(failed(standardize(input, -1.0)))
  assert_true(failed(standardize(input, @double.infinity)))
}
