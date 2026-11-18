///|
/// Bounded self-similarity motif discovery options.
pub(all) struct MotifOptions {
  alignment : DtwOptions
  /// Maximum number of fixed-length windows considered; pairs are O(k^2).
  max_windows : Int32
  max_work_units : Int32
}

///|
pub fn motif_options() -> MotifOptions {
  { alignment: dtw_options(), max_windows: 16, max_work_units: 100000000, }
}

///|
/// A pair of equal-length windows with their hard-DTW distance.
pub(all) struct MotifPair {
  first_start : Int32
  second_start : Int32
  distance : Double
  squared_cost : Double
}

///|
pub(all) struct MotifResult {
  window : Int32
  pairs : Array[MotifPair]
  work_units : Int32
}

///|
fn motif_window(series : Series, start : Int32, window : Int32) -> Series {
  let dimensions = series.dimensions
  let values = Array::make(window * dimensions, 0.0)
  for i = 0; i < window; i = i + 1 {
    for k = 0; k < dimensions; k = k + 1 {
      values[i * dimensions + k] = series.values[(start + i) * dimensions + k]
    }
  }
  { count: window, dimensions, values, }
}

///|
fn motif_pair_better(a : MotifPair, b : MotifPair) -> Bool {
  if a.squared_cost < b.squared_cost {
    true
  } else if a.squared_cost > b.squared_cost {
    false
  } else if a.first_start < b.first_start {
    true
  } else if a.first_start > b.first_start {
    false
  } else {
    a.second_start < b.second_start
  }
}

///|
/// Find the `top_k` most similar pairs of fixed-length windows under hard DTW.
/// Windows may overlap; the result is a bounded self-similarity search, not a
/// claim that the pair is a semantically meaningful motif.
pub fn discover_motifs(
  series : Series,
  window : Int32,
  top_k : Int32,
  options : MotifOptions,
) -> Result[MotifResult, WarpError] {
  match validate_raw_series(series) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  if window < 1 || window > 512 || window > series.count {
    return Err(failure("window", "window must be within 1..min(512, samples)"))
  }
  if top_k < 1 || top_k > 16 {
    return Err(failure("top_k", "top_k must be within 1..16"))
  }
  if options.max_windows < 2 || options.max_windows > 32 {
    return Err(failure("max_windows", "max_windows must be within 2..32"))
  }
  if options.max_work_units < 1 || options.max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  let count = series.count - window + 1
  if count < 2 || count > options.max_windows {
    return Err(
      failure(
        "motif_windows", "window count must be within 2..max_windows; shorten the series or raise max_windows",
      ),
    )
  }
  let windows : Array[Series] = []
  for start = 0; start < count; start = start + 1 {
    windows.push(motif_window(series, start, window))
  }
  let pair_units = window * window * series.dimensions
  let mut work = 0
  let mut pairs : Array[MotifPair] = []
  for first = 0; first < count; first = first + 1 {
    for second = first + 1; second < count; second = second + 1 {
      if pair_units > options.max_work_units ||
        work > options.max_work_units - pair_units {
        return Err(
          failure("work_budget", "budget cannot cover every motif pair"),
        )
      }
      work += pair_units
      let measured = match
        dtw_distance(windows[first], windows[second], options.alignment) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let candidate : MotifPair = {
        first_start: first,
        second_start: second,
        distance: measured.distance,
        squared_cost: measured.squared_cost,
      }
      if pairs.length() < top_k {
        pairs.push(candidate)
        pairs.sort_by(fn(a, b) {
          if motif_pair_better(a, b) {
            -1
          } else if motif_pair_better(b, a) {
            1
          } else {
            0
          }
        })
      } else if motif_pair_better(candidate, pairs[pairs.length() - 1]) {
        let next : Array[MotifPair] = []
        for index = 0; index < top_k - 1; index = index + 1 {
          next.push(pairs[index])
        }
        next.push(candidate)
        next.sort_by(fn(a, b) {
          if motif_pair_better(a, b) {
            -1
          } else if motif_pair_better(b, a) {
            1
          } else {
            0
          }
        })
        pairs = next
      }
    }
  }
  Ok({ window, pairs, work_units: work, })
}
