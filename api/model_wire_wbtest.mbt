///|
test "serialized cluster model predicts new samples without enforcing nonempty clusters" {
  let trained = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"train_model\",\"data\":[[0],[2],[9],[11]],\"seed_indices\":[0,3],\"options\":{\"normalize\":false}}",
  )
  let model = trained.get("model").unwrap()
  let prediction : Json = {
    "schema": "warpfit.request/1",
    "operation": "predict",
    "model": model,
    "data": [[0], [2]],
  }
  let out = response(prediction.stringify())
  let labels : Array[Int32] = @json.from_json(out.get("labels").unwrap())
  assert_eq(labels, [0, 0])
  let distances : Array[Double] = @json.from_json(out.get("distances").unwrap())
  assert_true((distances[0] - 1.0).abs() < 1.0e-10)
  assert_true((distances[1] - 1.0).abs() < 1.0e-10)
}

///|
test "model JSON rejects unsupported versions and incomplete budgets" {
  let bad_version = "{\"schema\":\"warpfit.request/1\",\"operation\":\"predict\",\"model\":{\"schema\":\"warpfit.cluster-model/2\"},\"data\":[[0]]}"
  assert_eq(error_code(bad_version), "model_version")
  let budget = "{\"schema\":\"warpfit.request/1\",\"operation\":\"predict\",\"model\":{\"schema\":\"warpfit.cluster-model/1\",\"centers\":[[0],[10]],\"preprocessing\":{\"target_count\":0,\"normalize\":false,\"epsilon\":0.0},\"alignment\":{\"window\":null,\"feature_weights\":[],\"max_cells\":262144}},\"data\":[[1]],\"options\":{\"max_work_units\":1}}"
  assert_eq(error_code(budget), "work_budget")
}

///|
test "automatic model training returns deterministic seeds and total budget" {
  let result = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"auto_train_model\",\"data\":[[0],[2],[9],[11]],\"cluster_count\":2,\"options\":{\"normalize\":false}}",
  )
  let seeds : Array[Int32] = @json.from_json(
    result.get("seed_indices").unwrap(),
  )
  assert_eq(seeds, [0, 3])
  let units : Int32 = @json.from_json(result.get("seed_work_units").unwrap())
  assert_eq(units, 3)
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"auto_train_model\",\"data\":[[0],[2]],\"cluster_count\":2,\"options\":{\"normalize\":false,\"max_work_units\":1}}",
    ),
    "work_budget",
  )
}
