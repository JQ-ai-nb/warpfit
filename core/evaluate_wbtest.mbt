///|
fn cv_series(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "cross-validation separates two well-separated classes" {
  let data : Array[Series] = [
    cv_series([0.0, 0.0, 0.0]),
    cv_series([0.0, 0.1, 0.0]),
    cv_series([5.0, 5.0, 5.0]),
    cv_series([5.0, 5.1, 5.0]),
  ]
  let labels = ["a", "a", "b", "b"]
  let result = cross_validate_knn(data, labels, {
    ..cross_validation_options(),
    k: 1,
    folds: 2,
  }).unwrap()
  assert_true((result.accuracy - 1.0).abs() <= 1.0e-12)
  assert_eq(result.predictions.length(), 4)
  assert_eq(result.labels.length(), 2)
  assert_eq(result.confusion.length(), 2)
  assert_eq(result.confusion[0][0], 2)
  assert_eq(result.confusion[0][1], 0)
  assert_eq(result.confusion[1][0], 0)
  assert_eq(result.confusion[1][1], 2)
  assert_eq(result.scores[0].precision, 1.0)
  assert_eq(result.scores[0].recall, 1.0)
  assert_eq(result.scores[0].f1, 1.0)
  assert_true(result.work_units > 0)
}

///|
test "cross-validation rejects invalid shapes and folds" {
  let data : Array[Series] = [
    cv_series([0.0]),
    cv_series([1.0]),
    cv_series([2.0]),
  ]
  assert_true(
    match cross_validate_knn(data, ["a", "a"], cross_validation_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      cross_validate_knn(data, ["a", "b", "a"], {
        ..cross_validation_options(),
        folds: 1,
      }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      cross_validate_knn(data, ["a", "b", "a"], {
        ..cross_validation_options(),
        folds: 2,
        k: 3,
      }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      cross_validate_knn(data, ["a", "b", "a"], {
        ..cross_validation_options(),
        max_work_units: 0,
      }) {
      Err(_) => true
      Ok(_) => false
    },
  )
}

///|
test "stratified folds do not depend on how the labels are ordered" {
  // Interleaving the classes used to put a single class in every training
  // fold, so a perfectly separable dataset scored 0.
  let data : Array[Series] = [
    cv_series([0.0, 0.0, 0.0]),
    cv_series([5.0, 5.0, 5.0]),
    cv_series([0.1, 0.0, 0.0]),
    cv_series([5.1, 5.0, 5.0]),
  ]
  let interleaved = ["a", "b", "a", "b"]
  let grouped = ["a", "a", "b", "b"]
  let options : CrossValidationOptions = {
    ..cross_validation_options(),
    k: 1,
    folds: 2,
  }
  let first = cross_validate_knn(data, interleaved, options).unwrap()
  assert_true((first.accuracy - 1.0).abs() <= 1.0e-12)
  let reordered : Array[Series] = [data[0], data[2], data[1], data[3]]
  let second = cross_validate_knn(reordered, grouped, options).unwrap()
  assert_true((second.accuracy - 1.0).abs() <= 1.0e-12)
}
