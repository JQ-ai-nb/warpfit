///|
/// DBA learns one fixed-length prototype using hard DTW alignment paths.
pub(all) struct DbaOptions {
  alignment : DtwOptions
  max_steps : Int32
  tolerance : Double
  /// Logical allocated matrix cells * dimensions across all evaluations.
  max_work_units : Int32
  /// Empty means equal weights; otherwise one positive weight per example.
  example_weights : Array[Double]
}

///|
pub(all) struct DbaFit {
  prototype : Series
  /// Weighted mean of squared DTW path costs, initial state included.
  objective : Array[Double]
  accepted_steps : Int32
  stop : String
  evaluations : Int32
  work_units : Int32
}

///|
pub fn dba_options() -> DbaOptions {
  {
    alignment: dtw_options(),
    max_steps: 30,
    tolerance: 1.0e-8,
    max_work_units: 20000000,
    example_weights: [],
  }
}

///|
fn dba_evaluate(
  prototype : Series,
  examples : Array[Series],
  weights : Array[Double],
  options : DtwOptions,
) -> Result[(Double, Array[DtwPath]), WarpError] {
  let paths : Array[DtwPath] = []
  let mut value = 0.0
  for i, example in examples {
    let path = match dtw_path(prototype, example, options) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    value += weights[i] * path.squared_cost
    paths.push(path)
  }
  Ok((value, paths))
}

///|
/// Fit a fixed-length DBA prototype from a user-provided initial series.
/// Each accepted prototype has a completely evaluated, nonincreasing objective.
/// A budget stop returns the last fully evaluated state, never a partial step.
pub fn dba_fit(
  seed : Series,
  examples : Array[Series],
  options : DbaOptions,
) -> Result[DbaFit, WarpError] {
  if examples.is_empty() || examples.length() > 32 {
    return Err(failure("example_count", "expected 1..32 example series"))
  }
  if options.max_steps < 0 ||
    options.max_steps > 200 ||
    options.tolerance != options.tolerance ||
    options.tolerance < 0.0 ||
    options.tolerance > 1000.0 {
    return Err(
      failure(
        "dba_options", "expected 0..200 steps and finite tolerance in [0, 1000]",
      ),
    )
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  if !options.example_weights.is_empty() &&
    options.example_weights.length() != examples.length() {
    return Err(
      failure("example_weights", "one positive weight per example is required"),
    )
  }
  let weights = Array::make(examples.length(), 1.0)
  if !options.example_weights.is_empty() {
    for i, weight in options.example_weights {
      if weight != weight || weight <= 0.0 || weight > 1000000.0 {
        return Err(
          failure(
            "example_weights", "example weights must be finite and within (0, 1000000]",
          ),
        )
      }
      weights[i] = weight
    }
  }
  let mut weight_sum = 0.0
  for weight in weights {
    weight_sum += weight
  }
  for i = 0; i < weights.length(); i = i + 1 {
    weights[i] /= weight_sum
  }
  let mut evaluation_units = 0
  for example in examples {
    match validate_dtw_pair(seed, example, options.alignment) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
    evaluation_units += seed.count * example.count * seed.dimensions
  }
  if evaluation_units > options.max_work_units {
    return Err(
      failure("work_budget", "budget cannot cover the initial DBA objective"),
    )
  }
  let mut state = { ..seed, values: seed.values.copy(), }
  let mut current = match
    dba_evaluate(state, examples, weights, options.alignment) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let history = [current.0]
  let mut accepted = 0
  let mut evaluations = 1
  let mut work = evaluation_units
  let mut stop = "max_steps"
  let align_options = dtw_alignment_options(options.alignment)
  for _iteration = 0
      _iteration < options.max_steps
      _iteration = _iteration + 1 {
    if work + evaluation_units > options.max_work_units {
      stop = "work_budget"
      break
    }
    let sums = Array::make(state.values.length(), 0.0)
    let counts = Array::make(state.count, 0.0)
    for index, example in examples {
      let weight = weights[index]
      for point in current.1[index].path {
        counts[point.x_index] += weight
        for k = 0; k < state.dimensions; k = k + 1 {
          sums[point.x_index * state.dimensions + k] += weight *
            example.values[point.y_index * state.dimensions + k]
        }
      }
    }
    let values = state.values.copy()
    for i = 0; i < state.count; i = i + 1 {
      // Every complete monotone path visits each prototype index at least once.
      if counts[i] <= 0.0 {
        return Err(
          failure("dba_alignment", "a prototype point has no aligned samples"),
        )
      }
      for k = 0; k < state.dimensions; k = k + 1 {
        if feature_weight(align_options, k) > 0.0 {
          let mean = sums[i * state.dimensions + k] / counts[i]
          // Weighted averages lie in the input bounds mathematically. Correct
          // only a possible last-bit floating-point overshoot of that bound.
          values[i * state.dimensions + k] = if mean > 10000.0 {
            10000.0
          } else if mean < -10000.0 {
            -10000.0
          } else {
            mean
          }
        }
      }
    }
    let candidate = { ..state, values, }
    let next = match
      dba_evaluate(candidate, examples, weights, options.alignment) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    evaluations += 1
    work += evaluation_units
    if next.0 > current.0 {
      stop = "numerical_stall"
      break
    }
    let improvement = current.0 - next.0
    let scale = if current.0.abs() > 1.0 { current.0.abs() } else { 1.0 }
    state = candidate
    current = next
    history.push(next.0)
    accepted += 1
    if improvement <= options.tolerance * scale {
      stop = "improvement_tolerance"
      break
    }
  }
  Ok({
    prototype: state,
    objective: history,
    accepted_steps: accepted,
    stop,
    evaluations,
    work_units: work,
  })
}
