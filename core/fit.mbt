///|
pub(all) struct FitOptions {
  alignment : AlignOptions
  max_steps : Int32
  learning_rate : Double
  gradient_tolerance : Double
  improvement_tolerance : Double
  max_evaluations : Int32
  /// Logical matrix-cell/feature units, not a wall-clock or instruction limit.
  max_work_units : Int32
  /// Empty means equal example weights; otherwise strictly positive weights.
  example_weights : Array[Double]
}

///|
pub(all) struct Fit {
  prototype : Series
  objective : Array[Double]
  accepted_steps : Int32
  stop : String
  evaluations : Int32
  work_units : Int32
  gradient_norm : Double
}

///|
pub fn fitting_options(gamma : Double, steps : Int32) -> FitOptions {
  {
    alignment: alignment_options(gamma),
    max_steps: steps,
    learning_rate: 1.0,
    gradient_tolerance: 1.0e-8,
    improvement_tolerance: 1.0e-10,
    max_evaluations: 512,
    max_work_units: 20000000,
    example_weights: [],
  }
}

///|
fn gradient_norm(g : Array[Double]) -> Double {
  let mut norm2 = 0.0
  for x in g {
    norm2 += x * x
  }
  norm2.sqrt()
}

///|
fn fit_result(
  state : Series,
  current : (Double, Array[Double]),
  history : Array[Double],
  accepted : Int32,
  stop : String,
  evaluations : Int32,
  work : Int32,
) -> Fit {
  {
    prototype: state,
    objective: history,
    accepted_steps: accepted,
    stop,
    evaluations,
    work_units: work,
    gradient_norm: gradient_norm(current.1),
  }
}

///|
fn fit_objective(
  state : Series,
  examples : Array[Series],
  self_values : Array[Double],
  weights : Array[Double],
  options : AlignOptions,
) -> Result[(Double, Array[Double]), WarpError] {
  let xx = match soft_dtw_with(state, state, options) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let gradient = Array::make(state.values.length(), 0.0)
  let mut value = -0.5 * xx.value
  for i, example in examples {
    let xy = match soft_dtw_with(state, example, options) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    value += weights[i] * (xy.value - 0.5 * self_values[i])
    for k = 0; k < gradient.length(); k = k + 1 {
      gradient[k] += weights[i] * xy.gradient_x[k]
    }
  }
  for k = 0; k < gradient.length(); k = k + 1 {
    gradient[k] -= 0.5 * (xx.gradient_x[k] + xx.gradient_y[k])
  }
  Ok((value, gradient))
}

///|
pub fn fit(
  seed : Series,
  examples : Array[Series],
  gamma : Double,
  steps : Int32,
) -> Result[Fit, WarpError] {
  fit_with(seed, examples, fitting_options(gamma, steps))
}

///|
/// Fixed-length prototype optimization of the weighted self-corrected objective.
/// Every accepted iterate satisfies an Armijo decrease test. A stopping label
/// describes this local run, and never certifies global optimality.
pub fn fit_with(
  seed : Series,
  examples : Array[Series],
  options : FitOptions,
) -> Result[Fit, WarpError] {
  if examples.is_empty() || examples.length() > 32 {
    return Err(failure("example_count", "expected 1..32 example series"))
  }
  if options.max_steps < 0 ||
    options.max_steps > 200 ||
    options.max_evaluations < 1 ||
    options.max_evaluations > 2048 {
    return Err(
      failure(
        "fit_options", "expected 0..200 steps and 1..2048 objective evaluations",
      ),
    )
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  for value in [options.gradient_tolerance, options.improvement_tolerance] {
    if value != value || value < 0.0 || value > 1000.0 {
      return Err(
        failure("fit_options", "tolerances must be finite and within [0, 1000]"),
      )
    }
  }
  if options.learning_rate != options.learning_rate ||
    options.learning_rate < 1.0e-8 ||
    options.learning_rate > 10.0 {
    return Err(
      failure(
        "fit_options", "learning_rate must be finite and within [1e-8, 10]",
      ),
    )
  }
  match validate_pair(seed, seed, options.alignment) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let weights = Array::make(examples.length(), 1.0)
  if !options.example_weights.is_empty() {
    if options.example_weights.length() != examples.length() {
      return Err(
        failure(
          "example_weights", "one positive weight per example is required",
        ),
      )
    }
    for i, w in options.example_weights {
      if w != w || w <= 0.0 || w > 1000000.0 {
        return Err(
          failure(
            "example_weights", "example weights must be finite and within (0, 1000000]",
          ),
        )
      }
      weights[i] = w
    }
  }
  let mut total_weight = 0.0
  for w in weights {
    total_weight += w
  }
  for i = 0; i < weights.length(); i = i + 1 {
    weights[i] /= total_weight
  }
  let mut preparation_units = 0
  let mut per_evaluation_units = seed.count * seed.count * seed.dimensions
  for example in examples {
    match validate_pair(seed, example, options.alignment) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
    match validate_pair(example, example, options.alignment) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
    preparation_units += example.count * example.count * example.dimensions
    per_evaluation_units += seed.count * example.count * seed.dimensions
  }
  if preparation_units + per_evaluation_units > options.max_work_units {
    return Err(
      failure(
        "work_budget", "budget cannot cover preparation and the initial objective",
      ),
    )
  }
  // Each fixed example's self term is calculated once and cached for this run.
  let self_values = Array::make(examples.length(), 0.0)
  for i, example in examples {
    match soft_dtw_with(example, example, options.alignment) {
      Err(e) => return Err(e)
      Ok(v) => self_values[i] = v.value
    }
  }
  let mut state = { ..seed, values: seed.values.copy(), }
  let mut current = match
    fit_objective(state, examples, self_values, weights, options.alignment) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let history = [current.0]
  let mut accepted = 0
  let mut evaluations = 1
  let mut work = preparation_units + per_evaluation_units
  for iteration = 0; iteration < options.max_steps; iteration = iteration + 1 {
    let norm = gradient_norm(current.1)
    if norm <= options.gradient_tolerance {
      return Ok(
        fit_result(
          state, current, history, accepted, "gradient_tolerance", evaluations, work,
        ),
      )
    }
    let mut rate = options.learning_rate
    let mut improved = false
    for attempt = 0; attempt < 24; attempt = attempt + 1 {
      if evaluations >= options.max_evaluations {
        return Ok(
          fit_result(
            state, current, history, accepted, "evaluation_budget", evaluations,
            work,
          ),
        )
      }
      if work + per_evaluation_units > options.max_work_units {
        return Ok(
          fit_result(
            state, current, history, accepted, "work_budget", evaluations, work,
          ),
        )
      }
      let values = Array::make(state.values.length(), 0.0)
      for k = 0; k < values.length(); k = k + 1 {
        values[k] = state.values[k] - rate * current.1[k]
      }
      let candidate = { ..state, values, }
      match validate_series(candidate) {
        Err(_) => {
          rate *= 0.5
          continue
        }
        Ok(_) => ()
      }
      let next = match
        fit_objective(
          candidate,
          examples,
          self_values,
          weights,
          options.alignment,
        ) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      evaluations += 1
      work += per_evaluation_units
      if next.0 <= current.0 - 1.0e-4 * rate * norm * norm {
        let improvement = current.0 - next.0
        let scale = if current.0.abs() > 1.0 { current.0.abs() } else { 1.0 }
        state = candidate
        current = next
        history.push(next.0)
        accepted += 1
        improved = true
        if improvement <= options.improvement_tolerance * scale {
          return Ok(
            fit_result(
              state, current, history, accepted, "improvement_tolerance", evaluations,
              work,
            ),
          )
        }
        break
      }
      rate *= 0.5
    }
    if !improved {
      return Ok(
        fit_result(
          state, current, history, accepted, "line_search_stalled", evaluations,
          work,
        ),
      )
    }
  }
  Ok(
    fit_result(
      state, current, history, accepted, "max_steps", evaluations, work,
    ),
  )
}
