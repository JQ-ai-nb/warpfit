///|
test "knn votes among the nearest neighbours" {
  let training : Array[LabeledSeries] = [
    { label: "a", series: univariate([0.0]), },
    { label: "a", series: univariate([0.2]), },
    { label: "b", series: univariate([9.0]), },
    { label: "b", series: univariate([9.2]), },
  ]
  let options = { ..knn_options(), k: 3, }
  let result = knn_classify(univariate([0.1]), training, options).unwrap()
  assert_eq(result.label, "a")
  assert_eq(result.neighbors.length(), 3)
  assert_eq(result.votes, [2, 1])
  assert_eq(result.labels, ["a", "b"])
  near(result.neighbors[0].distance, 0.1)
  near(result.neighbors[2].distance, 8.9)
  assert_eq(result.work_units, 4)
}

///|
test "knn breaks an even vote by total distance" {
  let training : Array[LabeledSeries] = [
    { label: "far", series: univariate([4.0]), },
    { label: "near", series: univariate([0.5]), },
    { label: "near", series: univariate([0.6]), },
    { label: "far", series: univariate([7.0]), },
  ]
  let options = { ..knn_options(), k: 4, }
  let result = knn_classify(univariate([0.0]), training, options).unwrap()
  // Two votes each; "near" has the smaller distance sum.
  assert_eq(result.votes, [2, 2])
  assert_eq(result.label, "near")
}

///|
test "knn keeps input order when votes and distances tie" {
  let training : Array[LabeledSeries] = [
    { label: "first", series: univariate([1.0]), },
    { label: "second", series: univariate([-1.0]), },
  ]
  let options = { ..knn_options(), k: 2, }
  let result = knn_classify(univariate([0.0]), training, options).unwrap()
  assert_eq(result.label, "first")
}

///|
test "knn rejects an empty label and an oversized k" {
  let bad_label : Array[LabeledSeries] = [
    { label: "", series: univariate([0.0]), },
  ]
  let label_error = match
    knn_classify(univariate([0.0]), bad_label, { ..knn_options(), k: 1, }) {
    Ok(_) => ""
    Err(error) => error.message
  }
  assert_true(label_error.contains("labels must be nonempty"))
  let one : Array[LabeledSeries] = [{ label: "a", series: univariate([0.0]), }]
  let k_error = match
    knn_classify(univariate([0.0]), one, { ..knn_options(), k: 2, }) {
    Ok(_) => ""
    Err(error) => error.message
  }
  assert_true(k_error.contains("k must be"))
}

///|
test "knn enforces the shared work budget before searching" {
  let training : Array[LabeledSeries] = [
    { label: "a", series: univariate([0.0]), },
    { label: "b", series: univariate([1.0]), },
  ]
  let error = match
    knn_classify(univariate([0.0]), training, {
      ..knn_options(),
      k: 1,
      max_work_units: 1,
    }) {
    Ok(_) => ""
    Err(error) => error.message
  }
  assert_true(error.contains("budget"))
}
