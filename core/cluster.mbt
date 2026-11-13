///|
/// Deterministic DTW k-means with user-provided initial centers and DBA updates.
pub(all) struct ClusterOptions {
  alignment : DtwOptions
  max_iterations : Int32
  max_dba_steps : Int32
  tolerance : Double
  /// Shared logical full-matrix-cell * feature budget for every DTW call.
  max_work_units : Int32
}

///|
pub(all) struct ClusterFit {
  centers : Array[Series]
  /// Index into centers for each input series, in the same order as input.
  labels : Array[Int32]
  /// Mean of the selected squared DTW path costs, not a probability.
  inertia : Double
  /// Initial inertia followed by fully evaluated accepted iterations.
  history : Array[Double]
  iterations : Int32
  stop : String
  work_units : Int32
}

///|
pub fn cluster_options() -> ClusterOptions {
  {
    alignment: dtw_options(),
    max_iterations: 20,
    max_dba_steps: 20,
    tolerance: 1.0e-8,
    max_work_units: 20000000,
  }
}

///|
fn cluster_assignment_units(
  data : Array[Series],
  centers : Array[Series],
  options : DtwOptions,
  budget : Int32,
) -> Result[Int32, WarpError] {
  let mut units = 0
  for center in centers {
    for sample in data {
      match validate_dtw_pair(center, sample, options) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      let pair_units = center.count * sample.count * center.dimensions
      // Compare before adding: 32*16*512*512*16 can overflow Int32.
      if pair_units > budget || units > budget - pair_units {
        return Err(
          failure(
            "work_budget", "budget cannot cover a complete cluster assignment",
          ),
        )
      }
      units += pair_units
    }
  }
  Ok(units)
}

///|
fn cluster_assign(
  data : Array[Series],
  centers : Array[Series],
  options : DtwOptions,
) -> Result[(Array[Int32], Double), WarpError] {
  let labels : Array[Int32] = []
  let counts = Array::make(centers.length(), 0)
  let mut total = 0.0
  for sample in data {
    let mut best_index = 0
    let mut best_cost = @double.infinity
    for k, center in centers {
      let result = match dtw_distance(center, sample, options) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      // Strict comparison keeps the lowest center index for exact ties.
      if result.squared_cost < best_cost {
        best_cost = result.squared_cost
        best_index = k
      }
    }
    labels.push(best_index)
    counts[best_index] += 1
    total += best_cost
  }
  for count in counts {
    if count == 0 {
      return Err(
        failure(
          "empty_cluster", "an initial or updated center has no members; choose different centers or reduce k",
        ),
      )
    }
  }
  Ok((labels, total / data.length().to_double()))
}

///|
fn finish_cluster(
  centers : Array[Series],
  assignment : (Array[Int32], Double),
  history : Array[Double],
  iterations : Int32,
  stop : String,
  units : Int32,
) -> ClusterFit {
  {
    centers,
    labels: assignment.0,
    inertia: assignment.1,
    history,
    iterations,
    stop,
    work_units: units,
  }
}

///|
/// Cluster variable-length samples with hard DTW and DBA center updates.
/// Initial centers are supplied by the caller. Every successful return includes
/// centers and nearest-center labels evaluated together. Empty clusters are an
/// explicit error; they are never silently dropped or assigned a fake center.
pub fn dtw_kmeans(
  data : Array[Series],
  initial_centers : Array[Series],
  options : ClusterOptions,
) -> Result[ClusterFit, WarpError] {
  if data.is_empty() ||
    data.length() > 32 ||
    initial_centers.is_empty() ||
    initial_centers.length() > 16 ||
    initial_centers.length() > data.length() {
    return Err(
      failure(
        "cluster_count", "expected 1..32 samples and 1..min(16, samples) initial centers",
      ),
    )
  }
  if options.max_iterations < 0 ||
    options.max_iterations > 50 ||
    options.max_dba_steps < 1 ||
    options.max_dba_steps > 50 ||
    options.tolerance != options.tolerance ||
    options.tolerance < 0.0 ||
    options.tolerance > 1000.0 {
    return Err(
      failure(
        "cluster_options", "expected 0..50 iterations, 1..50 DBA steps, and finite tolerance in [0, 1000]",
      ),
    )
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  let mut centers : Array[Series] = []
  for center in initial_centers {
    centers.push({ ..center, values: center.values.copy(), })
  }
  let assignment_units = match
    cluster_assignment_units(
      data,
      centers,
      options.alignment,
      options.max_work_units,
    ) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let mut assignment = match cluster_assign(data, centers, options.alignment) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let mut work = assignment_units
  let history = [assignment.1]
  let mut iterations = 0
  let mut stop = "max_iterations"
  for _iteration = 0
      _iteration < options.max_iterations
      _iteration = _iteration + 1 {
    let next_centers : Array[Series] = []
    let mut budget_stop = false
    for k, center in centers {
      let members : Array[Series] = []
      for i, sample in data {
        if assignment.0[i] == k {
          members.push(sample)
        }
      }
      let remaining = options.max_work_units - work
      if remaining < 1 {
        budget_stop = true
        break
      }
      let opts = {
        ..dba_options(),
        alignment: options.alignment,
        max_steps: options.max_dba_steps,
        tolerance: options.tolerance,
        max_work_units: remaining,
      }
      let fitted = match dba_fit(center, members, opts) {
        Ok(v) => v
        Err(e) => {
          if e.code == "work_budget" {
            budget_stop = true
            break
          }
          return Err(e)
        }
      }
      work += fitted.work_units
      if fitted.stop == "work_budget" {
        budget_stop = true
        break
      }
      next_centers.push(fitted.prototype)
    }
    if budget_stop || assignment_units > options.max_work_units - work {
      stop = "work_budget"
      break
    }
    let next = match cluster_assign(data, next_centers, options.alignment) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    work += assignment_units
    if next.1 > assignment.1 {
      stop = "numerical_stall"
      break
    }
    let improvement = assignment.1 - next.1
    let scale = if assignment.1.abs() > 1.0 { assignment.1.abs() } else { 1.0 }
    centers = next_centers
    assignment = next
    history.push(next.1)
    iterations += 1
    if improvement <= options.tolerance * scale {
      stop = "improvement_tolerance"
      break
    }
  }
  Ok(finish_cluster(centers, assignment, history, iterations, stop, work))
}
