///|
/// Deterministic DTW k-medoids options. Medoids are actual input samples, so
/// the result is robust to a prototype being pulled by an outlier.
pub(all) struct MedoidOptions {
  alignment : DtwOptions
  max_iterations : Int32
  max_work_units : Int32
}

///|
pub fn medoid_options() -> MedoidOptions {
  { alignment: dtw_options(), max_iterations: 20, max_work_units: 40000000, }
}

///|
pub(all) struct MedoidFit {
  /// Indices into the input data, in deterministic selection order.
  medoid_indices : Array[Int32]
  /// Index into `medoid_indices` for each input sample.
  labels : Array[Int32]
  /// Mean squared DTW distance to the selected medoid.
  cost : Double
  /// Initial cost followed by fully evaluated accepted swaps.
  history : Array[Double]
  iterations : Int32
  stop : String
  work_units : Int32
}

///|
fn medoid_assign(
  matrix : Array[Double],
  n : Int32,
  medoids : Array[Int32],
) -> (Array[Int32], Double) {
  let labels : Array[Int32] = []
  let mut total = 0.0
  for i = 0; i < n; i = i + 1 {
    let mut best = @double.infinity
    let mut selected = 0
    for position, medoid in medoids {
      let distance = matrix[i * n + medoid]
      if distance < best {
        best = distance
        selected = position
      }
    }
    labels.push(selected)
    total += best * best
  }
  (labels, total / n.to_double())
}

///|
fn medoid_cost_with_swap(
  matrix : Array[Double],
  n : Int32,
  medoids : Array[Int32],
  replace_position : Int32,
  candidate : Int32,
) -> Double {
  let mut total = 0.0
  for i = 0; i < n; i = i + 1 {
    let mut best = @double.infinity
    for position, medoid in medoids {
      let actual = if position == replace_position { candidate } else { medoid }
      let distance = matrix[i * n + actual]
      if distance < best {
        best = distance
      }
    }
    total += best * best
  }
  total / n.to_double()
}

///|
/// Deterministic PAM-style k-medoids on a precomputed DTW distance matrix.
/// Initial medoids use farthest-first selection from `first_index`; each
/// iteration accepts the best single swap and stops when no swap improves the
/// mean squared cost. Ties keep the first position/candidate in index order.
pub fn dtw_kmedoids(
  data : Array[Series],
  cluster_count : Int32,
  first_index : Int32,
  options : MedoidOptions,
) -> Result[MedoidFit, WarpError] {
  let n = data.length()
  if n < 2 || n > 32 {
    return Err(failure("sample_count", "expected 2..32 samples"))
  }
  if cluster_count < 2 || cluster_count > 16 || cluster_count > n {
    return Err(
      failure(
        "cluster_count", "cluster_count must be within 2..min(16, samples)",
      ),
    )
  }
  if first_index < 0 || first_index >= n {
    return Err(failure("first_index", "first_index must index an input sample"))
  }
  if options.max_iterations < 0 || options.max_iterations > 50 {
    return Err(failure("max_iterations", "max_iterations must be within 0..50"))
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
  let selected = Array::make(n, false)
  let medoids = [first_index]
  selected[first_index] = true
  let nearest = Array::make(n, @double.infinity)
  while medoids.length() < cluster_count {
    let newest = medoids[medoids.length() - 1]
    for i = 0; i < n; i = i + 1 {
      if !selected[i] {
        let distance = matrix[newest * n + i]
        if distance < nearest[i] {
          nearest[i] = distance
        }
      }
    }
    let mut farthest = -1
    let mut farthest_distance = -1.0
    for i = 0; i < n; i = i + 1 {
      if !selected[i] && nearest[i] > farthest_distance {
        farthest = i
        farthest_distance = nearest[i]
      }
    }
    if farthest < 0 || farthest_distance <= 0.0 {
      // Every remaining point coincides with an existing medoid: constant
      // series, duplicated rows, or a batch that was not deduplicated. That is
      // legitimate data, not an error - take the smallest unselected index,
      // whose cost contribution is zero, and keep going.
      farthest = -1
      for i = 0; i < n; i = i + 1 {
        if !selected[i] {
          farthest = i
          break
        }
      }
      if farthest < 0 {
        return Err(
          failure("seed_distinct", "not enough points to seed medoids"),
        )
      }
    }
    selected[farthest] = true
    medoids.push(farthest)
  }
  let mut assignment = medoid_assign(matrix, n, medoids)
  let history = [assignment.1]
  let mut work = matrix_units.to_int()
  let mut iterations = 0
  let mut stop = "max_iterations"
  for _iteration = 0
      _iteration < options.max_iterations
      _iteration = _iteration + 1 {
    let mut best_position = -1
    let mut best_candidate = -1
    let mut best_cost = assignment.1
    for position = 0; position < cluster_count; position = position + 1 {
      for candidate = 0; candidate < n; candidate = candidate + 1 {
        if selected[candidate] {
          continue
        }
        let trial_units = n * cluster_count
        if trial_units > options.max_work_units - work {
          return Err(
            failure("work_budget", "budget cannot cover every medoid swap"),
          )
        }
        work += trial_units
        let cost = medoid_cost_with_swap(
          matrix, n, medoids, position, candidate,
        )
        if cost < best_cost {
          best_cost = cost
          best_position = position
          best_candidate = candidate
        }
      }
    }
    if best_position < 0 {
      stop = "no_improvement"
      break
    }
    selected[medoids[best_position]] = false
    medoids[best_position] = best_candidate
    selected[best_candidate] = true
    assignment = medoid_assign(matrix, n, medoids)
    history.push(assignment.1)
    iterations += 1
    // Every accepted swap strictly lowers the cost (the scan only records a
    // candidate when cost < best_cost), so the loop cannot cycle. The old
    // guard compared the freshly recomputed cost with the value it was built
    // from, was therefore always equal, and stopped after the first swap -
    // leaving a strictly better medoid set unexplored.

  }
  Ok({
    medoid_indices: medoids,
    labels: assignment.0,
    cost: assignment.1,
    history,
    iterations,
    stop,
    work_units: work,
  })
}
