///|
/// Deterministic k-fold evaluation options for the DTW nearest-neighbour
/// classifier. Folds are assigned by input index, not by label.
pub(all) struct CrossValidationOptions {
  k : Int32
  folds : Int32
  alignment : DtwOptions
  max_work_units : Int32
}

///|
pub fn cross_validation_options() -> CrossValidationOptions {
  { k: 3, folds: 2, alignment: dtw_options(), max_work_units: 40000000, }
}

///|
/// Per-class precision, recall and F1 from a confusion matrix.
pub(all) struct ClassificationScore {
  label : String
  support : Int32
  predicted : Int32
  true_positive : Int32
  precision : Double
  recall : Double
  f1 : Double
}

///|
/// k-fold result. Predictions preserve the input order; labels preserve the
/// first-appearance order of the true labels.
pub(all) struct CrossValidationResult {
  accuracy : Double
  labels : Array[String]
  confusion : Array[Array[Int32]]
  scores : Array[ClassificationScore]
  predictions : Array[String]
  work_units : Int32
}

///|
fn cv_label_index(labels : Array[String], value : String) -> Int32 {
  for index, label in labels {
    if label == value {
      return index
    }
  }
  -1
}

///|
/// Evaluate k-nearest-neighbour classification with deterministic index-based
/// folds. Every fold trains on all other samples and predicts its own samples.
/// This is a small-sample engineering check, not a model-selection guarantee.
pub fn cross_validate_knn(
  data : Array[Series],
  class_labels : Array[String],
  options : CrossValidationOptions,
) -> Result[CrossValidationResult, WarpError] {
  let n = data.length()
  if n < 3 || n > 32 {
    return Err(
      failure("sample_count", "expected 3..32 samples for cross-validation"),
    )
  }
  if class_labels.length() != n {
    return Err(failure("label_count", "one class label per sample is required"))
  }
  if options.folds < 2 || options.folds > 8 || options.folds > n - 1 {
    return Err(failure("folds", "folds must be within 2..min(8, samples-1)"))
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  for label in class_labels {
    if label.length() < 1 || label.length() > 80 {
      return Err(
        failure("label", "labels must be nonempty and at most 80 UTF-16 units"),
      )
    }
  }
  let max_test = (n + options.folds - 1) / options.folds
  let min_train = n - max_test
  if options.k < 1 || options.k > min_train {
    return Err(failure("k", "k must be within 1..the smallest training fold"))
  }
  let predictions = Array::make(n, "")
  let mut work = 0
  for fold = 0; fold < options.folds; fold = fold + 1 {
    let training : Array[LabeledSeries] = []
    let test_indices : Array[Int32] = []
    for index, sample in data {
      if index % options.folds == fold {
        test_indices.push(index)
      } else {
        training.push({ label: class_labels[index], series: sample, })
      }
    }
    if test_indices.is_empty() {
      continue
    }
    let remaining = options.max_work_units - work
    if remaining < 1 {
      return Err(
        failure("work_budget", "budget cannot cover every validation fold"),
      )
    }
    for index in test_indices {
      let predicted = match
        knn_classify(data[index], training, {
          k: options.k,
          alignment: options.alignment,
          max_work_units: remaining,
        }) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      work += predicted.work_units
      if work > options.max_work_units {
        return Err(
          failure("work_budget", "budget cannot cover every validation fold"),
        )
      }
      predictions[index] = predicted.label
    }
  }
  let labels : Array[String] = []
  for label in class_labels {
    if cv_label_index(labels, label) < 0 {
      labels.push(label)
    }
  }
  let confusion : Array[Array[Int32]] = []
  for _ in labels {
    confusion.push(Array::make(labels.length(), 0))
  }
  let mut correct = 0
  for index, actual in class_labels {
    let predicted = predictions[index]
    let row = cv_label_index(labels, actual)
    let column = cv_label_index(labels, predicted)
    if row >= 0 && column >= 0 {
      confusion[row][column] += 1
    }
    if actual == predicted {
      correct += 1
    }
  }
  let scores : Array[ClassificationScore] = []
  for row, label in labels {
    let mut support = 0
    let mut predicted_count = 0
    for column = 0; column < labels.length(); column = column + 1 {
      support += confusion[row][column]
      predicted_count += confusion[column][row]
    }
    let true_positive = confusion[row][row]
    let precision = if predicted_count > 0 {
      true_positive.to_double() / predicted_count.to_double()
    } else {
      0.0
    }
    let recall = if support > 0 {
      true_positive.to_double() / support.to_double()
    } else {
      0.0
    }
    let f1 = if precision + recall > 0.0 {
      2.0 * precision * recall / (precision + recall)
    } else {
      0.0
    }
    scores.push({
      label,
      support,
      predicted: predicted_count,
      true_positive,
      precision,
      recall,
      f1,
    })
  }
  Ok({
    accuracy: correct.to_double() / n.to_double(),
    labels,
    confusion,
    scores,
    predictions,
    work_units: work,
  })
}
