///|
pub(all) struct StandardizedSeries {
  series : Series
  means : Array[Double]
  /// Population standard deviations before normalization, per feature.
  standard_deviations : Array[Double]
  /// Features with deviation <= epsilon become zeros, not NaN or infinity.
  constant_features : Array[Bool]
}

///|
/// Resample on an equally spaced normalized sample-index axis using linear
/// interpolation. This does not interpret or preserve real timestamps.
/// A one-point output takes the first observation; a one-point input repeats.
pub fn resample_linear(
  series : Series,
  target_count : Int32,
) -> Result[Series, WarpError] {
  match validate_series(series) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  if target_count < 1 || target_count > 512 {
    return Err(failure("target_count", "target_count must be within 1..512"))
  }
  let output = Array::make(target_count * series.dimensions, 0.0)
  for i = 0; i < target_count; i = i + 1 {
    let position = if target_count == 1 || series.count == 1 {
      0.0
    } else {
      i.to_double() *
      (series.count - 1).to_double() /
      (target_count - 1).to_double()
    }
    let left = position.to_int()
    let right = if left + 1 < series.count { left + 1 } else { left }
    let fraction = position - left.to_double()
    for k = 0; k < series.dimensions; k = k + 1 {
      let a = series.values[left * series.dimensions + k]
      let b = series.values[right * series.dimensions + k]
      let interpolated = a + fraction * (b - a)
      output[i * series.dimensions + k] = if interpolated > 10000.0 {
        10000.0
      } else if interpolated < -10000.0 {
        -10000.0
      } else {
        interpolated
      }
    }
  }
  Ok({ count: target_count, dimensions: series.dimensions, values: output, })
}

///|
/// Per-series, per-feature z-normalization using population variance.
/// epsilon controls when a feature is treated as constant; it is not added to
/// the denominator. Returns original means and deviations for interpretation.
pub fn standardize(
  series : Series,
  epsilon : Double,
) -> Result[StandardizedSeries, WarpError] {
  match validate_series(series) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  if epsilon != epsilon || epsilon < 0.0 || epsilon > 10000.0 {
    return Err(
      failure("epsilon", "epsilon must be finite and within [0, 10000]"),
    )
  }
  let d = series.dimensions
  let means = Array::make(d, 0.0)
  let deviations = Array::make(d, 0.0)
  let constants = Array::make(d, false)
  let output = Array::make(series.values.length(), 0.0)
  for k = 0; k < d; k = k + 1 {
    let mut total = 0.0
    let mut minimum = series.values[k]
    let mut maximum = series.values[k]
    for i = 0; i < series.count; i = i + 1 {
      let value = series.values[i * d + k]
      total += value
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
    }
    let mean = total / series.count.to_double()
    let mut squared = 0.0
    for i = 0; i < series.count; i = i + 1 {
      let delta = series.values[i * d + k] - mean
      squared += delta * delta
    }
    let deviation = if minimum == maximum {
      0.0
    } else {
      (squared / series.count.to_double()).sqrt()
    }
    let is_constant = deviation <= epsilon
    means[k] = mean
    deviations[k] = deviation
    constants[k] = is_constant
    if !is_constant {
      for i = 0; i < series.count; i = i + 1 {
        output[i * d + k] = (series.values[i * d + k] - mean) / deviation
      }
    }
  }
  Ok({
    series: { count: series.count, dimensions: d, values: output, },
    means,
    standard_deviations: deviations,
    constant_features: constants,
  })
}
