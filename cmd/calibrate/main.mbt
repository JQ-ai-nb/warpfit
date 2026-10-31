///|
/// A small external-model example: y_hat[t] = gain * sensor[t] + offset.
/// The model parameters are outside WarpFit. Its input gradient supplies the
/// chain rule even when prediction and target have different sample counts.
fn objective(
  sensor : Array[Double],
  gain : Double,
  offset : Double,
  target : @warpfit.Series,
) -> @warpfit.Divergence {
  let prediction : @warpfit.Series = {
    count: sensor.length(),
    dimensions: 1,
    values: sensor.map(v => gain * v + offset),
  }
  @warpfit.divergence(prediction, target, 0.3).unwrap()
}

///|
fn model_gradient(
  sensor : Array[Double],
  result : @warpfit.Divergence,
) -> (Double, Double) {
  let mut gain_gradient = 0.0
  let mut offset_gradient = 0.0
  for i, v in result.gradient_x {
    gain_gradient += v * sensor[i]
    offset_gradient += v
  }
  (gain_gradient, offset_gradient)
}

///|
fn main raise {
  let sensor = [0.0, 0.4, 0.8, 1.0, 0.3, 0.0]
  let target : @warpfit.Series = {
    count: 4,
    dimensions: 1,
    values: [0.0, 1.2, 0.7, 0.0],
  }
  let mut gain = 0.5
  let mut offset = 0.6
  let mut result = objective(sensor, gain, offset, target)
  let initial = result.value
  for _iteration = 0; _iteration < 80; _iteration = _iteration + 1 {
    let (dg, db) = model_gradient(sensor, result)
    let mut step = 0.1
    for _attempt = 0; _attempt < 20; _attempt = _attempt + 1 {
      let next = objective(sensor, gain - step * dg, offset - step * db, target)
      if next.value <= result.value {
        gain -= step * dg
        offset -= step * db
        result = next
        break
      }
      step *= 0.5
    }
  }
  assert_true(result.value < initial)
  println("calibration_initial=\{initial}")
  println("calibration_final=\{result.value}")
  println("gain=\{gain}")
  println("offset=\{offset}")
}
