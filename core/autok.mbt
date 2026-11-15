///|
/// Deterministic model selection over a candidate set of cluster counts.
pub(all) struct AutoKOptions {
  alignment : DtwOptions
  clustering : ClusterOptions
  /// Fixed first seed, so a selection run is reproducible from its inputs.
  first_index : Int32
  max_work_units : Int32
}

///|
pub fn auto_k_options() -> AutoKOptions {
  {
    alignment: dtw_options(),
    clustering: cluster_options(),
    first_index: 0,
    max_work_units: 40000000,
  }
}

///|
pub(all) struct KScore {
  k : Int32
  /// Mean silhouette over all samples, computed on hard DTW distances.
  silhouette : Double
  labels : Array[Int32]
  inertia : Double
}

///|
pub(all) struct KSelection {
  best_k : Int32
  /// One entry per candidate that produced no empty cluster, in input order.
  scores : Array[KScore]
  work_units : Int32
}

///|
/// Mean silhouette of one labelling, given a flat n*n distance matrix.
/// Singletons contribute 0, which is the standard convention.
fn silhouette_mean(
  matrix : Array[Double],
  labels : Array[Int32],
  clusters : Int32,
) -> Double {
  let n = labels.length()
  let mut total = 0.0
  for i = 0; i < n; i = i + 1 {
    let own = labels[i]
    let mut same_sum = 0.0
    let mut same_count = 0
    for j = 0; j < n; j = j + 1 {
      if j != i && labels[j] == own {
        same_sum += matrix[i * n + j]
        same_count += 1
      }
    }
    if same_count == 0 {
      continue
    }
    let a = same_sum / same_count.to_double()
    let mut b = @double.infinity
    for cluster = 0; cluster < clusters; cluster = cluster + 1 {
      if cluster == own {
        continue
      }
      let mut sum = 0.0
      let mut count = 0
      for j = 0; j < n; j = j + 1 {
        if labels[j] == cluster {
          sum += matrix[i * n + j]
          count += 1
        }
      }
      if count > 0 {
        let mean = sum / count.to_double()
        if mean < b {
          b = mean
        }
      }
    }
    if b == @double.infinity {
      continue
    }
    let scale = if a > b { a } else { b }
    if scale > 0.0 {
      total += (b - a) / scale
    }
  }
  total / n.to_double()
}

///|
/// Evaluate candidate cluster counts and pick the one with the highest mean
/// silhouette. Ties keep the smaller k. Candidate counts that collapse to an
/// empty cluster are reported as absent rather than scored, and any other error
/// aborts the selection so a partial ranking is never presented as complete.
pub fn select_cluster_count(
  data : Array[Series],
  candidates : Array[Int32],
  options : AutoKOptions,
) -> Result[KSelection, WarpError] {
  let n = data.length()
  if n < 3 || n > 32 {
    return Err(
      failure("sample_count", "expected 3..32 samples for model selection"),
    )
  }
  if candidates.is_empty() || candidates.length() > 15 {
    return Err(failure("candidates", "expected 1..15 candidate cluster counts"))
  }
  let limit = if n - 1 < 16 { n - 1 } else { 16 }
  let mut previous = 1
  for k in candidates {
    if k < 2 || k > limit || k <= previous {
      return Err(
        failure(
          "candidates", "candidates must be strictly increasing integers within 2..min(16, samples-1)",
        ),
      )
    }
    previous = k
  }
  if options.first_index < 0 || options.first_index >= n {
    return Err(failure("first_index", "first_index must index an input sample"))
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  for sample in data {
    match validate_series(sample) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  // One symmetric distance matrix serves every candidate k.
  let mut matrix_units = 0
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      match validate_dtw_pair(data[i], data[j], options.alignment) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
      matrix_units += data[i].count * data[j].count * data[i].dimensions
    }
  }
  if matrix_units > options.max_work_units {
    return Err(
      failure("work_budget", "budget cannot cover the pairwise distance matrix"),
    )
  }
  let matrix : Array[Double] = Array::make(n * n, 0.0)
  for i = 0; i < n; i = i + 1 {
    for j = i; j < n; j = j + 1 {
      let measured = match dtw_distance(data[i], data[j], options.alignment) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      matrix[i * n + j] = measured.distance
      matrix[j * n + i] = measured.distance
    }
  }
  let mut work = matrix_units
  let scores : Array[KScore] = []
  for k in candidates {
    let remaining = options.max_work_units - work
    if remaining < 1 {
      return Err(
        failure(
          "work_budget", "budget cannot cover every candidate cluster count",
        ),
      )
    }
    let seeds = match
      select_farthest_seeds(
        data,
        k,
        options.first_index,
        options.alignment,
        remaining,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let centers : Array[Series] = []
    for index in seeds.indices {
      centers.push(data[index])
    }
    if remaining <= seeds.work_units {
      return Err(
        failure(
          "work_budget", "budget cannot cover every candidate cluster count",
        ),
      )
    }
    let fit = match
      dtw_kmeans(data, centers, {
        ..options.clustering,
        alignment: options.alignment,
        max_work_units: remaining - seeds.work_units,
      }) {
      Ok(value) => value
      Err(error) => {
        if error.code == "empty_cluster" {
          continue
        }
        return Err(error)
      }
    }
    work += seeds.work_units + fit.work_units
    scores.push({
      k,
      silhouette: silhouette_mean(matrix, fit.labels, k),
      labels: fit.labels,
      inertia: fit.inertia,
    })
  }
  if scores.is_empty() {
    return Err(
      failure(
        "empty_cluster", "every candidate cluster count produced an empty cluster",
      ),
    )
  }
  let mut best = 0
  for i = 1; i < scores.length(); i = i + 1 {
    if scores[i].silhouette > scores[best].silhouette {
      best = i
    }
  }
  Ok({ best_k: scores[best].k, scores, work_units: work, })
}
