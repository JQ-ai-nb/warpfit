///|
/// Bounded nearest-neighbour outlier scoring options.
pub(all) struct OutlierOptions {
  alignment : DtwOptions
  k : Int32
  max_work_units : Int32
}

///|
pub fn outlier_options() -> OutlierOptions {
  { alignment: dtw_options(), k: 1, max_work_units: 40000000, }
}

///|
pub(all) struct OutlierScore {
  index : Int32
  /// Mean distance to the k nearest other samples; larger means more isolated.
  score : Double
  neighbor_indices : Array[Int32]
  neighbor_distances : Array[Double]
}

///|
pub(all) struct OutlierResult {
  scores : Array[OutlierScore]
  work_units : Int32
}

///|
priv struct OutlierNeighbor {
  index : Int32
  distance : Double
}

///|
/// Score each sample by its mean distance to its k nearest neighbours under
/// hard DTW. This is a ranking aid, not a probability or a labelled anomaly
/// detector. Pairwise work is checked before any distance is computed.
pub fn dtw_outlier_scores(
  data : Array[Series],
  options : OutlierOptions,
) -> Result[OutlierResult, WarpError] {
  let n = data.length()
  if n < 3 || n > 32 {
    return Err(failure("sample_count", "expected 3..32 samples"))
  }
  if options.k < 1 || options.k > 8 || options.k >= n {
    return Err(failure("k", "k must be within 1..min(8, samples-1)"))
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  let max_units : Int64 = options.max_work_units.to_int64()
  let mut matrix_units : Int64 = 0
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      match validate_dtw_pair(data[i], data[j], options.alignment) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
      matrix_units += data[i].count.to_int64() *
        data[j].count.to_int64() *
        data[i].dimensions.to_int64()
    }
  }
  if matrix_units > max_units {
    return Err(
      failure("work_budget", "budget cannot cover the pairwise distance matrix"),
    )
  }
  let matrix = Array::make(n * n, 0.0)
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
  let scores : Array[OutlierScore] = []
  for i = 0; i < n; i = i + 1 {
    let neighbors : Array[OutlierNeighbor] = []
    for j = 0; j < n; j = j + 1 {
      if i != j {
        neighbors.push({ index: j, distance: matrix[i * n + j], })
      }
    }
    neighbors.sort_by(fn(a, b) {
      if a.distance < b.distance {
        -1
      } else if a.distance > b.distance {
        1
      } else {
        a.index - b.index
      }
    })
    let indices : Array[Int32] = []
    let distances : Array[Double] = []
    let mut total = 0.0
    for position = 0; position < options.k; position = position + 1 {
      indices.push(neighbors[position].index)
      distances.push(neighbors[position].distance)
      total += neighbors[position].distance
    }
    scores.push({
      index: i,
      score: total / options.k.to_double(),
      neighbor_indices: indices,
      neighbor_distances: distances,
    })
  }
  Ok({ scores, work_units: matrix_units.to_int(), })
}
