///|
/// Reusable inference state. Version 1 stores preprocessing and alignment
/// parameters with the learned centers; it is not a classification model.
pub(all) struct ClusterModel {
  version : Int32
  centers : Array[Series]
  preprocessing : PreprocessOptions
  alignment : DtwOptions
}

///|
pub(all) struct ClusterModelFit {
  model : ClusterModel
  training : PipelineFit
}

///|
pub(all) struct SeedSelection {
  indices : Array[Int32]
  work_units : Int32
}

///|
pub(all) struct AutoClusterModelFit {
  fitted : ClusterModelFit
  seed_indices : Array[Int32]
  seed_work_units : Int32
  total_work_units : Int32
}

///|
pub(all) struct ClusterPrediction {
  prepared : Array[PreparedSeries]
  labels : Array[Int32]
  /// Euclidean-rooted DTW distance to the chosen center, per sample.
  distances : Array[Double]
  /// One distance per center in each row, preserving center order.
  distances_to_centers : Array[Array[Double]]
  work_units : Int32
}

///|
fn model_fit_from_training(
  training : PipelineFit,
  options : PipelineOptions,
) -> ClusterModelFit {
  let centers : Array[Series] = []
  for center in training.clustering.centers {
    centers.push({ ..center, values: center.values.copy(), })
  }
  let alignment : DtwOptions = {
    ..options.clustering.alignment,
    feature_weights: options.clustering.alignment.feature_weights.copy(),
  }
  {
    training,
    model: {
      version: 1,
      centers,
      preprocessing: options.preprocessing,
      alignment,
    },
  }
}

///|
/// Train once, then retain the exact preprocessing and alignment parameters
/// needed for later inference. Arrays in the model do not alias the options
/// or the training result supplied to or returned from this function.
pub fn train_cluster_model(
  data : Array[Series],
  seed_indices : Array[Int32],
  options : PipelineOptions,
) -> Result[ClusterModelFit, WarpError] {
  let training = match prepare_and_cluster(data, seed_indices, options) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(model_fit_from_training(training, options))
}

///|
/// Deterministic farthest-first initialization on already-prepared samples.
/// Each next center maximizes distance to its nearest chosen center; ties
/// favor the smallest unselected index. This is not randomized k-means++.
pub fn select_farthest_seeds(
  data : Array[Series],
  count : Int32,
  first_index : Int32,
  alignment : DtwOptions,
  max_work_units : Int32,
) -> Result[SeedSelection, WarpError] {
  if data.is_empty() ||
    data.length() > 32 ||
    count < 1 ||
    count > 16 ||
    count > data.length() ||
    first_index < 0 ||
    first_index >= data.length() {
    return Err(failure("seed_indices", "invalid sample count or initial seed"))
  }
  if max_work_units < 1 || max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  // Validate even when count == 1 and no distance needs to be evaluated.
  for sample in data {
    match validate_dtw_pair(data[first_index], sample, alignment) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  let chosen = [first_index]
  let selected = Array::make(data.length(), false)
  selected[first_index] = true
  let nearest = Array::make(data.length(), @double.infinity)
  let mut units = 0
  while chosen.length() < count {
    let newest = chosen[chosen.length() - 1]
    for index, sample in data {
      if selected[index] {
        continue
      }
      match validate_dtw_pair(data[newest], sample, alignment) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
      let needed = data[newest].count * sample.count * sample.dimensions
      if needed > max_work_units || units > max_work_units - needed {
        return Err(
          failure("work_budget", "budget cannot complete seed selection"),
        )
      }
      let distance = match dtw_distance(data[newest], sample, alignment) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      units += needed
      if distance.squared_cost < nearest[index] {
        nearest[index] = distance.squared_cost
      }
    }
    let mut farthest = -1
    let mut farthest_cost = -1.0
    for index, value in nearest {
      if !selected[index] && value > farthest_cost {
        farthest = index
        farthest_cost = value
      }
    }
    if farthest < 0 || farthest_cost <= 0.0 {
      return Err(
        failure(
          "seed_distinct", "not enough distinguishable seeds under the selected DTW settings",
        ),
      )
    }
    selected[farthest] = true
    chosen.push(farthest)
  }
  Ok({ indices: chosen, work_units: units, })
}

///|
/// Select deterministic initial centers and train under one shared logical
/// DTW work budget; preprocessing has its separately bounded input size.
pub fn train_cluster_model_auto(
  data : Array[Series],
  cluster_count : Int32,
  first_index : Int32,
  options : PipelineOptions,
) -> Result[AutoClusterModelFit, WarpError] {
  if data.is_empty() || data.length() > 32 {
    return Err(failure("model_shape", "expected 1..32 samples"))
  }
  let prepared : Array[PreparedSeries] = []
  let processed : Array[Series] = []
  for sample in data {
    let item = match prepare_series(sample, options.preprocessing) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    prepared.push(item)
    processed.push(item.series)
  }
  let seeds = match
    select_farthest_seeds(
      processed,
      cluster_count,
      first_index,
      options.clustering.alignment,
      options.clustering.max_work_units,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let remaining = options.clustering.max_work_units - seeds.work_units
  if remaining < 1 {
    return Err(
      failure(
        "work_budget", "budget cannot cover cluster assignment after seeding",
      ),
    )
  }
  let centers : Array[Series] = []
  for index in seeds.indices {
    centers.push(processed[index])
  }
  let clustered = match
    dtw_kmeans(processed, centers, {
      ..options.clustering,
      max_work_units: remaining,
    }) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let training : PipelineFit = { prepared, clustering: clustered, }
  Ok({
    fitted: model_fit_from_training(training, options),
    seed_indices: seeds.indices,
    seed_work_units: seeds.work_units,
    total_work_units: seeds.work_units + clustered.work_units,
  })
}

///|
/// Assign each new sample to its nearest center without changing the model.
/// A center may receive zero samples. Before evaluating any DTW matrices, the
/// complete batch is checked against the logical full-matrix work budget.
pub fn predict_clusters(
  model : ClusterModel,
  data : Array[Series],
  max_work_units : Int32,
) -> Result[ClusterPrediction, WarpError] {
  if model.version != 1 {
    return Err(failure("model_version", "unsupported cluster model version"))
  }
  if model.centers.is_empty() ||
    model.centers.length() > 16 ||
    data.is_empty() ||
    data.length() > 32 {
    return Err(
      failure("model_shape", "expected 1..16 centers and 1..32 samples"),
    )
  }
  if max_work_units < 1 || max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  let prepared : Array[PreparedSeries] = []
  for sample in data {
    let item = match prepare_series(sample, model.preprocessing) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    prepared.push(item)
  }
  let mut total_units = 0
  for item in prepared {
    for center in model.centers {
      match validate_dtw_pair(center, item.series, model.alignment) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
      if model.preprocessing.target_count > 0 &&
        center.count != model.preprocessing.target_count {
        return Err(
          failure("model_shape", "center length must match model target_count"),
        )
      }
      let units = center.count * item.series.count * center.dimensions
      if units > max_work_units || total_units > max_work_units - units {
        return Err(
          failure("work_budget", "budget cannot cover complete predictions"),
        )
      }
      total_units += units
    }
  }
  let labels : Array[Int32] = []
  let distances : Array[Double] = []
  let all_distances : Array[Array[Double]] = []
  for item in prepared {
    let mut best = @double.infinity
    let mut selected = 0
    let row : Array[Double] = []
    for index, center in model.centers {
      let result = match dtw_distance(center, item.series, model.alignment) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      row.push(result.distance)
      if result.squared_cost < best {
        best = result.squared_cost
        selected = index
      }
    }
    labels.push(selected)
    distances.push(row[selected])
    all_distances.push(row)
  }
  Ok({
    prepared,
    labels,
    distances,
    distances_to_centers: all_distances,
    work_units: total_units,
  })
}
