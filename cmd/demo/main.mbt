///|
fn main raise {
  let x : @warpfit.Series = { count: 2, dimensions: 1, values: [0.0, 1.0], }
  let raw = @warpfit.soft_dtw(x, x, 1.0).unwrap()
  let corrected = @warpfit.divergence(x, x, 1.0).unwrap()
  println("identical_raw=" + raw.value.to_string())
  println("identical_corrected=" + corrected.value.to_string())
  let seed : @warpfit.Series = {
    count: 4,
    dimensions: 1,
    values: [2.0, -1.0, 2.0, 0.0],
  }
  let examples : Array[@warpfit.Series] = [
    { count: 3, dimensions: 1, values: [0.0, 1.0, 0.0], },
    { count: 4, dimensions: 1, values: [0.0, 0.8, 1.0, 0.0], },
  ]
  let fitted = @warpfit.fit(seed, examples, 0.4, 30).unwrap()
  println("prototype_initial=" + fitted.objective[0].to_string())
  println("prototype_final=" + fitted.objective.last().unwrap().to_string())
  println("accepted_steps=" + fitted.accepted_steps.to_string())
  let prediction : @warpfit.Series = {
    count: 2,
    dimensions: 2,
    values: [0.2, -0.3, 1.5, 0.8],
  }
  let target : @warpfit.Series = {
    count: 3,
    dimensions: 2,
    values: [0.0, -0.2, 0.6, 0.4, 1.2, 0.9],
  }
  let loss = @warpfit.divergence(prediction, target, 0.8).unwrap()
  println("training_loss=" + loss.value.to_string())
  println("training_gradient_first=" + loss.gradient_x[0].to_string())
  let query : @warpfit.Series = {
    count: 3,
    dimensions: 1,
    values: [0.0, 1.0, 0.0],
  }
  let stretched : @warpfit.Series = {
    count: 4,
    dimensions: 1,
    values: [0.0, 0.8, 1.0, 0.0],
  }
  let changed : @warpfit.Series = {
    count: 3,
    dimensions: 1,
    values: [1.0, 0.0, 1.0],
  }
  let same_score = @warpfit.divergence(query, query, 0.4).unwrap().value
  let stretched_score = @warpfit.divergence(query, stretched, 0.4).unwrap().value
  let changed_score = @warpfit.divergence(query, changed, 0.4).unwrap().value
  assert_true(same_score < stretched_score && stretched_score < changed_score)
  println("query_same=" + same_score.to_string())
  println("query_stretched=" + stretched_score.to_string())
  println("query_changed=" + changed_score.to_string())
}
