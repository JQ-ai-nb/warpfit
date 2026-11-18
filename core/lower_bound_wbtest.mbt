///|
fn lb_univariate(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
fn lb_near(a : Double, b : Double) -> Unit raise {
  assert_true(a == a && b == b && (a - b).abs() <= 1.0e-9)
}

///|
test "pruned knn matches the exhaustive knn result" {
  let training : Array[LabeledSeries] = [
    { label: "a", series: lb_univariate([0.0, 1.0, 0.0]), },
    { label: "b", series: lb_univariate([0.0, 0.0, 1.0]), },
    { label: "a", series: lb_univariate([0.1, 0.9, 0.1]), },
    { label: "b", series: lb_univariate([0.1, 0.1, 0.9]), },
    { label: "a", series: lb_univariate([0.2, 1.1, 0.0]), },
    { label: "b", series: lb_univariate([0.0, 0.2, 1.0]), },
  ]
  let query = lb_univariate([0.0, 1.0, 0.0])
  let options = {
    ..knn_options(),
    k: 3,
    alignment: { ..dtw_options(), window: 1, },
  }
  let full = knn_classify(query, training, options).unwrap()
  let pruned = knn_classify_pruned(query, training, options).unwrap()
  assert_eq(pruned.label, full.label)
  assert_eq(pruned.votes, full.votes)
  assert_eq(pruned.neighbors.length(), full.neighbors.length())
  for index = 0; index < full.neighbors.length(); index = index + 1 {
    assert_eq(pruned.neighbors[index].label, full.neighbors[index].label)
    assert_eq(
      pruned.neighbors[index].train_index,
      full.neighbors[index].train_index,
    )
    lb_near(pruned.neighbors[index].distance, full.neighbors[index].distance)
  }
  assert_true(pruned.full_distance_calls <= training.length())
  assert_true(pruned.work_units > 0)
}

///|
test "lb keogh never exceeds the real dtw distance" {
  let query = lb_univariate([0.0, 1.0, 0.0])
  let candidate = lb_univariate([0.0, 0.0, 1.0])
  let (lower, upper) = query_envelope(query, 1)
  let bound = lb_keogh_prepared(lower, upper, candidate, [])
  let real = dtw_distance(query, candidate, { ..dtw_options(), window: 1, }).unwrap()
  assert_true(bound <= real.distance + 1.0e-9)
  let unequal = lb_keogh_prepared(
    lower,
    upper,
    lb_univariate([0.0, 0.0, 1.0, 0.0]),
    [],
  )
  assert_eq(unequal, 0.0)
}

///|
test "bounded dtw prunes below the threshold but keeps equal costs" {
  let x = lb_univariate([0.0, 1.0, 0.0])
  let y = lb_univariate([0.0, 0.0, 1.0])
  let options = { ..dtw_options(), window: 1, }
  let full = dtw_distance(x, y, options).unwrap()
  let pruned = dtw_distance_bounded(x, y, options, 0.0).unwrap()
  match pruned {
    None => ()
    Some(_) => assert_true(false)
  }
  let kept = dtw_distance_bounded(x, y, options, full.distance).unwrap()
  match kept {
    Some(value) => lb_near(value.distance, full.distance)
    None => assert_true(false)
  }
  assert_true(
    match dtw_distance_bounded(x, y, options, -1.0) {
      Err(_) => true
      Ok(_) => false
    },
  )
}

///|
test "pruned knn still works when lengths differ" {
  let training : Array[LabeledSeries] = [
    { label: "a", series: lb_univariate([0.0, 1.0, 0.0]), },
    { label: "b", series: lb_univariate([0.0, 0.0, 1.0, 0.0]), },
  ]
  let query = lb_univariate([0.0, 1.0])
  let options = {
    ..knn_options(),
    k: 1,
    alignment: { ..dtw_options(), window: 1, },
  }
  let full = knn_classify(query, training, options).unwrap()
  let pruned = knn_classify_pruned(query, training, options).unwrap()
  assert_eq(pruned.label, full.label)
  assert_eq(pruned.neighbors[0].train_index, full.neighbors[0].train_index)
}
