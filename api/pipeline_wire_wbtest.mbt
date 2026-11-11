///|
test "preprocess JSON returns resampled values without implicit normalization" {
  let out = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"preprocess\",\"series\":[1,2,3],\"options\":{\"target_count\":5,\"normalize\":false}}",
  )
  let prep : Map[String, Json] = @json.from_json(out.get("prepared").unwrap())
  let values : Array[Array[Double]] = @json.from_json(
    prep.get("series").unwrap(),
  )
  assert_eq(values.length(), 5)
  assert_true((values[1][0] - 1.5).abs() < 1.0e-12)
  let normalized : Bool = @json.from_json(prep.get("normalized").unwrap())
  assert_true(!normalized)
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"preprocess\",\"series\":[0],\"options\":{\"normalize\":1}}",
    ),
    "json_type",
  )
}

///|
test "pipeline JSON normalizes and clusters differently scaled inputs" {
  let out = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"pipeline\",\"data\":[[2,4,6],[100,200,300,400,500],[6,4,2],[500,400,300,200,100]],\"seed_indices\":[0,2],\"options\":{\"target_count\":5,\"window\":0}}",
  )
  let cluster : Map[String, Json] = @json.from_json(
    out.get("clustering").unwrap(),
  )
  let labels : Array[Int32] = @json.from_json(cluster.get("labels").unwrap())
  assert_eq(labels, [0, 0, 1, 1])
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"pipeline\",\"data\":[[1,2],[2,1]],\"seed_indices\":[0,0]}",
    ),
    "seed_indices",
  )
}
