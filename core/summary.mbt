///|
/// Per-feature descriptive statistics used by reports and preprocessing checks.
pub(all) struct FeatureSummary {
  minimum : Double
  maximum : Double
  mean : Double
  /// Population variance, matching `standardize`'s denominator.
  variance : Double
  standard_deviation : Double
  constant : Bool
}

///|
pub(all) struct SeriesSummary {
  count : Int32
  dimensions : Int32
  features : Array[FeatureSummary]
}

///|
/// Summarize a bounded raw series without mutating it. This is a reporting
/// utility; it does not decide whether a feature should be normalized.
pub fn summarize_series(series : Series) -> Result[SeriesSummary, WarpError] {
  match validate_raw_series(series) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let n = series.count
  let d = series.dimensions
  let features : Array[FeatureSummary] = []
  for k = 0; k < d; k = k + 1 {
    let mut minimum = series.values[k]
    let mut maximum = series.values[k]
    let mut total = 0.0
    for i = 0; i < n; i = i + 1 {
      let value = series.values[i * d + k]
      total += value
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
    }
    let mean = total / n.to_double()
    let mut squared = 0.0
    for i = 0; i < n; i = i + 1 {
      let delta = series.values[i * d + k] - mean
      squared += delta * delta
    }
    let variance = squared / n.to_double()
    features.push({
      minimum,
      maximum,
      mean,
      variance,
      standard_deviation: variance.sqrt(),
      constant: minimum == maximum,
    })
  }
  Ok({ count: n, dimensions: d, features, })
}

///|
/// Convenience range for one summarized feature. Kept separate from the bulk
/// summary so callers can format a single column without copying every stat.
pub fn feature_range(
  summary : SeriesSummary,
  feature : Int32,
) -> Result[Double, WarpError] {
  if feature < 0 || feature >= summary.features.length() {
    return Err(failure("feature_index", "feature index is out of range"))
  }
  let item = summary.features[feature]
  Ok(item.maximum - item.minimum)
}
