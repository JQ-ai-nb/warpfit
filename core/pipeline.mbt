///|
/// Reusable per-series preprocessing. target_count=0 preserves sample counts;
/// otherwise resampling is performed before optional per-feature standardization.
pub(all) struct PreprocessOptions {
  target_count : Int32
  normalize : Bool
  epsilon : Double
}

///|
pub(all) struct PreparedSeries {
  series : Series
  normalized : Bool
  /// Empty when normalize=false; otherwise statistics of the resampled series.
  means : Array[Double]
  standard_deviations : Array[Double]
  constant_features : Array[Bool]
}

///|
pub fn preprocess_options() -> PreprocessOptions {
  { target_count: 0, normalize: true, epsilon: 1.0e-12, }
}

///|
pub fn prepare_series(
  series : Series,
  options : PreprocessOptions,
) -> Result[PreparedSeries, WarpError] {
  if options.target_count < 0 || options.target_count > 512 {
    return Err(
      failure("target_count", "target_count must be 0 or within 1..512"),
    )
  }
  if options.epsilon != options.epsilon ||
    options.epsilon < 0.0 ||
    options.epsilon > 10000.0 {
    return Err(
      failure("epsilon", "epsilon must be finite and within [0, 10000]"),
    )
  }
  let count = if options.target_count == 0 {
    series.count
  } else {
    options.target_count
  }
  let sampled = match resample_linear(series, count) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if options.normalize {
    let result = match standardize(sampled, options.epsilon) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    Ok({
      series: result.series,
      normalized: true,
      means: result.means,
      standard_deviations: result.standard_deviations,
      constant_features: result.constant_features,
    })
  } else {
    Ok({
      series: sampled,
      normalized: false,
      means: [],
      standard_deviations: [],
      constant_features: [],
    })
  }
}

///|
pub(all) struct PipelineOptions {
  preprocessing : PreprocessOptions
  clustering : ClusterOptions
}

///|
pub(all) struct PipelineFit {
  prepared : Array[PreparedSeries]
  clustering : ClusterFit
}

///|
pub fn pipeline_options() -> PipelineOptions {
  { preprocessing: preprocess_options(), clustering: cluster_options(), }
}

///|
/// Preprocess each input independently, then use the specified input indices
/// as cluster seeds. This composes the same public DTW/DBA implementation.
/// Preprocessing is bounded by input/shape limits but not included in the
/// clustering logical matrix-cell budget.
pub fn prepare_and_cluster(
  data : Array[Series],
  seed_indices : Array[Int32],
  options : PipelineOptions,
) -> Result[PipelineFit, WarpError] {
  if data.is_empty() ||
    data.length() > 32 ||
    seed_indices.is_empty() ||
    seed_indices.length() > 16 ||
    seed_indices.length() > data.length() {
    return Err(
      failure(
        "cluster_count", "expected 1..32 samples and 1..min(16, samples) seed indices",
      ),
    )
  }
  let seen = Array::make(data.length(), false)
  for index in seed_indices {
    if index < 0 || index >= data.length() || seen[index] {
      return Err(
        failure(
          "seed_indices", "seed indices must be unique and within the data array",
        ),
      )
    }
    seen[index] = true
  }
  let prepared : Array[PreparedSeries] = []
  let processed : Array[Series] = []
  for sample in data {
    let result = match prepare_series(sample, options.preprocessing) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    prepared.push(result)
    processed.push(result.series)
  }
  let initial : Array[Series] = []
  for index in seed_indices {
    initial.push(processed[index])
  }
  let clustered = match dtw_kmeans(processed, initial, options.clustering) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  Ok({ prepared, clustering: clustered, })
}
