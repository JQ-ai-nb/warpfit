///|
test "distance-only DTW matches full paths across unequal lengths and windows" {
  for n = 1; n <= 9; n = n + 1 {
    for m = 1; m <= 9; m = m + 1 {
      let x : Array[Double] = []
      let y : Array[Double] = []
      for i = 0; i < n; i = i + 1 {
        x.push(((i * 3 + n) % 7).to_double())
      }
      for j = 0; j < m; j = j + 1 {
        y.push(((j * 5 + m) % 7).to_double())
      }
      for radius = -1; radius <= 3; radius = radius + 1 {
        let options = { ..dtw_options(), window: radius, }
        let path = dtw_path(univariate(x), univariate(y), options).unwrap()
        let distance = dtw_distance(univariate(x), univariate(y), options).unwrap()
        near(distance.squared_cost, path.squared_cost)
        assert_eq(distance.visited_cells, path.visited_cells)
      }
    }
  }
}
