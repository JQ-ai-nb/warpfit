///|
test "trained model predicts one or many new samples without requiring every cluster" {
  let data = [
    univariate([2.0, 4.0, 6.0]),
    univariate([100.0, 200.0, 300.0]),
    univariate([6.0, 4.0, 2.0]),
    univariate([300.0, 200.0, 100.0]),
  ]
  let options = {
    preprocessing: { ..preprocess_options(), target_count: 5, },
    clustering: {
      ..cluster_options(),
      alignment: { ..dtw_options(), window: 0, feature_weights: [1.0], },
    },
  }
  let fit = train_cluster_model(data, [0, 2], options).unwrap()
  let prediction = predict_clusters(
    fit.model,
    [univariate([50.0, 100.0, 150.0]), univariate([2.0, 4.0, 6.0])],
    10000,
  ).unwrap()
  assert_eq(prediction.labels, [0, 0])
  near(prediction.distances[0], 0.0)
  assert_eq(prediction.distances_to_centers[0].length(), 2)
  assert_true(prediction.distances_to_centers[0][1] > 0.0)
  options.clustering.alignment.feature_weights[0] = 2.0
  fit.training.clustering.centers[0].values[0] = 999.0
  near(fit.model.alignment.feature_weights[0], 1.0)
  assert_true(fit.model.centers[0].values[0] != 999.0)
}

///|
test "prediction handles ties and rejects malformed models or insufficient budget" {
  let zero = univariate([0.0])
  let model : ClusterModel = {
    version: 1,
    centers: [zero, zero],
    preprocessing: { ..preprocess_options(), normalize: false, },
    alignment: dtw_options(),
  }
  let result = predict_clusters(model, [zero], 2).unwrap()
  assert_eq(result.labels, [0])
  near(result.distances[0], 0.0)
  assert_eq(result.work_units, 2)
  match predict_clusters(model, [zero], 1) {
    Err(error) => assert_eq(error.code, "work_budget")
    Ok(_) => abort("prediction cannot return a partially evaluated batch")
  }
  assert_true(failed(predict_clusters({ ..model, version: 2, }, [zero], 2)))
  assert_true(failed(predict_clusters({ ..model, centers: [], }, [zero], 2)))
  assert_true(failed(predict_clusters(model, [], 2)))
  assert_true(
    failed(
      predict_clusters(
        model,
        [{ count: 1, dimensions: 2, values: [0.0, 0.0], }],
        20,
      ),
    ),
  )
  assert_true(
    failed(
      predict_clusters(
        { ..model, preprocessing: { ..model.preprocessing, target_count: 2, }, },
        [zero],
        20,
      ),
    ),
  )
}

///|
test "automatic farthest-first seeds are deterministic and charged to training" {
  let data = [
    univariate([0.0]),
    univariate([2.0]),
    univariate([9.0]),
    univariate([11.0]),
  ]
  let options = {
    preprocessing: { ..preprocess_options(), normalize: false, },
    clustering: cluster_options(),
  }
  let auto = train_cluster_model_auto(data, 2, 0, options).unwrap()
  assert_eq(auto.seed_indices, [0, 3])
  assert_eq(auto.seed_work_units, 3)
  assert_eq(auto.fitted.training.clustering.labels, [0, 0, 1, 1])
  assert_eq(
    auto.total_work_units,
    auto.seed_work_units + auto.fitted.training.clustering.work_units,
  )
  let repeat = train_cluster_model_auto(data, 2, 0, options).unwrap()
  assert_eq(repeat.seed_indices, auto.seed_indices)
  assert_true(auto.total_work_units <= options.clustering.max_work_units)
  assert_true(failed(select_farthest_seeds(data, 2, 0, dtw_options(), 2)))
  match select_farthest_seeds([data[0], data[0]], 2, 0, dtw_options(), 10) {
    Err(error) => assert_eq(error.code, "seed_distinct")
    Ok(_) => abort("indistinguishable samples cannot create distinct seeds")
  }
  assert_true(failed(train_cluster_model_auto(data, 5, 0, options)))
  assert_true(
    failed(select_farthest_seeds([univariate([])], 1, 0, dtw_options(), 10)),
  )
  assert_true(
    failed(
      select_farthest_seeds(
        data,
        1,
        0,
        { ..dtw_options(), feature_weights: [0.0], },
        10,
      ),
    ),
  )
}
