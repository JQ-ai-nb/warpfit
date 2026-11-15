///|
test "silhouette selection recovers three separated groups" {
  let data = [
    univariate([0.0]),
    univariate([0.1]),
    univariate([5.0]),
    univariate([5.1]),
    univariate([10.0]),
    univariate([10.1]),
  ]
  let selection = select_cluster_count(data, [2, 3], auto_k_options()).unwrap()
  assert_eq(selection.best_k, 3)
  assert_eq(selection.scores.length(), 2)
  assert_eq(selection.scores[0].k, 2)
  assert_eq(selection.scores[1].k, 3)
  // Cluster ids are seed-order dependent; only the partition is meaningful.
  let labels = selection.scores[1].labels
  assert_eq(labels[0], labels[1])
  assert_eq(labels[2], labels[3])
  assert_eq(labels[4], labels[5])
  assert_true(labels[0] != labels[2] && labels[2] != labels[4])
  assert_true(selection.scores[1].silhouette > 0.9)
  assert_true(selection.scores[1].silhouette > selection.scores[0].silhouette)
  assert_true(selection.work_units > 0)
}

///|
test "silhouette selection keeps two groups when only two exist" {
  let data = [
    univariate([0.0]),
    univariate([0.1]),
    univariate([0.2]),
    univariate([9.0]),
    univariate([9.1]),
    univariate([9.2]),
  ]
  let selection = select_cluster_count(data, [2, 3], auto_k_options()).unwrap()
  assert_eq(selection.best_k, 2)
  assert_eq(selection.scores[0].labels, [0, 0, 0, 1, 1, 1])
  assert_true(selection.scores[0].silhouette > 0.95)
}

///|
test "silhouette selection rejects non-increasing candidates" {
  let data = [univariate([0.0]), univariate([1.0]), univariate([9.0])]
  let error = match select_cluster_count(data, [3, 2], auto_k_options()) {
    Ok(_) => ""
    Err(error) => error.message
  }
  assert_true(error.contains("strictly increasing"))
}

///|
test "silhouette selection enforces the shared work budget" {
  let data = [univariate([0.0]), univariate([1.0]), univariate([9.0])]
  let error = match
    select_cluster_count(data, [2], { ..auto_k_options(), max_work_units: 2, }) {
    Ok(_) => ""
    Err(error) => error.message
  }
  assert_true(error.contains("budget"))
}
