///|
fn model_json(model : @warpfit.ClusterModel) -> Json {
  let centers : Array[Json] = []
  for center in model.centers {
    centers.push(matrix(center.values, center.count, center.dimensions))
  }
  let window = if model.alignment.window < 0 {
    Json::null()
  } else {
    Json::number(model.alignment.window.to_double())
  }
  {
    "schema": "warpfit.cluster-model/1",
    "centers": Json::array(centers),
    "preprocessing": {
      "target_count": Json::number(model.preprocessing.target_count.to_double()),
      "normalize": Json::boolean(model.preprocessing.normalize),
      "epsilon": Json::number(model.preprocessing.epsilon),
    },
    "alignment": {
      "window": window,
      "feature_weights": numbers(model.alignment.feature_weights),
      "max_cells": Json::number(model.alignment.max_cells.to_double()),
    },
  }
}

///|
fn parse_model(value : Json) -> @warpfit.ClusterModel raise WireError {
  let model = object(value, "model", [
    "schema", "centers", "preprocessing", "alignment",
  ])
  if text(required(model, "schema"), "model.schema") !=
    "warpfit.cluster-model/1" {
    invalid("model_version", "unsupported cluster model schema")
  }
  let centers : Array[@warpfit.Series] = []
  for value in array(required(model, "centers"), "model.centers", 16) {
    centers.push(series(value, "model.centers[]"))
  }
  let prep = object(required(model, "preprocessing"), "model.preprocessing", [
    "target_count", "normalize", "epsilon",
  ])
  let normalized = match required(prep, "normalize") {
    True => true
    False => false
    _ => {
      invalid("json_type", "model.preprocessing.normalize must be boolean")
      abort("unreachable")
    }
  }
  let preprocessing : @warpfit.PreprocessOptions = {
    target_count: integer(
      required(prep, "target_count"),
      "model.preprocessing.target_count",
    ),
    normalize: normalized,
    epsilon: number(required(prep, "epsilon"), "model.preprocessing.epsilon"),
  }
  let alignment = object(required(model, "alignment"), "model.alignment", [
    "window", "feature_weights", "max_cells",
  ])
  let window = match required(alignment, "window") {
    Null => -1
    other => integer(other, "model.alignment.window")
  }
  let settings : @warpfit.DtwOptions = {
    window,
    feature_weights: number_array(
      required(alignment, "feature_weights"),
      "model.alignment.feature_weights",
      16,
    ),
    max_cells: integer(
      required(alignment, "max_cells"),
      "model.alignment.max_cells",
    ),
  }
  { version: 1, centers, preprocessing, alignment: settings, }
}

///|
fn train_model(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let data : Array[@warpfit.Series] = []
  for value in array(required(fields, "data"), "data", 32) {
    data.push(raw_series(value, "data[]"))
  }
  let seeds : Array[Int32] = []
  for value in array(required(fields, "seed_indices"), "seed_indices", 16) {
    seeds.push(integer(value, "seed_indices[]"))
  }
  let result = from_result(
    @warpfit.train_cluster_model(data, seeds, pipeline_parameters(options)),
  )
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "train_model",
    "model": model_json(result.model),
    "prepared": prepared_items_json(result.training.prepared),
    "clustering": clustering_json(result.training.clustering),
  }
}

///|
fn auto_train_model(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let data : Array[@warpfit.Series] = []
  for value in array(required(fields, "data"), "data", 32) {
    data.push(raw_series(value, "data[]"))
  }
  let count = integer(required(fields, "cluster_count"), "cluster_count")
  let first = match fields.get("first_index") {
    Some(value) => integer(value, "first_index")
    None => 0
  }
  let result = from_result(
    @warpfit.train_cluster_model_auto(
      data,
      count,
      first,
      pipeline_parameters(options),
    ),
  )
  let seeds : Array[Json] = []
  for index in result.seed_indices {
    seeds.push(Json::number(index.to_double()))
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "auto_train_model",
    "model": model_json(result.fitted.model),
    "prepared": prepared_items_json(result.fitted.training.prepared),
    "clustering": clustering_json(result.fitted.training.clustering),
    "seed_indices": Json::array(seeds),
    "seed_work_units": Json::number(result.seed_work_units.to_double()),
    "total_work_units": Json::number(result.total_work_units.to_double()),
  }
}

///|
fn predict_model(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let model = parse_model(required(fields, "model"))
  let data : Array[@warpfit.Series] = []
  for value in array(required(fields, "data"), "data", 32) {
    data.push(raw_series(value, "data[]"))
  }
  let result = from_result(
    @warpfit.predict_clusters(
      model,
      data,
      integer_option(options, "max_work_units", 20000000),
    ),
  )
  let labels : Array[Json] = []
  for label in result.labels {
    labels.push(Json::number(label.to_double()))
  }
  let rows : Array[Json] = []
  for row in result.distances_to_centers {
    rows.push(numbers(row))
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "predict",
    "prepared": prepared_items_json(result.prepared),
    "labels": Json::array(labels),
    "distances": numbers(result.distances),
    "distances_to_centers": Json::array(rows),
    "work_units": Json::number(result.work_units.to_double()),
  }
}
