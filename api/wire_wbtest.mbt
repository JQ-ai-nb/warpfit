///|
fn response(source : String) -> Map[String, Json] raise {
  let encoded = run(source)
  match @json.parse(encoded[:]) {
    Object(fields) => fields
    _ => abort("response must be an object")
  }
}

///|
fn error_code(source : String) -> String raise {
  let fields = response(source)
  match fields.get("ok").unwrap() {
    False => ()
    _ => abort("expected failure")
  }
  match fields.get("error").unwrap() {
    Object(error) => @json.from_json(error.get("code").unwrap())
    _ => abort("expected error object")
  }
}

///|
test "wire contract keeps raw and corrected objectives distinct" {
  let raw = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"objective\":\"raw\",\"x\":[0,1],\"y\":[0,1],\"options\":{\"gamma\":1}}",
  )
  let value : Double = @json.from_json(raw.get("value").unwrap())
  assert_true(value < -0.55 && value > -0.56)
  let corrected = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[0,1],\"y\":[0,1],\"options\":{\"gamma\":1}}",
  )
  let value : Double = @json.from_json(corrected.get("value").unwrap())
  assert_true(value.abs() < 1.0e-12)
  let gx : Array[Array[Double]] = @json.from_json(
    corrected.get("gradient_x").unwrap(),
  )
  assert_eq(gx.length(), 2)
  assert_eq(gx[0].length(), 1)
}

///|
test "unknown top-level and nested options are rejected" {
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[0],\"y\":[0],\"noise\":1}",
    ),
    "unknown_field",
  )
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[0],\"y\":[0],\"options\":{\"gama\":1}}",
    ),
    "unknown_field",
  )
}

///|
test "duplicate JSON keys are not silently overwritten" {
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[0],\"x\":[1],\"y\":[0]}",
    ),
    "json",
  )
}

///|
test "integer controls preserve lexical representation" {
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"fit\",\"seed\":[1],\"examples\":[[0]],\"options\":{\"max_steps\":1.0000000000000000001}}",
    ),
    "integer",
  )
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"fit\",\"seed\":[1],\"examples\":[[0]],\"options\":{\"max_steps\":1e1}}",
    ),
    "integer",
  )
}

///|
test "series reject ragged rows mixed dimensions and missing data" {
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[[0,1],[2]],\"y\":[[0,1]]}",
    ),
    "series_shape",
  )
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[0,[1]],\"y\":[0]}",
    ),
    "json_type",
  )
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[],\"y\":[0]}",
    ),
    "series_shape",
  )
}

///|
test "version operation and nonfinite lexical input fail explicitly" {
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/2\",\"operation\":\"loss\",\"x\":[0],\"y\":[0]}",
    ),
    "schema",
  )
  assert_eq(
    error_code("{\"schema\":\"warpfit.request/1\",\"operation\":\"train\"}"),
    "operation",
  )
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"loss\",\"x\":[1e999],\"y\":[0]}",
    ),
    "number",
  )
}

///|
test "fit response exposes evaluated stopping reason and history" {
  let r = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"fit\",\"seed\":[2],\"examples\":[[0]],\"options\":{\"max_evaluations\":1}}",
  )
  let stop : String = @json.from_json(r.get("stop").unwrap())
  let evaluations : Int32 = @json.from_json(r.get("evaluations").unwrap())
  let history : Array[Double] = @json.from_json(r.get("history").unwrap())
  assert_eq(stop, "evaluation_budget")
  assert_eq(evaluations, 1)
  assert_eq(history.length(), 1)
}

///|
test "ranking checks nested candidate fields and returns ranked ids" {
  let r = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"rank\",\"query\":[0],\"candidates\":[{\"id\":\"far\",\"series\":[2]},{\"id\":\"near\",\"series\":[0]}]}",
  )
  let rows : Array[Json] = @json.from_json(r.get("matches").unwrap())
  match rows[0] {
    Object(fields) => {
      let id : String = @json.from_json(fields.get("id").unwrap())
      assert_eq(id, "near")
    }
    _ => abort("expected ranking object")
  }
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"rank\",\"query\":[0],\"candidates\":[{\"id\":\"one\",\"series\":[0],\"weight\":1}]}",
    ),
    "unknown_field",
  )
}

///|
test "hard DTW JSON returns path and respects a zero-width band" {
  let out = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"dtw\",\"x\":[0,0,1,2],\"y\":[0,1,2,2],\"options\":{\"window\":0}}",
  )
  let distance : Double = @json.from_json(out.get("distance").unwrap())
  let path : Array[Array[Int32]] = @json.from_json(out.get("path").unwrap())
  assert_true((distance - 2.0.sqrt()).abs() < 1.0e-10)
  assert_eq(path.length(), 4)
  assert_eq(path[3], [3, 3])
}

///|
test "DBA JSON returns weighted prototype and explicit budget stop" {
  let out = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"dba\",\"seed\":[10],\"examples\":[[0],[4]],\"options\":{\"example_weights\":[3,1]}}",
  )
  let prototype : Array[Array[Double]] = @json.from_json(
    out.get("prototype").unwrap(),
  )
  assert_true((prototype[0][0] - 1.0).abs() < 1.0e-10)
  let limited = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"dba\",\"seed\":[2],\"examples\":[[0]],\"options\":{\"max_work_units\":1}}",
  )
  let stop : String = @json.from_json(limited.get("stop").unwrap())
  assert_eq(stop, "work_budget")
}

///|
test "clustering JSON exposes real labels, centroids and empty-cluster error" {
  let out = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"cluster\",\"data\":[[0],[2],[9],[11]],\"centers\":[[0],[10]]}",
  )
  let labels : Array[Int32] = @json.from_json(out.get("labels").unwrap())
  let centers : Array[Array[Array[Double]]] = @json.from_json(
    out.get("centers").unwrap(),
  )
  assert_eq(labels, [0, 0, 1, 1])
  assert_true((centers[0][0][0] - 1.0).abs() < 1.0e-10)
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"cluster\",\"data\":[[0],[0]],\"centers\":[[0],[0]]}",
    ),
    "empty_cluster",
  )
}

///|
test "new operations reject unrelated options and non-integer windows" {
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"dtw\",\"x\":[0],\"y\":[0],\"options\":{\"window\":1.5}}",
    ),
    "integer",
  )
  assert_eq(
    error_code(
      "{\"schema\":\"warpfit.request/1\",\"operation\":\"cluster\",\"data\":[[0]],\"centers\":[[0]],\"options\":{\"gamma\":0.5}}",
    ),
    "unknown_field",
  )
}
