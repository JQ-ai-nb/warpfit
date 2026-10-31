///|
test "weighted alignment uses the declared ground cost and derivative" {
  let x = { count: 1, dimensions: 2, values: [2.0, 4.0], }
  let y = { count: 1, dimensions: 2, values: [1.0, 2.0], }
  let r = soft_dtw_with(x, y, {
    ..alignment_options(0.5),
    feature_weights: [3.0, 0.5],
  }).unwrap()
  near(r.value, 5.0)
  near(r.gradient_x[0], 6.0)
  near(r.gradient_x[1], 2.0)
  near(r.gradient_y[0], -6.0)
}

///|
test "feature weights may ignore a feature but cannot ignore all features" {
  let x = { count: 1, dimensions: 2, values: [2.0, 400.0], }
  let y = { count: 1, dimensions: 2, values: [1.0, -400.0], }
  let options = { ..alignment_options(1.0), feature_weights: [1.0, 0.0], }
  let r = soft_dtw_with(x, y, options).unwrap()
  near(r.value, 1.0)
  near(r.gradient_x[1], 0.0)
  assert_true(
    failed(soft_dtw_with(x, y, { ..options, feature_weights: [0.0, 0.0], })),
  )
  assert_true(
    failed(soft_dtw_with(x, y, { ..options, feature_weights: [1.0], })),
  )
}

///|
test "cell bounds apply independently to cross and self matrices" {
  let x = univariate([1.0, 2.0, 3.0])
  let y = univariate([2.0])
  let options = { ..alignment_options(1.0), max_cells: 3, }
  assert_true(!failed(soft_dtw_with(x, y, options)))
  match divergence_with(x, y, options) {
    Err(error) => assert_eq(error.code, "cell_limit")
    Ok(_) => abort("expected self matrix limit")
  }
}

///|
test "reject nonfinite data and invalid option bounds before allocation" {
  let x = univariate([1.0])
  assert_true(failed(soft_dtw(univariate([@double.infinity]), x, 1.0)))
  assert_true(
    failed(soft_dtw_with(x, x, { ..alignment_options(1.0), max_cells: 0, })),
  )
  assert_true(
    failed(
      soft_dtw_with(x, x, { ..alignment_options(1.0), feature_weights: [-1.0], }),
    ),
  )
}

///|
test "self correction reports its exact decomposition" {
  let x = univariate([0.2, 0.9, 0.1])
  let y = univariate([0.0, 1.0])
  let r = divergence(x, y, 0.8).unwrap()
  near(r.value, r.raw_cross - 0.5 * r.raw_self_x - 0.5 * r.raw_self_y)
  near(r.alignment[0], 1.0)
  near(r.alignment.last().unwrap(), 1.0)
}
