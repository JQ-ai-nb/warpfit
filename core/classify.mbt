///|
/// A training sample with a caller-supplied class label. Labels repeat across
/// samples by design; they are not identifiers.
pub(all) struct LabeledSeries {
  label : String
  series : Series
}

///|
/// Nearest-neighbour classification over hard DTW distances.
pub(all) struct KnnOptions {
  k : Int32
  alignment : DtwOptions
  max_work_units : Int32
}

///|
pub fn knn_options() -> KnnOptions {
  { k: 3, alignment: dtw_options(), max_work_units: 20000000, }
}

///|
pub(all) struct Neighbor {
  label : String
  train_index : Int32
  /// Euclidean-rooted DTW distance, the same quantity `dtw_distance` reports.
  distance : Double
}

///|
pub(all) struct KnnPrediction {
  /// Majority label among the k neighbours.
  label : String
  /// Exactly k neighbours, ordered by distance and then training index.
  neighbors : Array[Neighbor]
  /// Distinct labels in first-appearance order of the neighbour list.
  labels : Array[String]
  /// Vote counts aligned with `labels`.
  votes : Array[Int32]
  work_units : Int32
}

///|
/// Classify one query by majority vote of its k nearest training series.
///
/// Ties in vote count are broken by the smaller total distance among the
/// neighbours that voted for the label; an exact remaining tie keeps the label
/// that appears first in the neighbour order. Both rules are deterministic, so
/// the same input always produces the same label. The result is a neighbour
/// vote, not a probability and not a calibrated confidence.
pub fn knn_classify(
  query : Series,
  training : Array[LabeledSeries],
  options : KnnOptions,
) -> Result[KnnPrediction, WarpError] {
  if training.is_empty() || training.length() > 32 {
    return Err(failure("training_count", "expected 1..32 training series"))
  }
  if options.k < 1 || options.k > training.length() {
    return Err(failure("k", "k must be within 1..training series count"))
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  let mut units = 0
  for item in training {
    if item.label.length() < 1 || item.label.length() > 80 {
      return Err(
        failure("label", "labels must be nonempty and at most 80 UTF-16 units"),
      )
    }
    match validate_dtw_pair(query, item.series, options.alignment) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    let pair_units = query.count * item.series.count * query.dimensions
    if pair_units > options.max_work_units ||
      units > options.max_work_units - pair_units {
      return Err(
        failure(
          "work_budget", "budget cannot cover a complete neighbour search",
        ),
      )
    }
    units += pair_units
  }
  let neighbors : Array[Neighbor] = []
  for index, item in training {
    let measured = match dtw_distance(query, item.series, options.alignment) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    neighbors.push({
      label: item.label,
      train_index: index,
      distance: measured.distance,
    })
  }
  neighbors.sort_by(fn(a, b) {
    if a.distance < b.distance {
      -1
    } else if a.distance > b.distance {
      1
    } else {
      a.train_index - b.train_index
    }
  })
  let labels : Array[String] = []
  let votes : Array[Int32] = []
  let distance_sums : Array[Double] = []
  for index = 0; index < options.k; index = index + 1 {
    let neighbor = neighbors[index]
    let mut found = -1
    for position, label in labels {
      if label == neighbor.label {
        found = position
      }
    }
    if found >= 0 {
      votes[found] += 1
      distance_sums[found] += neighbor.distance
    } else {
      labels.push(neighbor.label)
      votes.push(1)
      distance_sums.push(neighbor.distance)
    }
  }
  let mut best = 0
  for position = 1; position < labels.length(); position = position + 1 {
    if votes[position] > votes[best] {
      best = position
    } else if votes[position] == votes[best] &&
      distance_sums[position] < distance_sums[best] {
      best = position
    }
  }
  let selected : Array[Neighbor] = []
  for index = 0; index < options.k; index = index + 1 {
    selected.push(neighbors[index])
  }
  Ok({
    label: labels[best],
    neighbors: selected,
    labels,
    votes,
    work_units: units,
  })
}
