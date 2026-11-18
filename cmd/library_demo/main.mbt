///|
/// End-to-end typed example, compiled by CI like any other package:
///
///   moon run cmd/library_demo --target js
///
/// It shows the three steps a third-party project needs - build Series from
/// rows, train a model that keeps its preprocessing, then label a later batch -
/// and how to report a failure without unwrapping.
fn series(rows : Array[Array[Double]]) -> @warpfit.Series? {
  match @warpfit.Series::from_rows(rows) {
    Ok(value) => Some(value)
    Err(error) => {
      println("invalid series: " + error.to_string())
      None
    }
  }
}

///|
fn main {
  let data : Array[@warpfit.Series] = []
  for
    rows in [
      [[0.0], [1.0], [0.0]],
      [[0.0], [1.0], [0.2]],
      [[9.0], [9.0], [9.0]],
      [[9.0], [9.2], [9.0]],
    ] {
    match series(rows) {
      Some(value) => data.push(value)
      None => return
    }
  }
  let options : @warpfit.PipelineOptions = {
    preprocessing: @warpfit.preprocess_options(),
    clustering: @warpfit.cluster_options(),
  }
  let fit = match @warpfit.train_cluster_model(data, [0, 2], options) {
    Ok(value) => value
    Err(error) => {
      println("training failed: " + error.to_string())
      return
    }
  }
  println("centers: " + fit.model.centers.length().to_string())
  let later : Array[@warpfit.Series] = []
  for rows in [[[0.1], [1.0], [0.0]], [[9.0], [9.0], [8.8]]] {
    match series(rows) {
      Some(value) => later.push(value)
      None => return
    }
  }
  match @warpfit.predict_clusters(fit.model, later, 20000000) {
    Ok(prediction) => {
      let mut text = "labels: ["
      for index, label in prediction.labels {
        if index > 0 {
          text = text + ", "
        }
        text = text + label.to_string()
      }
      println(text + "]")
    }
    Err(error) => println("prediction failed: " + error.to_string())
  }
}
