///|
suberror WireError {
  WireError(String, String)
}

///|
fn invalid(code : String, message : String) -> Unit raise WireError {
  raise WireError(code, message)
}

///|
fn object(
  value : Json,
  path : String,
  allowed : Array[String],
) -> Map[String, Json] raise WireError {
  let fields = match value {
    Object(v) => v
    _ => {
      invalid("json_type", path + " must be an object")
      abort("unreachable")
    }
  }
  for key in fields.keys() {
    if !allowed.contains(key) {
      invalid("unknown_field", path + " contains an unsupported field: " + key)
    }
  }
  fields
}

///|
fn required(fields : Map[String, Json], key : String) -> Json raise WireError {
  match fields.get(key) {
    Some(v) => v
    None => {
      invalid("missing_field", "missing required field: " + key)
      abort("unreachable")
    }
  }
}

///|
fn text(value : Json, path : String) -> String raise WireError {
  match value {
    String(s) => s
    _ => {
      invalid("json_type", path + " must be text")
      abort("unreachable")
    }
  }
}

///|
fn number(value : Json, path : String) -> Double raise WireError {
  match value {
    Number(x, ..) => {
      if x != x || x > 1.0e100 || x < -1.0e100 {
        invalid("number", path + " must be a bounded finite number")
      }
      x
    }
    _ => {
      invalid("json_type", path + " must be numeric")
      abort("unreachable")
    }
  }
}

///|
fn integer(value : Json, path : String) -> Int32 raise WireError {
  match value {
    Number(x, repr~) => {
      if x < 0.0 || x > 100000000.0 || x != x || x.to_int().to_double() != x {
        invalid(
          "integer",
          path + " must be a nonnegative integer within 100000000",
        )
      }
      match repr {
        Some(raw) =>
          for c in raw {
            if c < '0' || c > '9' {
              invalid("integer", path + " requires a plain integer token")
            }
          }
        None => ()
      }
      x.to_int()
    }
    _ => {
      invalid("integer", path + " must be an integer")
      abort("unreachable")
    }
  }
}

///|
fn array(
  value : Json,
  path : String,
  limit : Int32,
) -> Array[Json] raise WireError {
  match value {
    Array(v) => {
      if v.length() > limit {
        invalid("array_limit", path + " exceeds its item limit")
      }
      v
    }
    _ => {
      invalid("json_type", path + " must be an array")
      abort("unreachable")
    }
  }
}

///|
fn number_array(
  value : Json,
  path : String,
  limit : Int32,
) -> Array[Double] raise WireError {
  let values = array(value, path, limit)
  let out = []
  for v in values {
    out.push(number(v, path))
  }
  out
}

///|
fn series(value : Json, path : String) -> @warpfit.Series raise WireError {
  let rows = array(value, path, 512)
  if rows.is_empty() {
    invalid("series_shape", path + " must not be empty")
  }
  let mut dimensions = 1
  let data : Array[Double] = []
  match rows[0] {
    Array(first) => {
      dimensions = first.length()
      if dimensions < 1 || dimensions > 16 {
        invalid("series_shape", path + " needs 1..16 features")
      }
      for row in rows {
        let values = number_array(row, path, 16)
        if values.length() != dimensions {
          invalid("series_shape", path + " has ragged feature rows")
        }
        for v in values {
          data.push(v)
        }
      }
    }
    _ =>
      for v in rows {
        data.push(number(v, path))
      }
  }
  let result : @warpfit.Series = {
    count: rows.length(),
    dimensions,
    values: data,
  }
  from_result(@warpfit.validate_series(result))
  result
}

///|
fn[T] from_result(value : Result[T, @warpfit.WarpError]) -> T raise WireError {
  match value {
    Ok(v) => v
    Err(e) => {
      invalid(e.code, e.message)
      abort("unreachable")
    }
  }
}

///|
fn numeric_option(
  fields : Map[String, Json],
  key : String,
  fallback : Double,
) -> Double raise WireError {
  match fields.get(key) {
    Some(v) => number(v, "options." + key)
    None => fallback
  }
}

///|
fn integer_option(
  fields : Map[String, Json],
  key : String,
  fallback : Int32,
) -> Int32 raise WireError {
  match fields.get(key) {
    Some(v) => integer(v, "options." + key)
    None => fallback
  }
}

///|
fn alignment(
  fields : Map[String, Json],
) -> @warpfit.AlignOptions raise WireError {
  {
    gamma: numeric_option(fields, "gamma", 0.5),
    feature_weights: match fields.get("feature_weights") {
      Some(v) => number_array(v, "options.feature_weights", 16)
      None => []
    },
    max_cells: integer_option(fields, "max_cells", 262144),
  }
}

///|
fn hard_alignment(
  fields : Map[String, Json],
) -> @warpfit.DtwOptions raise WireError {
  {
    window: integer_option(fields, "window", -1),
    feature_weights: match fields.get("feature_weights") {
      Some(v) => number_array(v, "options.feature_weights", 16)
      None => []
    },
    max_cells: integer_option(fields, "max_cells", 262144),
  }
}

///|
fn matrix(values : Array[Double], rows : Int32, columns : Int32) -> Json {
  let out : Array[Json] = []
  for i = 0; i < rows; i = i + 1 {
    let row : Array[Json] = []
    for j = 0; j < columns; j = j + 1 {
      row.push(Json::number(values[i * columns + j]))
    }
    out.push(Json::array(row))
  }
  Json::array(out)
}

///|
fn numbers(values : Array[Double]) -> Json {
  Json::array(values.map(fn(x) { Json::number(x) }))
}

///|
fn loss(
  fields : Map[String, Json],
  options : @warpfit.AlignOptions,
) -> Json raise WireError {
  let x = series(required(fields, "x"), "x")
  let y = series(required(fields, "y"), "y")
  let mode = match fields.get("objective") {
    Some(v) => text(v, "objective")
    None => "corrected"
  }
  let (value, gx, gy, occupancy, components) = if mode == "raw" {
    let r = from_result(@warpfit.soft_dtw_with(x, y, options))
    (r.value, r.gradient_x, r.gradient_y, r.alignment, Json::null())
  } else if mode == "corrected" {
    let r = from_result(@warpfit.divergence_with(x, y, options))
    let parts : Json = {
      "cross": Json::number(r.raw_cross),
      "self_x": Json::number(r.raw_self_x),
      "self_y": Json::number(r.raw_self_y),
    }
    (r.value, r.gradient_x, r.gradient_y, r.alignment, parts)
  } else {
    invalid("objective", "objective must be raw or corrected")
    abort("unreachable")
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "loss",
    "objective": Json::string(mode),
    "value": Json::number(value),
    "gradient_x": matrix(gx, x.count, x.dimensions),
    "gradient_y": matrix(gy, y.count, y.dimensions),
    "alignment": matrix(occupancy, x.count, y.count),
    "components": components,
  }
}

///|
fn fitting(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let seed = series(required(fields, "seed"), "seed")
  let examples = []
  for v in array(required(fields, "examples"), "examples", 32) {
    examples.push(series(v, "examples[]"))
  }
  let parameters : @warpfit.FitOptions = {
    alignment: alignment(options),
    max_steps: integer_option(options, "max_steps", 60),
    learning_rate: numeric_option(options, "learning_rate", 1.0),
    gradient_tolerance: numeric_option(options, "gradient_tolerance", 1.0e-8),
    improvement_tolerance: numeric_option(
      options, "improvement_tolerance", 1.0e-10,
    ),
    max_evaluations: integer_option(options, "max_evaluations", 512),
    max_work_units: integer_option(options, "max_work_units", 20000000),
    example_weights: match options.get("example_weights") {
      Some(v) => number_array(v, "options.example_weights", 32)
      None => []
    },
  }
  let r = from_result(@warpfit.fit_with(seed, examples, parameters))
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "fit",
    "objective": "corrected",
    "prototype": matrix(
      r.prototype.values,
      r.prototype.count,
      r.prototype.dimensions,
    ),
    "history": numbers(r.objective),
    "accepted_steps": Json::number(r.accepted_steps.to_double()),
    "stop": Json::string(r.stop),
    "evaluations": Json::number(r.evaluations.to_double()),
    "work_units": Json::number(r.work_units.to_double()),
    "gradient_norm": Json::number(r.gradient_norm),
  }
}

///|
fn ranking(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let query = series(required(fields, "query"), "query")
  let candidates : Array[@warpfit.Candidate] = []
  for v in array(required(fields, "candidates"), "candidates", 32) {
    let candidate = object(v, "candidates[]", ["id", "series"])
    candidates.push({
      id: text(required(candidate, "id"), "candidate.id"),
      series: series(required(candidate, "series"), "candidate.series"),
    })
  }
  let top_k = match fields.get("top_k") {
    Some(v) => integer(v, "top_k")
    None => candidates.length()
  }
  let r = from_result(
    @warpfit.rank_candidates(
      query,
      candidates,
      alignment(options),
      top_k,
      integer_option(options, "max_work_units", 20000000),
    ),
  )
  let matches : Array[Json] = []
  for row in r.matches {
    matches.push({
      "id": Json::string(row.id),
      "input_index": Json::number(row.input_index.to_double()),
      "value": Json::number(row.value),
      "raw_cross": Json::number(row.raw_cross),
      "raw_self_candidate": Json::number(row.raw_self_candidate),
    })
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "rank",
    "objective": "corrected",
    "matches": Json::array(matches),
    "raw_self_query": Json::number(r.raw_self_query),
    "work_units": Json::number(r.work_units.to_double()),
    "candidates_evaluated": Json::number(r.candidates_evaluated.to_double()),
  }
}

///|
fn hard_dtw(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let x = series(required(fields, "x"), "x")
  let y = series(required(fields, "y"), "y")
  let result = from_result(@warpfit.dtw_path(x, y, hard_alignment(options)))
  let path : Array[Json] = []
  for point in result.path {
    path.push(
      Json::array([
        Json::number(point.x_index.to_double()),
        Json::number(point.y_index.to_double()),
      ]),
    )
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "dtw",
    "distance": Json::number(result.distance),
    "squared_cost": Json::number(result.squared_cost),
    "path": Json::array(path),
    "visited_cells": Json::number(result.visited_cells.to_double()),
  }
}

///|
fn hard_dba(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let seed = series(required(fields, "seed"), "seed")
  let examples : Array[@warpfit.Series] = []
  for v in array(required(fields, "examples"), "examples", 32) {
    examples.push(series(v, "examples[]"))
  }
  let params : @warpfit.DbaOptions = {
    alignment: hard_alignment(options),
    max_steps: integer_option(options, "max_steps", 30),
    tolerance: numeric_option(options, "tolerance", 1.0e-8),
    max_work_units: integer_option(options, "max_work_units", 20000000),
    example_weights: match options.get("example_weights") {
      Some(v) => number_array(v, "options.example_weights", 32)
      None => []
    },
  }
  let result = from_result(@warpfit.dba_fit(seed, examples, params))
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "dba",
    "prototype": matrix(
      result.prototype.values,
      result.prototype.count,
      result.prototype.dimensions,
    ),
    "history": numbers(result.objective),
    "accepted_steps": Json::number(result.accepted_steps.to_double()),
    "stop": Json::string(result.stop),
    "evaluations": Json::number(result.evaluations.to_double()),
    "work_units": Json::number(result.work_units.to_double()),
  }
}

///|
fn hard_cluster(
  fields : Map[String, Json],
  options : Map[String, Json],
) -> Json raise WireError {
  let data : Array[@warpfit.Series] = []
  for v in array(required(fields, "data"), "data", 32) {
    data.push(series(v, "data[]"))
  }
  let seeds : Array[@warpfit.Series] = []
  for v in array(required(fields, "centers"), "centers", 16) {
    seeds.push(series(v, "centers[]"))
  }
  let params : @warpfit.ClusterOptions = {
    alignment: hard_alignment(options),
    max_iterations: integer_option(options, "max_iterations", 20),
    max_dba_steps: integer_option(options, "max_dba_steps", 20),
    tolerance: numeric_option(options, "tolerance", 1.0e-8),
    max_work_units: integer_option(options, "max_work_units", 20000000),
  }
  let result = from_result(@warpfit.dtw_kmeans(data, seeds, params))
  let centers : Array[Json] = []
  for center in result.centers {
    centers.push(matrix(center.values, center.count, center.dimensions))
  }
  let labels : Array[Json] = []
  for label in result.labels {
    labels.push(Json::number(label.to_double()))
  }
  {
    "schema": "warpfit.response/1",
    "ok": true,
    "operation": "cluster",
    "centers": Json::array(centers),
    "labels": Json::array(labels),
    "inertia": Json::number(result.inertia),
    "history": numbers(result.history),
    "iterations": Json::number(result.iterations.to_double()),
    "stop": Json::string(result.stop),
    "work_units": Json::number(result.work_units.to_double()),
  }
}

///|
fn dispatch(source : String) -> Json raise WireError {
  if source.length() > 2000000 {
    invalid("input_limit", "request exceeds 2000000 UTF-16 units")
  }
  let input = @json.parse(
    source[:],
    reject_duplicate_keys=true,
    preserve_number_repr=true,
    max_nesting_depth=16,
  ) catch {
    _ => {
      invalid("json", "invalid JSON, duplicate key, or excessive nesting")
      abort("unreachable")
    }
  }
  let preliminary = match input {
    Object(v) => v
    _ => {
      invalid("json_type", "request must be an object")
      abort("unreachable")
    }
  }
  if text(required(preliminary, "schema"), "schema") != "warpfit.request/1" {
    invalid("schema", "unsupported request schema")
  }
  let operation = text(required(preliminary, "operation"), "operation")
  let allowed = match operation {
    "loss" => ["schema", "operation", "objective", "x", "y", "options"]
    "fit" => ["schema", "operation", "seed", "examples", "options"]
    "rank" => ["schema", "operation", "query", "candidates", "top_k", "options"]
    "dtw" => ["schema", "operation", "x", "y", "options"]
    "dba" => ["schema", "operation", "seed", "examples", "options"]
    "cluster" => ["schema", "operation", "data", "centers", "options"]
    "preprocess" => ["schema", "operation", "series", "options"]
    "pipeline" => ["schema", "operation", "data", "seed_indices", "options"]
    _ => {
      invalid(
        "operation", "operation must be loss, fit, rank, dtw, dba, cluster, preprocess or pipeline",
      )
      abort("unreachable")
    }
  }
  let fields = object(input, "request", allowed)
  let common = ["gamma", "feature_weights", "max_cells"]
  let option_names = match operation {
    "fit" =>
      [
        "gamma", "feature_weights", "max_cells", "max_steps", "learning_rate", "gradient_tolerance",
        "improvement_tolerance", "max_evaluations", "max_work_units", "example_weights",
      ]
    "rank" => ["gamma", "feature_weights", "max_cells", "max_work_units"]
    "dtw" => ["window", "feature_weights", "max_cells"]
    "dba" =>
      [
        "window", "feature_weights", "max_cells", "max_steps", "tolerance", "max_work_units",
        "example_weights",
      ]
    "cluster" =>
      [
        "window", "feature_weights", "max_cells", "max_iterations", "max_dba_steps",
        "tolerance", "max_work_units",
      ]
    "preprocess" => ["target_count", "normalize", "epsilon"]
    "pipeline" =>
      [
        "target_count", "normalize", "epsilon", "window", "feature_weights", "max_cells",
        "max_iterations", "max_dba_steps", "tolerance", "max_work_units",
      ]
    _ => common
  }
  let options = match fields.get("options") {
    Some(v) => object(v, "options", option_names)
    None => Map([])
  }
  match operation {
    "loss" => loss(fields, alignment(options))
    "fit" => fitting(fields, options)
    "rank" => ranking(fields, options)
    "dtw" => hard_dtw(fields, options)
    "dba" => hard_dba(fields, options)
    "cluster" => hard_cluster(fields, options)
    "preprocess" => preprocess_one(fields, options)
    _ => pipeline_cluster(fields, options)
  }
}

///|
/// Versioned JSON interface shared by CLI, browser worker and external hosts.
pub fn run(source : String) -> String {
  let result = dispatch(source) catch {
    WireError(code, message) => {
      let error : Json = {
        "schema": "warpfit.response/1",
        "ok": false,
        "error": {
          "code": Json::string(code),
          "message": Json::string(message),
        },
      }
      error
    }
  }
  result.stringify()
}

///|
fn main {
  ()
}
