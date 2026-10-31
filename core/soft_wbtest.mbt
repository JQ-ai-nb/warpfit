///|
fn near(a : Double, b : Double, epsilon~ : Double = 1.0e-6) -> Unit raise {
  assert_true(a == a && b == b && (a - b).abs() <= epsilon)
}

///|
fn[T] failed(r : Result[T, String]) -> Bool {
  match r {
    Err(_) => true
    Ok(_) => false
  }
}

///|
fn univariate(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "identical sequences have negative raw loss and zero corrected value" {
  let x = univariate([0.0, 1.0])
  let raw = soft_dtw(x, x, 1.0).unwrap()
  near(raw.value, -@math.ln(1.0 + 2.0 * @math.exp(-1.0)))
  let corrected = divergence(x, x, 1.0).unwrap()
  near(corrected.value, 0.0)
  for g in corrected.gradient_x {
    near(g, 0.0)
  }
}

///|
test "raw gradient agrees with independent finite differences" {
  let x = univariate([0.2, 1.4, -0.3])
  let y = univariate([0.0, 0.8])
  let r = soft_dtw(x, y, 0.6).unwrap()
  for k = 0; k < x.values.length(); k = k + 1 {
    let plus = x.values.copy()
    let minus = x.values.copy()
    plus[k] += 1.0e-5
    minus[k] -= 1.0e-5
    let a = soft_dtw({ ..x, values: plus, }, y, 0.6).unwrap().value
    let b = soft_dtw({ ..x, values: minus, }, y, 0.6).unwrap().value
    near(r.gradient_x[k], (a - b) / 2.0e-5)
  }
}

///|
test "corrected multivariate gradient includes both self derivatives" {
  let x = { count: 2, dimensions: 2, values: [0.2, -0.3, 1.5, 0.8], }
  let y = { count: 3, dimensions: 2, values: [0.0, -0.2, 0.6, 0.4, 1.2, 0.9], }
  let r = divergence(x, y, 0.8).unwrap()
  for k = 0; k < x.values.length(); k = k + 1 {
    let plus = x.values.copy()
    let minus = x.values.copy()
    plus[k] += 1.0e-5
    minus[k] -= 1.0e-5
    let a = divergence({ ..x, values: plus, }, y, 0.8).unwrap().value
    let b = divergence({ ..x, values: minus, }, y, 0.8).unwrap().value
    near(r.gradient_x[k], (a - b) / 2.0e-5)
  }
}

///|
test "alignment is visit occupancy, not row normalized attention" {
  let r = soft_dtw(univariate([0.0]), univariate([0.0, 0.0, 0.0]), 1.0).unwrap()
  near(r.alignment[0], 1.0)
  near(r.alignment[1], 1.0)
  near(r.alignment[2], 1.0)
}

///|
test "prototype fitting lowers its declared local objective" {
  let seed = univariate([2.0, -1.0, 2.0, 0.0])
  let examples = [univariate([0.0, 1.0, 0.0]), univariate([0.0, 0.8, 1.0, 0.0])]
  let r = fit(seed, examples, 0.4, 30).unwrap()
  assert_true(r.accepted_steps > 0)
  assert_true(r.objective.last().unwrap() < r.objective[0])
  for i = 1; i < r.objective.length(); i = i + 1 {
    assert_true(r.objective[i] <= r.objective[i - 1])
  }
}

///|
test "reject unsupported shape, empty data and invalid smoothing" {
  let x = univariate([0.0])
  assert_true(failed(soft_dtw(x, x, 0.0)))
  assert_true(failed(soft_dtw(x, x, @double.infinity)))
  assert_true(failed(soft_dtw(univariate([]), x, 1.0)))
  assert_true(
    failed(soft_dtw({ count: 2, dimensions: 1, values: [0.0], }, x, 1.0)),
  )
}
