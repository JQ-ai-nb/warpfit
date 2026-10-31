///|
test "weighted single-sample fitting reaches its analytic reference" {
  let seed = univariate([10.0])
  let examples = [univariate([0.0]), univariate([4.0])]
  let options = { ..fitting_options(0.5, 20), example_weights: [3.0, 1.0], }
  let r = fit_with(seed, examples, options).unwrap()
  near(r.prototype.values[0], 1.0)
  near(r.gradient_norm, 0.0)
  assert_eq(r.stop, "gradient_tolerance")
  assert_eq(seed.values[0], 10.0)
  assert_eq(r.objective.length(), r.accepted_steps + 1)
}

///|
test "zero steps reports its real stopping condition" {
  let r = fit(univariate([2.0]), [univariate([0.0])], 1.0, 0).unwrap()
  assert_eq(r.stop, "max_steps")
  assert_eq(r.accepted_steps, 0)
  assert_eq(r.evaluations, 1)
  near(r.objective[0], 4.0)
}

///|
test "evaluation budget returns the last fully evaluated iterate" {
  let options = { ..fitting_options(1.0, 20), max_evaluations: 1, }
  let r = fit_with(univariate([2.0]), [univariate([0.0])], options).unwrap()
  assert_eq(r.stop, "evaluation_budget")
  assert_eq(r.accepted_steps, 0)
  near(r.prototype.values[0], 2.0)
  assert_eq(r.evaluations, 1)
}

///|
test "work budget is charged before the next matrix evaluation" {
  // One cached self cell, one prototype self cell and one cross cell.
  let options = { ..fitting_options(1.0, 20), max_work_units: 3, }
  let r = fit_with(univariate([2.0]), [univariate([0.0])], options).unwrap()
  assert_eq(r.stop, "work_budget")
  assert_eq(r.work_units, 3)
  assert_true(
    failed(
      fit_with(univariate([2.0]), [univariate([0.0])], {
        ..options,
        max_work_units: 2,
      }),
    ),
  )
}

///|
test "a stationary seed does not pretend to perform an update" {
  let x = univariate([0.0, 1.0])
  let r = fit(x, [x], 0.5, 20).unwrap()
  assert_eq(r.stop, "gradient_tolerance")
  assert_eq(r.accepted_steps, 0)
}

///|
test "relative improvement has a separate stopping label" {
  let options = { ..fitting_options(0.4, 20), improvement_tolerance: 1000.0, }
  let r = fit_with(univariate([2.0, -1.0]), [univariate([0.0, 1.0])], options).unwrap()
  assert_eq(r.stop, "improvement_tolerance")
  assert_eq(r.accepted_steps, 1)
}

///|
test "fit rejects invalid budgets weights and optimizer parameters" {
  let x = univariate([1.0])
  let options = fitting_options(0.5, 20)
  assert_true(failed(fit_with(x, [x], { ..options, learning_rate: 0.0, })))
  assert_true(failed(fit_with(x, [x], { ..options, example_weights: [0.0], })))
  assert_true(
    failed(fit_with(x, [x], { ..options, example_weights: [1.0, 1.0], })),
  )
  assert_true(failed(fit_with(x, [x], { ..options, max_evaluations: 0, })))
  assert_true(failed(fit_with(x, [x], { ..options, max_steps: 201, })))
}
