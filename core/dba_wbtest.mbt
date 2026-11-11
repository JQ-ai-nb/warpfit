///|
test "DBA reaches the analytic weighted one-point mean and preserves inputs" {
  let seed = univariate([10.0])
  let examples = [univariate([0.0]), univariate([4.0])]
  let result = dba_fit(seed, examples, {
    ..dba_options(),
    example_weights: [3.0, 1.0],
  }).unwrap()
  near(result.prototype.values[0], 1.0)
  near(result.objective[0], 84.0)
  near(result.objective[result.objective.length() - 1], 3.0)
  assert_eq(result.stop, "improvement_tolerance")
  assert_eq(result.objective.length(), result.accepted_steps + 1)
  near(seed.values[0], 10.0)
  near(examples[1].values[0], 4.0)
}

///|
test "DBA uses an actual hard DTW alignment for unequal lengths" {
  let seed = univariate([1.0, 2.0, 3.0, 4.0])
  let examples = [
    univariate([1.0, 2.0, 3.0, 4.0]),
    univariate([1.0, 2.0, 4.0, 5.0]),
  ]
  let result = dba_fit(seed, examples, dba_options()).unwrap()
  let expected = [1.0, 2.0, 3.5, 4.5]
  for i, value in expected {
    near(result.prototype.values[i], value)
  }
  for i = 1; i < result.objective.length(); i = i + 1 {
    assert_true(result.objective[i] <= result.objective[i - 1])
  }
  let unequal = dba_fit(
    seed,
    [seed, univariate([1.0, 2.0, 3.0, 4.0, 5.0])],
    dba_options(),
  ).unwrap()
  assert_eq(unequal.prototype.count, 4)
  assert_true(
    unequal.objective[unequal.objective.length() - 1] <= unequal.objective[0],
  )
}

///|
test "DBA retains zero-weight feature coordinates from the seed" {
  let seed : Series = { count: 1, dimensions: 2, values: [10.0, 99.0], }
  let example : Series = { count: 1, dimensions: 2, values: [0.0, -100.0], }
  let opts = {
    ..dba_options(),
    alignment: { ..dtw_options(), feature_weights: [1.0, 0.0], },
  }
  let result = dba_fit(seed, [example], opts).unwrap()
  near(result.prototype.values[0], 0.0)
  near(result.prototype.values[1], 99.0)
}

///|
test "DBA reports budget stops with only a fully evaluated initial state" {
  let seed = univariate([2.0])
  let options = { ..dba_options(), max_work_units: 1, }
  let result = dba_fit(seed, [univariate([0.0])], options).unwrap()
  assert_eq(result.stop, "work_budget")
  assert_eq(result.evaluations, 1)
  assert_eq(result.accepted_steps, 0)
  assert_eq(result.work_units, 1)
  near(result.prototype.values[0], 2.0)
  assert_true(failed(dba_fit(seed, [seed, seed], options)))
  let no_steps = dba_fit(seed, [seed], { ..options, max_steps: 0, }).unwrap()
  assert_eq(no_steps.stop, "max_steps")
  assert_eq(no_steps.objective.length(), 1)
}

///|
test "DBA rejects invalid parameters and invalid samples before calculation" {
  let x = univariate([1.0])
  assert_true(failed(dba_fit(x, [], dba_options())))
  assert_true(
    failed(dba_fit(x, [x], { ..dba_options(), example_weights: [0.0], })),
  )
  assert_true(failed(dba_fit(x, [x], { ..dba_options(), max_steps: 201, })))
  assert_true(failed(dba_fit(x, [x], { ..dba_options(), tolerance: -0.1, })))
  assert_true(
    failed(
      dba_fit(x, [x], {
        ..dba_options(),
        alignment: { ..dtw_options(), window: -2, },
      }),
    ),
  )
  assert_true(
    failed(
      dba_fit(
        x,
        [{ count: 1, dimensions: 2, values: [0.0, 1.0], }],
        dba_options(),
      ),
    ),
  )
}
