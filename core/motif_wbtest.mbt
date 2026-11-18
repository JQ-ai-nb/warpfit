///|
fn motif_series(values : Array[Double]) -> Series {
  { count: values.length(), dimensions: 1, values, }
}

///|
test "motif discovery finds a repeated window first" {
  let series = motif_series([0.0, 1.0, 0.0, 9.0, 9.0, 0.0, 1.0, 0.0])
  let result = discover_motifs(series, 3, 1, motif_options()).unwrap()
  assert_eq(result.window, 3)
  assert_eq(result.pairs.length(), 1)
  assert_eq(result.pairs[0].first_start, 0)
  assert_eq(result.pairs[0].second_start, 5)
  assert_true((result.pairs[0].distance - 0.0).abs() <= 1.0e-9)
  assert_true(result.work_units > 0)
}

///|
test "motif discovery validates window, k and bounded window count" {
  let series = motif_series([0.0, 1.0, 0.0, 9.0, 9.0, 0.0, 1.0, 0.0])
  assert_true(
    match discover_motifs(series, 0, 1, motif_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match discover_motifs(series, 3, 17, motif_options()) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      discover_motifs(series, 2, 1, { ..motif_options(), max_windows: 2, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      discover_motifs(series, 3, 1, { ..motif_options(), max_work_units: 0, }) {
      Err(_) => true
      Ok(_) => false
    },
  )
}
