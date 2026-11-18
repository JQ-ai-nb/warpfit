///|
fn robust_near(a : Double, b : Double) -> Unit raise {
  assert_true(a == a && b == b && (a - b).abs() <= 1.0e-6)
}

///|
fn robust_univariate(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "soft dtw stays finite at extreme smoothing values" {
  let x = robust_univariate([0.0, 1.0, 0.0])
  let y = robust_univariate([0.0, 0.0, 1.0])
  for gamma in [1.0e-6, 1.0, 10000.0] {
    let r = soft_dtw(x, y, gamma).unwrap()
    assert_true(r.value == r.value)
    for value in r.gradient_x {
      assert_true(value == value)
    }
    for value in r.gradient_y {
      assert_true(value == value)
    }
  }
}

///|
test "knn with k equal to training size keeps a deterministic tie" {
  let training : Array[LabeledSeries] = [
    { label: "a", series: robust_univariate([0.0]), },
    { label: "b", series: robust_univariate([0.0]), },
  ]
  let result = knn_classify(robust_univariate([0.0]), training, {
    ..knn_options(),
    k: 2,
  }).unwrap()
  assert_eq(result.label, "a")
  assert_eq(result.neighbors.length(), 2)
  assert_eq(result.votes.length(), 2)
  assert_eq(result.votes[0], 1)
  assert_eq(result.votes[1], 1)
  assert_true(result.work_units > 0)
}

///|
test "distance-only dtw matches the full path when the window covers all cells" {
  let x = robust_univariate([0.0, 0.7, 0.2, 1.0])
  let y = robust_univariate([0.1, 0.0, 0.9])
  let options = { ..dtw_options(), window: 512, }
  let measured = dtw_distance(x, y, options).unwrap()
  let path = dtw_path(x, y, options).unwrap()
  robust_near(measured.squared_cost, path.squared_cost)
  robust_near(measured.distance, path.distance)
  assert_eq(measured.visited_cells, path.visited_cells)
  assert_eq(measured.visited_cells, 12)
}

///|
test "resampling the largest raw input to the largest output keeps endpoints" {
  let values = Array::make(8192, 0.0)
  for i = 0; i < 8192; i = i + 1 {
    values[i] = i.to_double() / 8191.0 * 20000.0 - 10000.0
  }
  let source = { count: 8192, dimensions: 1, values, }
  let output = resample_linear(source, 512).unwrap()
  assert_eq(output.count, 512)
  robust_near(output.values[0], -10000.0)
  robust_near(output.values[511], 10000.0)
  for value in output.values {
    assert_true(value >= -10000.0 && value <= 10000.0)
  }
}
