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
  let params : @warpfit.PipelineOptions = {
    preprocessing: preprocessing(options),
    clustering: {
      alignment: hard_alignment(options),
      max_iterations: integer_option(options, "max_iterations", 20),
      max_dba_steps: integer_option(options, "max_dba_steps", 20),
      tolerance: numeric_option(options, "tolerance", 1.0e-8),
      max_work_units: integer_option(options, "max_work_units", 20000000),
    },
  }
  let result = from_result(@warpfit.prepare_and_cluster(data, seeds, params))
  let prepared : Array[Json] = []
  for item in result.prepared {
    prepared.push(prepared_json(item))
  }
  let centers : Array[Json] = []
  for center in result.clustering.centers {
    centers.push(matrix(center.values, center.count, center.dimensions))
  }
  let labels : Array[Json] = []
  for label in result.clustering.labels {
    labels.push(Json::number(label.to_double()))
  }
  let clustering : Json = {
    "centers": Json::array(centers),
    "labels": Json::array(labels),
    "inertia": Json::number(result.clustering.inertia),
    "history": numbers(result.clustering.history),
    "iterations": Json::number(result.clustering.iterations.to_double()),
    "stop": Json::string(result.clustering.stop),
    "work_units": Json::number(result.clustering.work_units.to_double()),
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "pipeline",
    "prepared": Json::array(prepared),
    "clustering": clustering,
  }
}
