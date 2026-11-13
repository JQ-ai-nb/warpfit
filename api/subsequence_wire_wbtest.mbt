///|
test "subsequence JSON returns the inclusive interval and complete path" {
  let out = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"subsequence\",\"query\":[0,1,0],\"target\":[9,9,0,1,0,9,9]}",
  )
  let start : Int32 = @json.from_json(out.get("start").unwrap())
  let end : Int32 = @json.from_json(out.get("end").unwrap())
  let distance : Double = @json.from_json(out.get("distance").unwrap())
  assert_eq(start, 2)
  assert_eq(end, 4)
  assert_true(distance.abs() < 1.0e-12)
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"subsequence\",\"query\":[0],\"target\":[0],\"options\":{\"window\":0}}",
    ),
    "unknown_field",
  )
}
