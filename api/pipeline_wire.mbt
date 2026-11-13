///|
fn bool_option(
  fields : Map[String, Json],
  key : String,
  fallback : Bool,
) -> Bool raise WireError {
  match fields.get(key) {
    Some(True) => true
    Some(False) => false
    Some(_) => {
      invalid("json_type", "options." + key + " must be boolean")
      abort("unreachable")
    }
    None => fallback
  }
}

///|
fn preprocessing(
  fields : Map[String, Json],
) -> @warpfit.PreprocessOptions raise WireError {
  {
    target_count: integer_option(fields, "target_count", 0),
    normalize: bool_option(fields, "normalize", true),
    epsilon: numeric_option(fields, "epsilon", 1.0e-12),
  }
}

///|
fn prepared_json(value : @warpfit.PreparedSeries) -> Json {
  let constants : Array[Json] = []
  for is_constant in value.constant_features {
    constants.push(Json::boolean(is_constant))
  }
  {
    "series": matrix(
      value.series.values,
      value.series.count,
      value.series.dimensions,
    ),
    "normalized": Json::boolean(value.normalized),
    "means": numbers(value.means),
    "standard_deviations": numbers(value.standard_deviations),
    "constant_features": Json::array(constants),
  }
}

///|
fn preprocess_one(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let input = raw_series(required(fields, "series"), "series")
  let result = from_result(
    @warpfit.prepare_series(input, preprocessing(options)),
  )
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "preprocess",
    "prepared": prepared_json(result),
  }
}

///|
fn pipeline_parameters(
  options : Map[String, Json],
) -> @warpfit.PipelineOptions raise WireError {
  {
    preprocessing: preprocessing(options),
    clustering: {
      alignment: hard_alignment(options),
      max_iterations: integer_option(options, "max_iterations", 20),
      max_dba_steps: integer_option(options, "max_dba_steps", 20),
      tolerance: numeric_option(options, "tolerance", 1.0e-8),
      max_work_units: integer_option(options, "max_work_units", 20000000),
    },
  }
}

///|
fn prepared_items_json(items : Array[@warpfit.PreparedSeries]) -> Json {
  let prepared : Array[Json] = []
  for item in items {
    prepared.push(prepared_json(item))
  }
  Json::array(prepared)
}

///|
fn clustering_json(group : @warpfit.ClusterFit) -> Json {
  let centers : Array[Json] = []
  for center in group.centers {
    centers.push(matrix(center.values, center.count, center.dimensions))
  }
  let labels : Array[Json] = []
  for label in group.labels {
    labels.push(Json::number(label.to_double()))
  }
  {
    "centers": Json::array(centers),
    "labels": Json::array(labels),
    "inertia": Json::number(group.inertia),
    "history": numbers(group.history),
    "iterations": Json::number(group.iterations.to_double()),
    "stop": Json::string(group.stop),
    "work_units": Json::number(group.work_units.to_double()),
  }
}

///|
fn pipeline_cluster(
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
    @warpfit.prepare_and_cluster(data, seeds, pipeline_parameters(options)),
  )
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "pipeline",
    "prepared": prepared_items_json(result.prepared),
    "clustering": clustering_json(result.clustering),
  }
}
