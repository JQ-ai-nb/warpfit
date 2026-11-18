///|
/// Row-major multivariate observations. All public calculations validate shape
/// and finite input bounds before allocation. Formula sources are documented.
pub(all) struct Series {
  count : Int32
  dimensions : Int32
  values : Array[Double]
}

///|
/// Build a series from rows of equal length, validating shape and bounds the
/// same way every public entry point does. Without this, a caller had to write
/// the row-major record by hand and guess that `count × dimensions` must equal
/// `values.length()`.
pub fn Series::from_rows(
  rows : Array[Array[Double]],
) -> Result[Series, WarpError] {
  if rows.is_empty() {
    return Err(failure("series_shape", "series must not be empty"))
  }
  let dimensions = rows[0].length()
  if dimensions == 0 {
    return Err(
      failure("series_shape", "each row must contain at least one feature"),
    )
  }
  let values : Array[Double] = []
  for row in rows {
    if row.length() != dimensions {
      return Err(
        failure("series_shape", "all rows must have the same feature count"),
      )
    }
    for value in row {
      values.push(value)
    }
  }
  let series : Series = { count: rows.length(), dimensions, values, }
  match validate_series(series) {
    Ok(_) => Ok(series)
    Err(error) => Err(error)
  }
}

///|
/// Rows in the same layout `from_rows` accepts. The returned arrays are fresh;
/// mutating them cannot change the series.
pub fn Series::to_rows(self : Series) -> Array[Array[Double]] {
  let rows : Array[Array[Double]] = []
  for i = 0; i < self.count; i = i + 1 {
    let row : Array[Double] = []
    for k = 0; k < self.dimensions; k = k + 1 {
      row.push(self.values[i * self.dimensions + k])
    }
    rows.push(row)
  }
  rows
}

///|
/// Value of one feature at one step. Bounds are not checked; the index follows
/// the same convention as the underlying array, so an out-of-range read fails
/// the same way it would there.
pub fn Series::at(self : Series, index : Int32, feature : Int32) -> Double {
  self.values[index * self.dimensions + feature]
}

///|
pub(all) struct Evaluation {
  value : Double
  gradient_x : Array[Double]
  gradient_y : Array[Double]
  alignment : Array[Double]
}

///|
pub(all) struct Divergence {
  value : Double
  gradient_x : Array[Double]
  gradient_y : Array[Double]
  raw_cross : Double
  raw_self_x : Double
  raw_self_y : Double
  /// Cross-series visit occupancy, not a row-normalized probability matrix.
  alignment : Array[Double]
}

///|
fn predecessor_weights(
  a : Double,
  b : Double,
  c : Double,
  gamma : Double,
) -> (Double, Double, Double, Double) {
  let mut smallest = a
  if b < smallest {
    smallest = b
  }
  if c < smallest {
    smallest = c
  }
  let wa = @math.exp((smallest - a) / gamma)
  let wb = @math.exp((smallest - b) / gamma)
  let wc = @math.exp((smallest - c) / gamma)
  let z = wa + wb + wc
  (smallest - gamma * @math.ln(z), wa / z, wb / z, wc / z)
}

///|
pub fn soft_dtw(
  x : Series,
  y : Series,
  gamma : Double,
) -> Result[Evaluation, WarpError] {
  soft_dtw_with(x, y, alignment_options(gamma))
}

///|
pub fn soft_dtw_with(
  x : Series,
  y : Series,
  options : AlignOptions,
) -> Result[Evaluation, WarpError] {
  match validate_pair(x, y, options) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let gamma = options.gamma
  let n = x.count
  let m = y.count
  let d = x.dimensions
  let stride = m + 1
  let r = Array::make((n + 1) * stride, @double.infinity)
  r[0] = 0.0
  for i = 1; i <= n; i = i + 1 {
    for j = 1; j <= m; j = j + 1 {
      let mut local_cost = 0.0
      for k = 0; k < d; k = k + 1 {
        let delta = x.values[(i - 1) * d + k] - y.values[(j - 1) * d + k]
        local_cost = local_cost + feature_weight(options, k) * delta * delta
      }
      let (v, _, _, _) = predecessor_weights(
        r[(i - 1) * stride + j],
        r[i * stride + j - 1],
        r[(i - 1) * stride + j - 1],
        gamma,
      )
      r[i * stride + j] = local_cost + v
    }
  }
  // Reverse differentiation of the stable forward recurrence. This is not
  // the paper's padded reverse recurrence, avoiding infinity subtraction.
  let adjoint = Array::make((n + 1) * stride, 0.0)
  adjoint[n * stride + m] = 1.0
  let alignment = Array::make(n * m, 0.0)
  let gx = Array::make(n * d, 0.0)
  let gy = Array::make(m * d, 0.0)
  for i = n; i >= 1; i = i - 1 {
    for j = m; j >= 1; j = j - 1 {
      let a = adjoint[i * stride + j]
      alignment[(i - 1) * m + j - 1] = a
      let (_, wa, wb, wc) = predecessor_weights(
        r[(i - 1) * stride + j],
        r[i * stride + j - 1],
        r[(i - 1) * stride + j - 1],
        gamma,
      )
      adjoint[(i - 1) * stride + j] += a * wa
      adjoint[i * stride + j - 1] += a * wb
      adjoint[(i - 1) * stride + j - 1] += a * wc
      for k = 0; k < d; k = k + 1 {
        let xi = (i - 1) * d + k
        let yj = (j - 1) * d + k
        let grad = 2.0 *
          a *
          feature_weight(options, k) *
          (x.values[xi] - y.values[yj])
        gx[xi] += grad
        gy[yj] -= grad
      }
    }
  }
  Ok({ value: r[n * stride + m], gradient_x: gx, gradient_y: gy, alignment, })
}

///|
pub fn divergence(
  x : Series,
  y : Series,
  gamma : Double,
) -> Result[Divergence, WarpError] {
  divergence_with(x, y, alignment_options(gamma))
}

///|
pub fn divergence_with(
  x : Series,
  y : Series,
  options : AlignOptions,
) -> Result[Divergence, WarpError] {
  let xy = match soft_dtw_with(x, y, options) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let xx = match soft_dtw_with(x, x, options) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let yy = match soft_dtw_with(y, y, options) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let gx = Array::make(x.values.length(), 0.0)
  let gy = Array::make(y.values.length(), 0.0)
  for k = 0; k < gx.length(); k = k + 1 {
    gx[k] = xy.gradient_x[k] - 0.5 * (xx.gradient_x[k] + xx.gradient_y[k])
  }
  for k = 0; k < gy.length(); k = k + 1 {
    gy[k] = xy.gradient_y[k] - 0.5 * (yy.gradient_x[k] + yy.gradient_y[k])
  }
  Ok({
    value: xy.value - 0.5 * xx.value - 0.5 * yy.value,
    gradient_x: gx,
    gradient_y: gy,
    raw_cross: xy.value,
    raw_self_x: xx.value,
    raw_self_y: yy.value,
    alignment: xy.alignment,
  })
}
