///|
test "series round-trips through rows and exposes one value" {
  let rows : Array[Array[Double]] = [[0.0, 1.0], [2.0, 3.0]]
  let series = Series::from_rows(rows).unwrap()
  assert_eq(series.count, 2)
  assert_eq(series.dimensions, 2)
  assert_eq(series.at(0, 1), 1.0)
  assert_eq(series.at(1, 0), 2.0)
  let back = series.to_rows()
  assert_eq(back.length(), 2)
  assert_eq(back[0][0], 0.0)
  assert_eq(back[0][1], 1.0)
  assert_eq(back[1][0], 2.0)
  assert_eq(back[1][1], 3.0)
}

///|
test "from_rows rejects ragged and empty input with a stable code" {
  let ragged : Array[Array[Double]] = [[0.0], [1.0, 2.0]]
  let error = match Series::from_rows(ragged) {
    Err(error) => error
    Ok(_) => abort("ragged rows must be rejected")
  }
  assert_eq(error.code, "series_shape")
  assert_true(error.to_string().contains("same feature count"))

  let empty : Array[Array[Double]] = []
  let empty_error = match Series::from_rows(empty) {
    Err(error) => error
    Ok(_) => abort("empty input must be rejected")
  }
  assert_eq(empty_error.code, "series_shape")
}

///|
test "an error prints its code and message together" {
  let error : WarpError = { code: "k", message: "k must be within 1..8", }
  assert_eq(error.to_string(), "k: k must be within 1..8")
}
