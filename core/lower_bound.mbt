///|
/// Result of a lower-bound-pruned k-nearest-neighbour search.
pub(all) struct KnnPrunedPrediction {
  label : String
  neighbors : Array[Neighbor]
  labels : Array[String]
  votes : Array[Int32]
  work_units : Int32
  lower_bound_checks : Int32
  full_distance_calls : Int32
}

///|
priv struct LowerBoundCandidate {
  index : Int32
  lower : Double
}

///|
/// Query envelope for LB_Keogh. A negative radius means one global min/max
/// per feature; a nonnegative radius uses the Sakoe-Chiba neighbourhood.
fn query_envelope(
  query : Series,
  radius : Int32,
) -> (Array[Double], Array[Double]) {
  let n = query.count
  let d = query.dimensions
  let lower = Array::make(n * d, 0.0)
  let upper = Array::make(n * d, 0.0)
  if radius < 0 {
    for k = 0; k < d; k = k + 1 {
      let mut minimum = query.values[k]
      let mut maximum = query.values[k]
      for i = 1; i < n; i = i + 1 {
        let value = query.values[i * d + k]
        if value < minimum {
          minimum = value
        }
        if value > maximum {
          maximum = value
        }
      }
      for i = 0; i < n; i = i + 1 {
        lower[i * d + k] = minimum
        upper[i * d + k] = maximum
      }
    }
  } else {
    for i = 0; i < n; i = i + 1 {
      let start = (i - radius).max(0)
      let end = (i + radius).min(n - 1)
      for k = 0; k < d; k = k + 1 {
        let mut minimum = query.values[start * d + k]
        let mut maximum = query.values[start * d + k]
        for j = start + 1; j <= end; j = j + 1 {
          let value = query.values[j * d + k]
          if value < minimum {
            minimum = value
          }
          if value > maximum {
            maximum = value
          }
        }
        lower[i * d + k] = minimum
        upper[i * d + k] = maximum
      }
    }
  }
  (lower, upper)
}

///|
/// Logical work for building one query envelope.
fn envelope_work(query : Series, radius : Int32) -> Int32 {
  if radius < 0 {
    query.count * query.dimensions
  } else {
    query.count * query.dimensions * (2 * radius + 1)
  }
}

///|
/// LB_Keogh between a prepared query envelope and a candidate. The bound is
/// only defined for equal lengths here; unequal lengths return zero, which is
/// a valid (but weak) lower bound and keeps the pruned search exact.
pub fn lb_keogh_prepared(
  lower : Array[Double],
  upper : Array[Double],
  candidate : Series,
  feature_weights : Array[Double],
) -> Double {
  if candidate.count * candidate.dimensions != lower.length() {
    return 0.0
  }
  let n = candidate.count
  let d = candidate.dimensions
  let mut total = 0.0
  for i = 0; i < n; i = i + 1 {
    for k = 0; k < d; k = k + 1 {
      let value = candidate.values[i * d + k]
      let weight = if feature_weights.is_empty() {
        1.0
      } else {
        feature_weights[k]
      }
      if value > upper[i * d + k] {
        let delta = value - upper[i * d + k]
        total += weight * delta * delta
      } else if value < lower[i * d + k] {
        let delta = lower[i * d + k] - value
        total += weight * delta * delta
      }
    }
  }
  total.sqrt()
}

///|
/// Distance-only DTW with an upper cutoff. Returns `None` when the row minimum
/// or the final cost is strictly greater than `threshold`, because remaining
/// costs are nonnegative and cannot improve it. Equal costs are evaluated so
/// callers can preserve exact tie ordering.
pub fn dtw_distance_bounded(
  x : Series,
  y : Series,
  options : DtwOptions,
  threshold : Double,
) -> Result[DtwDistance?, WarpError] {
  if threshold != threshold || threshold < 0.0 {
    return Err(failure("threshold", "threshold must be finite and nonnegative"))
  }
  match validate_dtw_pair(x, y, options) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let limit = threshold * threshold
  // A squared distance is not exactly representable: sqrt(6)^2 evaluates to
  // 5.999999999999999, which would reject a candidate whose cost is exactly
  // 6.0 - an exact tie, not a worse neighbour. Allow a tiny relative slack so
  // ties survive and the caller keeps its exact ordering promise.
  let slack = limit * 1.0e-12 + 1.0e-12
  let n = x.count
  let m = y.count
  let dimensions = x.dimensions
  let weights = dtw_alignment_options(options)
  let mut previous = Array::make(m + 1, @double.infinity)
  let mut current = Array::make(m + 1, @double.infinity)
  previous[0] = 0.0
  let mut visited = 0
  for i = 1; i <= n; i = i + 1 {
    let row = i - 1
    let mut lower = 0
    let mut upper = m - 1
    if options.window >= 0 {
      if n <= m {
        lower = (row - options.window).max(0)
        upper = (row + (m - n) + options.window).min(m - 1)
      } else {
        lower = (row - (n - m) - options.window).max(0)
        upper = (row + options.window).min(m - 1)
      }
    }
    let first = lower + 1
    let last = upper + 1
    current[0] = @double.infinity
    if first > 1 {
      current[first - 1] = @double.infinity
    }
    if last < m {
      current[last + 1] = @double.infinity
    }
    let mut row_min = @double.infinity
    for j = first; j <= last; j = j + 1 {
      let mut point_cost = 0.0
      for k = 0; k < dimensions; k = k + 1 {
        let delta = x.values[(i - 1) * dimensions + k] -
          y.values[(j - 1) * dimensions + k]
        point_cost += feature_weight(weights, k) * delta * delta
      }
      let diagonal = previous[j - 1]
      let up = previous[j]
      let left = current[j - 1]
      let mut best = diagonal
      if up < best {
        best = up
      }
      if left < best {
        best = left
      }
      current[j] = point_cost + best
      if current[j] < row_min {
        row_min = current[j]
      }
      visited += 1
    }
    if row_min > limit + slack {
      return Ok(None)
    }
    let old = previous
    previous = current
    current = old
  }
  let cost = previous[m]
  if cost > limit + slack {
    Ok(None)
  } else {
    Ok(
      Some({
        distance: cost.sqrt(),
        squared_cost: cost,
        visited_cells: visited,
      }),
    )
  }
}

///|
/// k-nearest-neighbour classification with LB_Keogh ordering and exact
/// early-abandoned DTW. Results are identical to `knn_classify`; the extra
/// counters show how many full distance evaluations were avoided.
pub fn knn_classify_pruned(
  query : Series,
  training : Array[LabeledSeries],
  options : KnnOptions,
) -> Result[KnnPrunedPrediction, WarpError] {
  if training.is_empty() || training.length() > 32 {
    return Err(failure("training_count", "expected 1..32 training series"))
  }
  if options.k < 1 || options.k > training.length() {
    return Err(failure("k", "k must be within 1..training series count"))
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  let mut units = 0
  for item in training {
    if item.label.length() < 1 || item.label.length() > 80 {
      return Err(
        failure("label", "labels must be nonempty and at most 80 UTF-16 units"),
      )
    }
    match validate_dtw_pair(query, item.series, options.alignment) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  let radius = if options.alignment.window < 0 {
    -1
  } else {
    options.alignment.window
  }
  let envelope_units = envelope_work(query, radius)
  if envelope_units > options.max_work_units {
    return Err(failure("work_budget", "budget cannot cover the query envelope"))
  }
  units += envelope_units
  let (lower, upper) = query_envelope(query, radius)
  let candidates : Array[LowerBoundCandidate] = []
  for index, item in training {
    let pair_units = query.count * query.dimensions
    if pair_units > options.max_work_units ||
      units > options.max_work_units - pair_units {
      return Err(failure("work_budget", "budget cannot cover all lower bounds"))
    }
    units += pair_units
    candidates.push({
      index,
      lower: lb_keogh_prepared(
        lower,
        upper,
        item.series,
        options.alignment.feature_weights,
      ),
    })
  }
  candidates.sort_by(fn(a, b) {
    if a.lower < b.lower {
      -1
    } else if a.lower > b.lower {
      1
    } else {
      a.index - b.index
    }
  })
  let mut selected : Array[Neighbor] = []
  let mut threshold = @double.infinity
  let mut full_distance_calls = 0
  for candidate in candidates {
    if selected.length() == options.k && candidate.lower > threshold {
      break
    }
    let item = training[candidate.index]
    let pair_units = query.count * item.series.count * query.dimensions
    if pair_units > options.max_work_units ||
      units > options.max_work_units - pair_units {
      return Err(
        failure("work_budget", "budget cannot cover the remaining distances"),
      )
    }
    units += pair_units
    full_distance_calls += 1
    let cutoff = if selected.length() == options.k {
      threshold
    } else {
      @double.infinity
    }
    let measured = match
      dtw_distance_bounded(query, item.series, options.alignment, cutoff) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match measured {
      Some(value) => {
        selected.push({
          label: item.label,
          train_index: candidate.index,
          distance: value.distance,
        })
        selected.sort_by(fn(a, b) {
          if a.distance < b.distance {
            -1
          } else if a.distance > b.distance {
            1
          } else {
            a.train_index - b.train_index
          }
        })
        if selected.length() > options.k {
          let trimmed : Array[Neighbor] = []
          for position = 0; position < options.k; position = position + 1 {
            trimmed.push(selected[position])
          }
          selected = trimmed
        }
        threshold = selected[selected.length() - 1].distance
      }
      None => ()
    }
  }
  if selected.length() < options.k {
    return Err(
      failure("knn_empty", "not enough candidates survived the search"),
    )
  }
  let labels : Array[String] = []
  let votes : Array[Int32] = []
  let distance_sums : Array[Double] = []
  for index = 0; index < options.k; index = index + 1 {
    let neighbor = selected[index]
    let mut found = -1
    for position, label in labels {
      if label == neighbor.label {
        found = position
      }
    }
    if found >= 0 {
      votes[found] += 1
      distance_sums[found] += neighbor.distance
    } else {
      labels.push(neighbor.label)
      votes.push(1)
      distance_sums.push(neighbor.distance)
    }
  }
  let mut best = 0
  for position = 1; position < labels.length(); position = position + 1 {
    if votes[position] > votes[best] {
      best = position
    } else if votes[position] == votes[best] &&
      distance_sums[position] < distance_sums[best] {
      best = position
    }
  }
  Ok({
    label: labels[best],
    neighbors: selected,
    labels,
    votes,
    work_units: units,
    lower_bound_checks: training.length(),
    full_distance_calls,
  })
}
