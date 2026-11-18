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
  for j = 1; j <= m; j = j + 1 {
    let cost = accum[n * stride + j]
    if cost == @double.infinity {
      continue
    }
    let candidate : SubsequenceCandidate = {
      start: starts[n * stride + j],
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
  Ok({ matches, visited_cells: n * m, work_units: n * m * dimensions, })
}
