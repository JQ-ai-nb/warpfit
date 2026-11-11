///|
test "zero band on equal length is the weighted Euclidean diagonal" {
  let x : Series = { count: 2, dimensions: 2, values: [1.0, 2.0, 4.0, 9.0], }
  let y : Series = { count: 2, dimensions: 2, values: [0.0, 5.0, 2.0, 7.0], }
  let r = dtw_path(x, y, {
    ..dtw_options(),
    window: 0,
    feature_weights: [2.0, 0.5],
  }).unwrap()
  near(r.squared_cost, 16.5)
  near(r.distance, 16.5.sqrt())
  assert_eq(r.path.length(), 2)
  assert_eq(r.path[0].x_index, 0)
  assert_eq(r.path[1].y_index, 1)
  assert_eq(r.visited_cells, 2)
}

///|
test "band permits temporal shifts but a zero band forbids them" {
  let x = univariate([0.0, 0.0, 1.0, 2.0])
  let y = univariate([0.0, 1.0, 2.0, 2.0])
  let locked = dtw_path(x, y, { ..dtw_options(), window: 0, }).unwrap()
  let shifted = dtw_path(x, y, { ..dtw_options(), window: 1, }).unwrap()
  near(locked.squared_cost, 2.0)
  near(shifted.squared_cost, 0.0)
  assert_eq(shifted.path[0].x_index, 0)
  assert_eq(shifted.path[0].y_index, 0)
  let last = shifted.path[shifted.path.length() - 1]
  assert_eq(last.x_index, 3)
  assert_eq(last.y_index, 3)
  for k = 1; k < shifted.path.length(); k = k + 1 {
    let a = shifted.path[k - 1]
    let b = shifted.path[k]
    let dx = b.x_index - a.x_index
    let dy = b.y_index - a.y_index
    assert_true(dx >= 0 && dx <= 1 && dy >= 0 && dy <= 1 && dx + dy > 0)
    assert_true((b.x_index - b.y_index).abs() <= 1)
  }
}

///|
test "unequal length band retains both ends and extends the longer axis" {
  let x = univariate([0.0, 1.0, 2.0])
  let y = univariate([0.0, 0.0, 1.0, 2.0])
  let r = dtw_path(x, y, { ..dtw_options(), window: 0, }).unwrap()
  let reverse = dtw_path(y, x, { ..dtw_options(), window: 0, }).unwrap()
  near(r.distance, 0.0)
  near(reverse.distance, r.distance)
  let last = r.path[r.path.length() - 1]
  assert_eq(last.x_index, 2)
  assert_eq(last.y_index, 3)
  assert_eq(x.values.length(), 3)
  assert_eq(y.values[1], 0.0)
}

///|
test "hard DTW handles one point, ties and edge constraints deterministically" {
  let one = dtw_path(univariate([2.0]), univariate([5.0]), dtw_options()).unwrap()
  near(one.distance, 3.0)
  assert_eq(one.path.length(), 1)
  let tied = dtw_path(
    univariate([0.0, 0.0]),
    univariate([0.0, 0.0]),
    dtw_options(),
  ).unwrap()
  assert_eq(tied.path.length(), 2)
  assert_eq(tied.path[1].x_index, 1)
  assert_eq(tied.path[1].y_index, 1)
  let long = dtw_path(univariate([0.0]), univariate([0.0, 1.0, 2.0]), {
    ..dtw_options(),
    window: 0,
  }).unwrap()
  near(long.squared_cost, 5.0)
  assert_eq(long.path.length(), 3)
}

///|
test "hard DTW validates window, dimensions, weights and allocation budget" {
  let x = univariate([1.0, 2.0])
  assert_true(failed(dtw_path(x, x, { ..dtw_options(), window: -2, })))
  assert_true(failed(dtw_path(x, x, { ..dtw_options(), max_cells: 3, })))
  assert_true(
    failed(dtw_path(x, x, { ..dtw_options(), feature_weights: [0.0], })),
  )
  assert_true(
    failed(
      dtw_path(
        x,
        { count: 1, dimensions: 2, values: [1.0, 2.0], },
        dtw_options(),
      ),
    ),
  )
  assert_true(failed(dtw_path(univariate([]), x, dtw_options())))
}
