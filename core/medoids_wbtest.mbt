///|
fn medoid_series(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "k-medoids uses actual samples from both groups" {
  let data : Array[Series] = [
    medoid_series([0.0, 0.0, 0.0]),
    medoid_series([0.0, 0.1, 0.0]),
    medoid_series([5.0, 5.0, 5.0]),
    medoid_series([5.0, 5.1, 5.0]),
  ]
  let result = dtw_kmedoids(data, 2, 0, medoid_options()).unwrap()
  assert_eq(result.medoid_indices.length(), 2)
  assert_eq(result.labels.length(), 4)
  assert_true(result.cost >= 0.0)
  assert_true(result.work_units > 0)
  assert_true(result.history.length() >= 1)
  assert_true(result.labels[0] == result.labels[1])
  assert_true(result.labels[2] == result.labels[3])
  assert_true(result.labels[0] != result.labels[2])
}

///|
test "k-medoids allows every sample to be a medoid" {
  let data : Array[Series] = [medoid_series([0.0]), medoid_series([1.0])]
  let result = dtw_kmedoids(data, 2, 0, medoid_options()).unwrap()
  assert_eq(result.medoid_indices.length(), 2)
  assert_true((result.cost - 0.0).abs() <= 1.0e-12)
  assert_eq(result.labels[0], 0)
  assert_eq(result.labels[1], 1)
}

///|
test "k-medoids rejects invalid sizes and budgets" {
  let data : Array[Series] = [
    medoid_series([0.0]),
    medoid_series([1.0]),
    medoid_series([2.0]),
  ]
  assert_true(
    match dtw_kmedoids(data, 1, 0, medoid_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match dtw_kmedoids(data, 2, 9, medoid_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match dtw_kmedoids(data, 2, 0, { ..medoid_options(), max_work_units: 0, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
}

///|
test "identical samples seed distinct medoids instead of failing" {
  // A constant series has no distinguishable points. Refusing to cluster it
  // made `medoids` unusable on exactly the data where it is easiest to explain.
  let data : Array[Series] = [
    medoid_series([1.0]),
    medoid_series([1.0]),
    medoid_series([1.0]),
    medoid_series([1.0]),
  ]
  let result = dtw_kmedoids(data, 2, 0, medoid_options()).unwrap()
  assert_eq(result.medoid_indices.length(), 2)
  assert_true((result.cost - 0.0).abs() <= 1.0e-12)
  for label in result.labels {
    assert_true(label >= 0 && label < 2)
  }
}
