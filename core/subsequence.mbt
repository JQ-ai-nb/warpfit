///|
/// The inclusive target interval and a complete minimum-cost alignment path.
pub(all) struct SubsequenceMatch {
  start : Int32
  end : Int32
  distance : Double
  squared_cost : Double
  path : Array[DtwPoint]
  visited_cells : Int32
}

///|
/// Find the globally least-cost contiguous target interval matching all of
/// query. Target endpoints are open, query endpoints are closed; exact ties
/// select the earliest ending target position, then use diagonal/up/left
/// predecessor order. Windows are rejected because a band relative to an
/// unknown target start needs a separate, explicit definition.
pub fn subsequence_dtw(
  query : Series,
  target : Series,
  options : DtwOptions,
) -> Result[SubsequenceMatch, WarpError] {
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
  let n = query.count
  let m = target.count
  let dimensions = query.dimensions
  let stride = m + 1
  let accum = Array::make((n + 1) * stride, @double.infinity)
  for j = 0; j <= m; j = j + 1 {
    accum[j] = 0.0
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
    }
  }
  let mut last_j = 1
  let mut best_cost = accum[n * stride + 1]
  for j = 2; j <= m; j = j + 1 {
    let cost = accum[n * stride + j]
    if cost < best_cost {
      best_cost = cost
      last_j = j
    }
  }
  if best_cost == @double.infinity {
    return Err(failure("dtw_no_path", "no valid subsequence alignment exists"))
  }
  let backwards : Array[DtwPoint] = []
  let mut i = n
  let mut j = last_j
  while i > 0 && j > 0 {
    backwards.push({ x_index: i - 1, y_index: j - 1, })
    let diagonal = accum[(i - 1) * stride + j - 1]
    let up = accum[(i - 1) * stride + j]
    let left = accum[i * stride + j - 1]
    if diagonal <= up && diagonal <= left {
      i -= 1
      j -= 1
    } else if up <= left {
      i -= 1
    } else {
      j -= 1
    }
  }
  let path : Array[DtwPoint] = []
  for k = backwards.length() - 1; k >= 0; k = k - 1 {
    path.push(backwards[k])
  }
  Ok({
    start: path[0].y_index,
    end: last_j - 1,
    distance: best_cost.sqrt(),
    squared_cost: best_cost,
    path,
    visited_cells: n * m,
  })
}
