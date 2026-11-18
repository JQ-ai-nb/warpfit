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

///|
test "selected motifs land on distinct regions by default" {
  // A ramp makes every shifted window a near-copy; without an exclusion zone
  // the top pairs were (0,1), (1,2), (2,3) - three views of one region.
  let series = motif_series([
    0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0,
  ])
  let result = discover_motifs(series, 3, 3, motif_options()).unwrap()
  assert_true(result.pairs.length() >= 2)
  for left = 0; left < result.pairs.length(); left = left + 1 {
    for right = left + 1; right < result.pairs.length(); right = right + 1 {
      let a = result.pairs[left].first_start - result.pairs[right].first_start
      let b = result.pairs[left].first_start - result.pairs[right].second_start
      let gap_ok = if a < 0 { -a >= 3 } else { a >= 3 }
      let gap_ok2 = if b < 0 { -b >= 3 } else { b >= 3 }
      assert_true(gap_ok || gap_ok2)
    }
  }
}

///|
test "min_gap zero restores the overlapping behaviour" {
  let series = motif_series([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
  let loose = discover_motifs(
    series,
    3,
    3,
    { ..motif_options(), min_gap: 0 },
  ).unwrap()
  assert_eq(loose.pairs.length(), 3)
  // The first three best pairs are consecutive shifts of the same region.
  assert_eq(loose.pairs[0].first_start, 0)
  assert_eq(loose.pairs[0].second_start, 1)
}

///|
test "motif options reject an out-of-range gap" {
  let series = motif_series([0.0, 1.0, 0.0, 9.0, 9.0, 0.0, 1.0, 0.0])
  assert_true(
    match
      discover_motifs(series, 3, 1, { ..motif_options(), min_gap: -2 }) {
      Err(_) => true
      Ok(_) => false
    },
  )
  assert_true(
    match
      discover_motifs(series, 3, 1, { ..motif_options(), min_gap: 1025 }) {
      Err(_) => true
      Ok(_) => false
    },
  )
}
