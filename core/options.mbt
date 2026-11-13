///|
/// Stable error code for applications; messages contain no input data.
pub(all) struct WarpError {
  code : String
  message : String
}

///|
fn failure(code : String, message : String) -> WarpError {
  { code, message, }
}

///|
pub(all) struct AlignOptions {
  gamma : Double
  /// Empty means equal weights. Otherwise one nonnegative weight per feature.
  feature_weights : Array[Double]
  /// Upper bound on each dynamic-programming matrix's non-padding cells.
  max_cells : Int32
}

///|
pub fn alignment_options(gamma : Double) -> AlignOptions {
  { gamma, feature_weights: [], max_cells: 262144, }
}

///|
fn validate_series_limit(
  s : Series,
  max_samples : Int32,
) -> Result[Unit, WarpError] {
  if s.count < 1 ||
    s.count > max_samples ||
    s.dimensions < 1 ||
    s.dimensions > 16 {
    return Err(
      failure(
        "series_shape",
        if max_samples == 512 {
          "expected 1..512 samples and 1..16 features"
        } else {
          "expected 1..8192 raw samples and 1..16 features"
        },
      ),
    )
  }
  if s.values.length() != s.count * s.dimensions {
    return Err(
      failure("series_shape", "flat value count does not match declared shape"),
    )
  }
  for value in s.values {
    if value != value || value < -10000.0 || value > 10000.0 {
      return Err(
        failure(
          "series_value", "values must be finite and within [-10000, 10000]",
        ),
      )
    }
  }
  Ok(())
}

///|
/// Validate an input that is ready for DTW, Soft-DTW or clustering.
pub fn validate_series(s : Series) -> Result[Unit, WarpError] {
  validate_series_limit(s, 512)
}

///|
/// Validate bounded raw input for preprocessing or a subsequence target.
/// Ordinary DTW, Soft-DTW and clustering still require validate_series.
pub fn validate_raw_series(s : Series) -> Result[Unit, WarpError] {
  validate_series_limit(s, 8192)
}

///|
fn validate_pair(
  x : Series,
  y : Series,
  options : AlignOptions,
) -> Result[Unit, WarpError] {
  match validate_series(x) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  match validate_series(y) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  validate_pair_options(x, y, options)
}

///|
fn validate_pair_options(
  x : Series,
  y : Series,
  options : AlignOptions,
) -> Result[Unit, WarpError] {
  if x.dimensions != y.dimensions {
    return Err(
      failure(
        "feature_mismatch", "both series must have the same feature dimension",
      ),
    )
  }
  if options.gamma != options.gamma ||
    options.gamma <= 0.0 ||
    options.gamma > 10000.0 {
    return Err(failure("gamma", "gamma must be finite and in (0, 10000]"))
  }
  if options.max_cells < 1 || options.max_cells > 262144 {
    return Err(failure("cell_limit", "max_cells must be within 1..262144"))
  }
  if x.count * y.count > options.max_cells {
    return Err(failure("cell_limit", "the requested matrix exceeds max_cells"))
  }
  if !options.feature_weights.is_empty() {
    if options.feature_weights.length() != x.dimensions {
      return Err(
        failure("feature_weights", "one weight per feature is required"),
      )
    }
    let mut total = 0.0
    for w in options.feature_weights {
      if w != w || w < 0.0 || w > 1000000.0 {
        return Err(
          failure(
            "feature_weights", "feature weights must be finite and within [0, 1000000]",
          ),
        )
      }
      total += w
    }
    if total <= 0.0 {
      return Err(
        failure(
          "feature_weights", "at least one feature weight must be positive",
        ),
      )
    }
  }
  Ok(())
}

///|
fn feature_weight(options : AlignOptions, feature : Int32) -> Double {
  if options.feature_weights.is_empty() {
    1.0
  } else {
    options.feature_weights[feature]
  }
}
