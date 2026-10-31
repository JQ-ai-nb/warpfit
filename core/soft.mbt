///|
/// Small local experiment, not a finished contest package.
/// Formula sources: Cuturi & Blondel (2017), Blondel et al. (2021).
pub(all) struct Series {
  count : Int32
  dimensions : Int32
  values : Array[Double]
}

///|
pub(all) struct Evaluation {
  value : Double
  gradient_x : Array[Double]
  gradient_y : Array[Double]
  alignment : Array[Double]
}

///|
pub(all) struct Divergence {
  value : Double
  gradient_x : Array[Double]
  gradient_y : Array[Double]
}

///|
pub(all) struct Fit {
  prototype : Series
  objective : Array[Double]
  accepted_steps : Int32
}

///|
fn valid(s : Series) -> Bool {
  if s.count < 1 || s.count > 128 || s.dimensions < 1 || s.dimensions > 8 {
    return false
  }
  if s.values.length() != s.count * s.dimensions {
    return false
  }
  for x in s.values {
    if x != x || x < -10000.0 || x > 10000.0 {
      return false
    }
  }
  true
}

///|
fn predecessor_weights(
  a : Double,
  b : Double,
  c : Double,
  gamma : Double,
) -> (Double, Double, Double, Double) {
  let mut smallest = a
  if b < smallest {
    smallest = b
  }
  if c < smallest {
    smallest = c
  }
  let wa = @math.exp((smallest - a) / gamma)
  let wb = @math.exp((smallest - b) / gamma)
  let wc = @math.exp((smallest - c) / gamma)
  let z = wa + wb + wc
  (smallest - gamma * @math.ln(z), wa / z, wb / z, wc / z)
}

///|
pub fn soft_dtw(
  x : Series,
  y : Series,
  gamma : Double,
) -> Result[Evaluation, String] {
  if !valid(x) || !valid(y) || x.dimensions != y.dimensions {
    return Err("nonempty, bounded series with matching dimensions required")
  }
  if gamma != gamma || gamma <= 0.0 || gamma > 10000.0 {
    return Err("gamma must be finite and in (0, 10000]")
  }
  let n = x.count
  let m = y.count
  let d = x.dimensions
  let stride = m + 1
  let r = Array::make((n + 1) * stride, @double.infinity)
  r[0] = 0.0
  for i = 1; i <= n; i = i + 1 {
    for j = 1; j <= m; j = j + 1 {
      let mut local_cost = 0.0
      for k = 0; k < d; k = k + 1 {
        let delta = x.values[(i - 1) * d + k] - y.values[(j - 1) * d + k]
        local_cost = local_cost + delta * delta
      }
      let (v, _, _, _) = predecessor_weights(
        r[(i - 1) * stride + j],
        r[i * stride + j - 1],
        r[(i - 1) * stride + j - 1],
        gamma,
      )
      r[i * stride + j] = local_cost + v
    }
  }
  // Reverse differentiation of the stable forward recurrence. This is not
  // the paper's padded reverse recurrence, avoiding infinity subtraction.
  let adjoint = Array::make((n + 1) * stride, 0.0)
  adjoint[n * stride + m] = 1.0
  let alignment = Array::make(n * m, 0.0)
  let gx = Array::make(n * d, 0.0)
  let gy = Array::make(m * d, 0.0)
  for i = n; i >= 1; i = i - 1 {
    for j = m; j >= 1; j = j - 1 {
      let a = adjoint[i * stride + j]
      alignment[(i - 1) * m + j - 1] = a
      let (_, wa, wb, wc) = predecessor_weights(
        r[(i - 1) * stride + j],
        r[i * stride + j - 1],
        r[(i - 1) * stride + j - 1],
        gamma,
      )
      adjoint[(i - 1) * stride + j] += a * wa
      adjoint[i * stride + j - 1] += a * wb
      adjoint[(i - 1) * stride + j - 1] += a * wc
      for k = 0; k < d; k = k + 1 {
        let xi = (i - 1) * d + k
        let yj = (j - 1) * d + k
        let grad = 2.0 * a * (x.values[xi] - y.values[yj])
        gx[xi] += grad
        gy[yj] -= grad
      }
    }
  }
  Ok({ value: r[n * stride + m], gradient_x: gx, gradient_y: gy, alignment, })
}

///|
pub fn divergence(
  x : Series,
  y : Series,
  gamma : Double,
) -> Result[Divergence, String] {
  let xy = match soft_dtw(x, y, gamma) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let xx = match soft_dtw(x, x, gamma) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let yy = match soft_dtw(y, y, gamma) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let gx = Array::make(x.values.length(), 0.0)
  let gy = Array::make(y.values.length(), 0.0)
  for k = 0; k < gx.length(); k = k + 1 {
    gx[k] = xy.gradient_x[k] - 0.5 * (xx.gradient_x[k] + xx.gradient_y[k])
  }
  for k = 0; k < gy.length(); k = k + 1 {
    gy[k] = xy.gradient_y[k] - 0.5 * (yy.gradient_x[k] + yy.gradient_y[k])
  }
  Ok({
    value: xy.value - 0.5 * xx.value - 0.5 * yy.value,
    gradient_x: gx,
    gradient_y: gy,
  })
}

///|
fn objective(
  seed : Series,
  examples : Array[Series],
  gamma : Double,
) -> Result[(Double, Array[Double]), String] {
  if examples.is_empty() || examples.length() > 16 {
    return Err("the experiment accepts 1..16 examples")
  }
  let gradient = Array::make(seed.values.length(), 0.0)
  let mut value = 0.0
  let scale = 1.0 / examples.length().to_double()
  for example in examples {
    let r = match divergence(seed, example, gamma) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    value += scale * r.value
    for k = 0; k < gradient.length(); k = k + 1 {
      gradient[k] += scale * r.gradient_x[k]
    }
  }
  Ok((value, gradient))
}

///|
/// A bounded descent experiment. Accepted steps improve the computed objective;
/// the result is not a certificate of a globally optimal prototype.
pub fn fit(
  seed : Series,
  examples : Array[Series],
  gamma : Double,
  steps : Int32,
) -> Result[Fit, String] {
  if steps < 0 || steps > 100 {
    return Err("the experiment accepts 0..100 steps")
  }
  let mut state = seed
  let mut current = match objective(state, examples, gamma) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let history = [current.0]
  let mut accepted_steps = 0
  for iteration = 0; iteration < steps; iteration = iteration + 1 {
    let mut norm2 = 0.0
    for g in current.1 {
      norm2 += g * g
    }
    if norm2 < 1.0e-16 {
      break
    }
    let mut rate = 1.0
    let mut improved = false
    for attempt = 0; attempt < 24; attempt = attempt + 1 {
      let values = Array::make(state.values.length(), 0.0)
      for k = 0; k < values.length(); k = k + 1 {
        values[k] = state.values[k] - rate * current.1[k]
      }
      let candidate = { ..state, values, }
      match objective(candidate, examples, gamma) {
        Ok(next) =>
          if next.0 <= current.0 - 1.0e-4 * rate * norm2 {
            state = candidate
            current = next
            history.push(next.0)
            accepted_steps += 1
            improved = true
            break
          }
        Err(_) => ()
      }
      rate *= 0.5
    }
    if !improved {
      break
    }
  }
  Ok({ prototype: state, objective: history, accepted_steps, })
}
