///|
test "public input gradient trains a separate affine model via chain rule" {
  let sensor = [0.1, 0.7, 1.2, 0.0]
  let target : @warpfit.Series = {
    count: 3,
    dimensions: 1,
    values: [0.0, 1.0, 0.0],
  }
  let gain = 0.8
  let offset = 0.2
  let result = objective(sensor, gain, offset, target)
  let (dg, db) = model_gradient(sensor, result)
  let h = 1.0e-5
  let finite_g = (
      objective(sensor, gain + h, offset, target).value -
      objective(sensor, gain - h, offset, target).value
    ) /
    (2.0 * h)
  let finite_b = (
      objective(sensor, gain, offset + h, target).value -
      objective(sensor, gain, offset - h, target).value
    ) /
    (2.0 * h)
  assert_true((finite_g - dg).abs() < 1.0e-6)
  assert_true((finite_b - db).abs() < 1.0e-6)
  let next = objective(sensor, gain - 0.01 * dg, offset - 0.01 * db, target)
  assert_true(next.value < result.value)
}
