///|
/// Complete typed MoonBit example: resample and normalize four unlabeled
/// series, then group their shapes with hard DTW and DBA cluster centers.
fn main raise {
  let data : Array[@warpfit.Series] = [
    { count: 3, dimensions: 1, values: [2.0, 4.0, 6.0], },
    { count: 5, dimensions: 1, values: [100.0, 200.0, 300.0, 400.0, 500.0], },
    { count: 3, dimensions: 1, values: [6.0, 4.0, 2.0], },
    { count: 5, dimensions: 1, values: [500.0, 400.0, 300.0, 200.0, 100.0], },
  ]
  let options : @warpfit.PipelineOptions = {
    preprocessing: { ..@warpfit.preprocess_options(), target_count: 5, },
    clustering: {
      ..@warpfit.cluster_options(),
      alignment: { ..@warpfit.dtw_options(), window: 0, },
    },
  }
  let result = @warpfit.prepare_and_cluster(data, [0, 2], options).unwrap()
  assert_eq(result.clustering.labels, [0, 0, 1, 1])
  assert_true(result.clustering.inertia.abs() < 1.0e-10)
  for i, label in result.clustering.labels {
    println("sample \{i}: cluster \{label}")
  }
  println("inertia: \{result.clustering.inertia}")
  println("stop: \{result.clustering.stop}")
  println("matrix work units: \{result.clustering.work_units}")
}
