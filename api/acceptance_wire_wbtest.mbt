///|
fn response_text(fields : Map[String, Json], key : String) -> String raise {
  @json.from_json(fields.get(key).unwrap())
}

///|
test "wire exposes pruned knn with its search counters" {
  let fields = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"knn_pruned\",\"query\":[0,1,0],\"training\":[{\"label\":\"a\",\"series\":[0,1,0]},{\"label\":\"b\",\"series\":[0,0,1]}],\"options\":{\"k\":1,\"window\":1}}",
  )
  assert_eq(response_text(fields, "operation"), "knn_pruned")
  assert_eq(response_text(fields, "label"), "a")
  let checks : Double = @json.from_json(
    fields.get("lower_bound_checks").unwrap(),
  )
  let calls : Double = @json.from_json(
    fields.get("full_distance_calls").unwrap(),
  )
  assert_eq(checks, 2.0)
  assert_true(calls >= 1.0 && calls <= 2.0)
}

///|
test "wire exposes top-k subsequence matches" {
  let fields = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"subsequence_topk\",\"query\":[0,1,0],\"target\":[9,9,0,1,0,9,9],\"top_k\":2}",
  )
  assert_eq(response_text(fields, "operation"), "subsequence_topk")
  let matches : Array[Json] = @json.from_json(fields.get("matches").unwrap())
  assert_true(matches.length() >= 1)
  match matches[0] {
    Object(first) => {
      let start : Double = @json.from_json(first.get("start").unwrap())
      let end : Double = @json.from_json(first.get("end").unwrap())
      assert_eq(start, 2.0)
      assert_eq(end, 4.0)
    }
    _ => assert_true(false)
  }
}

///|
test "wire exposes cross-validation metrics" {
  let fields = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"cross_validate\",\"data\":[[0,0,0],[0,0.1,0],[5,5,5],[5,5.1,5]],\"labels\":[\"a\",\"a\",\"b\",\"b\"],\"options\":{\"k\":1,\"folds\":2}}",
  )
  assert_eq(response_text(fields, "operation"), "cross_validate")
  let accuracy : Double = @json.from_json(fields.get("accuracy").unwrap())
  assert_true((accuracy - 1.0).abs() <= 1.0e-12)
  let confusion : Array[Array[Double]] = @json.from_json(
    fields.get("confusion").unwrap(),
  )
  assert_eq(confusion.length(), 2)
  assert_eq(confusion[0][0], 2.0)
  assert_eq(confusion[1][1], 2.0)
  let labels : Array[String] = @json.from_json(fields.get("labels").unwrap())
  assert_eq(labels.length(), 2)
}

///|
test "wire exposes medoids and their sample indices" {
  let fields = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"medoids\",\"data\":[[0,0,0],[0,0.1,0],[5,5,5],[5,5.1,5]],\"cluster_count\":2}",
  )
  assert_eq(response_text(fields, "operation"), "medoids")
  let medoids : Array[Double] = @json.from_json(
    fields.get("medoid_indices").unwrap(),
  )
  let labels : Array[Double] = @json.from_json(fields.get("labels").unwrap())
  assert_eq(medoids.length(), 2)
  assert_eq(labels.length(), 4)
  let cost : Double = @json.from_json(fields.get("cost").unwrap())
  assert_true(cost >= 0.0)
}

///|
test "wire exposes motif pairs" {
  let fields = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"motifs\",\"series\":[0,1,0,9,9,0,1,0],\"window\":3,\"top_k\":1}",
  )
  assert_eq(response_text(fields, "operation"), "motifs")
  let pairs : Array[Json] = @json.from_json(fields.get("pairs").unwrap())
  assert_eq(pairs.length(), 1)
  match pairs[0] {
    Object(first) => {
      let start : Double = @json.from_json(first.get("first_start").unwrap())
      let second : Double = @json.from_json(first.get("second_start").unwrap())
      assert_eq(start, 0.0)
      assert_eq(second, 5.0)
    }
    _ => assert_true(false)
  }
}

///|
test "wire exposes outlier scores" {
  let fields = response(
    "{\"schema\":\"warpfit.request/1\",\"operation\":\"outliers\",\"data\":[[0,0,0],[0,0.1,0],[9,9,9]],\"options\":{\"k\":1}}",
  )
  assert_eq(response_text(fields, "operation"), "outliers")
  let scores : Array[Json] = @json.from_json(fields.get("scores").unwrap())
  assert_eq(scores.length(), 3)
  let isolated : Map[String, Json] = match scores[2] {
    Object(value) => value
    _ => abort("expected score object")
  }
  let score : Double = @json.from_json(isolated.get("score").unwrap())
  assert_true(score > 0.0)
}
