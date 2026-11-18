///|
/// One contiguous target interval that matches the complete query.
pub(all) struct SubsequenceCandidate {
  start : Int32
  end : Int32
  distance : Double
  squared_cost : Double
}

///|
/// Top-k subsequence result. Matches may overlap; ordering is by cost, then
/// earlier end, then earlier start.
pub(all) struct SubsequenceTopK {
  matches : Array[SubsequenceCandidate]
  visited_cells : Int32
  work_units : Int32
}

///|
fn subsequence_candidate_better(
  a : SubsequenceCandidate,
  b : SubsequenceCandidate,
) -> Bool {
  if a.squared_cost < b.squared_cost {
    true
  } else if a.squared_cost > b.squared_cost {
    false
  } else if a.end < b.end {
    true
  } else if a.end > b.end {
    false
  } else {
    a.start < b.start
  }
}

///|
/// Find up to `top_k` minimum-cost contiguous target intervals that match the
/// complete query. Target endpoints are open and query endpoints are closed.
/// The DP also carries the start index, so each candidate is available in O(1)
/// after the forward pass. Windows are rejected because the band would need a
/// separate definition relative to an unknown target start.
///|
/// Full DTW cost between the query and the length-`n` target window starting at
/// `start`. Used when the unconstrained best path compresses the query onto
/// fewer target points than the contract allows: evaluating the tightest legal
/// window is better than dropping that endpoint altogether.
fn window_squared_cost(
  query : Series,
  target : Series,
  start : Int,
  options : DtwOptions,
) -> Double {
  let n = query.count
  let d = query.dimensions
  let weighted = dtw_alignment_options(options)
  let stride = n + 1
  let mut previous = Array::make(stride, @double.infinity)
  let mut current = Array::make(stride, @double.infinity)
  previous[0] = 0.0
  for i = 1; i <= n; i = i + 1 {
    current[0] = @double.infinity
    for j = 1; j <= n; j = j + 1 {
      let mut point_cost = 0.0
      for k = 0; k < d; k = k + 1 {
        let delta = query.values[(i - 1) * d + k] -
          target.values[(start + j - 1) * d + k]
        point_cost += feature_weight(weighted, k) * delta * delta
      }
      let mut best = previous[j - 1]
      if previous[j] < best {
        best = previous[j]
      }
      if current[j - 1] < best {
        best = current[j - 1]
      }
      current[j] = point_cost + best
    }
    let stash = previous
    previous = current
    current = stash
  }
  previous[n]
}

///|
pub fn subsequence_topk(
  query : Series,
  target : Series,
  top_k : Int32,
  options : DtwOptions,
) -> Result[SubsequenceTopK, WarpError] {
  if top_k < 1 || top_k > 16 {
    return Err(failure("top_k", "top_k must be within 1..16"))
  }
  if options.window != -1 {
    return Err(
      failure(
        "subsequence_window", "subsequence matching does not support a window",
      ),
    )
  }
  match validate_series(query) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match validate_raw_series(target) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let weighted = dtw_alignment_options(options)
  match validate_pair_options(query, target, weighted) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  if target.count < query.count {
    return Err(
      failure(
        "subsequence_length", "target must be at least as long as the query",
      ),
    )
  }
  let n = query.count
  let m = target.count
  let dimensions = query.dimensions
  let stride = m + 1
  let accum = Array::make((n + 1) * stride, @double.infinity)
  let starts = Array::make((n + 1) * stride, 0)
  for j = 0; j <= m; j = j + 1 {
    accum[j] = 0.0
    starts[j] = j
  }
  for i = 1; i <= n; i = i + 1 {
    for j = 1; j <= m; j = j + 1 {
      let mut point_cost = 0.0
      for k = 0; k < dimensions; k = k + 1 {
        let delta = query.values[(i - 1) * dimensions + k] -
          target.values[(j - 1) * dimensions + k]
        point_cost += feature_weight(weighted, k) * delta * delta
      }
      let diagonal = accum[(i - 1) * stride + j - 1]
      let up = accum[(i - 1) * stride + j]
      let left = accum[i * stride + j - 1]
      let mut best = diagonal
      if up < best {
        best = up
      }
      if left < best {
        best = left
      }
      accum[i * stride + j] = point_cost + best
      if i == 1 {
        if left <= diagonal && left <= up {
          starts[i * stride + j] = starts[i * stride + j - 1]
        } else {
          starts[i * stride + j] = j - 1
        }
      } else if diagonal <= up && diagonal <= left {
        starts[i * stride + j] = starts[(i - 1) * stride + j - 1]
      } else if up <= left {
        starts[i * stride + j] = starts[(i - 1) * stride + j]
      } else {
        starts[i * stride + j] = starts[i * stride + j - 1]
      }
    }
  }
  let mut matches : Array[SubsequenceCandidate] = []
  let mut fallback_units = 0
  for j = 1; j <= m; j = j + 1 {
    let mut cost = accum[n * stride + j]
    if cost == @double.infinity {
      continue
    }
    let mut start = starts[n * stride + j]
    // A valid contiguous interval must contain at least as many target points
    // as the query. When the unconstrained best path compressed several query
    // points onto one target point, evaluate the tightest legal window ending
    // here instead of dropping the endpoint: dropping produced empty results
    // for inputs where a legal window plainly exists.
    if j - start < n {
      if j < n {
        continue
      }
      let units = n * n * dimensions
      // Bound the fallback to one extra forward pass: pathological inputs must
      // not multiply the runtime. Endpoints beyond the allowance are skipped,
      // exactly as before this fix.
      if fallback_units + units > n * m * dimensions {
        continue
      }
      fallback_units += units
      start = j - n
      cost = window_squared_cost(query, target, start, options)
      if cost == @double.infinity {
        continue
      }
    }
    let candidate : SubsequenceCandidate = {
      start,
      end: j - 1,
      distance: cost.sqrt(),
      squared_cost: cost,
    }
    if matches.length() < top_k {
      matches.push(candidate)
      matches.sort_by(fn(a, b) {
        if subsequence_candidate_better(a, b) {
          -1
        } else if subsequence_candidate_better(b, a) {
          1
        } else {
          0
        }
      })
    } else if subsequence_candidate_better(
        candidate,
        matches[matches.length() - 1],
      ) {
      let next : Array[SubsequenceCandidate] = []
      for index = 0; index < top_k - 1; index = index + 1 {
        next.push(matches[index])
      }
      next.push(candidate)
      next.sort_by(fn(a, b) {
        if subsequence_candidate_better(a, b) {
          -1
        } else if subsequence_candidate_better(b, a) {
          1
        } else {
          0
        }
      })
      matches = next
    }
  }
  Ok({
    matches,
    visited_cells: n * m,
    work_units: n * m * dimensions + fallback_units,
  })
}
