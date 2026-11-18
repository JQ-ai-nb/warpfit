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
    /// Welford's online update. The naive sum-then-mean form left a 1-ulp
    /// residue on a constant column, so `constant: true` came with a
    /// standard deviation of 1.4e-17 instead of 0.
    let mut mean = 0.0
    let mut m2 = 0.0
    let mut seen = 0.0
    for i = 0; i < n; i = i + 1 {
      let value = series.values[i * d + k]
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
      seen += 1.0
      let delta = value - mean
      mean += delta / seen
      m2 += delta * (value - mean)
    }
    let mut variance = m2 / seen
    if minimum == maximum {
      // A column that never changes has no spread by definition; the guard
      // also keeps the reporting identity `constant => variance == 0` exact.
      variance = 0.0
      mean = minimum
    }
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
