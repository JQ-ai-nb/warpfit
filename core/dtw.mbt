///|
/// Hard DTW options. window = -1 disables the band; nonnegative values use
/// a Sakoe-Chiba band extended along the longer axis for unequal lengths.
pub(all) struct DtwOptions {
  window : Int32
  feature_weights : Array[Double]
  max_cells : Int32
}

///|
pub(all) struct DtwPoint {
  x_index : Int32
  y_index : Int32
}

///|
pub(all) struct DtwPath {
  /// Square root of total weighted squared point cost, like tslearn DTW.
  distance : Double
  /// Sum of weighted squared point cost along the selected path.
  squared_cost : Double
  /// Zero-based points, from (0, 0) to (n-1, m-1), inclusive.
  path : Array[DtwPoint]
  /// Number of non-padding cells inside the band evaluated by this call.
  visited_cells : Int32
}

///|
pub fn dtw_options() -> DtwOptions {
  { window: -1, feature_weights: [], max_cells: 262144, }
}

///|
fn dtw_alignment_options(options : DtwOptions) -> AlignOptions {
  {
    gamma: 1.0,
    feature_weights: options.feature_weights,
    max_cells: options.max_cells,
  }
}

///|
fn validate_dtw_pair(
  x : Series,
  y : Series,
  options : DtwOptions,
) -> Result[Unit, WarpError] {
  if options.window < -1 || options.window > 512 {
    return Err(failure("dtw_window", "window must be -1 or within 0..512"))
  }
  validate_pair(x, y, dtw_alignment_options(options))
}

///|
fn dtw_in_band(
  i : Int32,
  j : Int32,
  n : Int32,
  m : Int32,
  radius : Int32,
) -> Bool {
  if radius < 0 {
    true
  } else if n <= m {
    j >= i - radius && j <= i + (m - n) + radius
  } else {
    i >= j - radius && i <= j + (n - m) + radius
  }
}

///|
/// Calculate weighted hard DTW and its complete optimal path. On equal-cost
/// predecessors, prefer diagonal, then up, then left for deterministic output.
/// The full n*m allocation counts toward max_cells even when a band is set.
pub fn dtw_path(
  x : Series,
  y : Series,
  options : DtwOptions,
) -> Result[DtwPath, WarpError] {
  match validate_dtw_pair(x, y, options) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let n = x.count
  let m = y.count
  let d = x.dimensions
  let stride = m + 1
  let accum = Array::make((n + 1) * stride, @double.infinity)
  accum[0] = 0.0
  let weighted = dtw_alignment_options(options)
  let mut visited = 0
  for i = 1; i <= n; i = i + 1 {
    for j = 1; j <= m; j = j + 1 {
      if !dtw_in_band(i - 1, j - 1, n, m, options.window) {
        continue
      }
      visited += 1
      let mut cost = 0.0
      for k = 0; k < d; k = k + 1 {
        let delta = x.values[(i - 1) * d + k] - y.values[(j - 1) * d + k]
        cost += feature_weight(weighted, k) * delta * delta
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
      accum[i * stride + j] = cost + best
    }
  }
  let cost = accum[n * stride + m]
  if cost == @double.infinity {
    return Err(failure("dtw_no_path", "no valid alignment path exists"))
  }
  let backwards : Array[DtwPoint] = []
  let mut i = n
  let mut j = m
  while i > 0 && j > 0 {
    backwards.push({ x_index: i - 1, y_index: j - 1, })
    if i == 1 && j == 1 {
      break
    }
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
    distance: cost.sqrt(),
    squared_cost: cost,
    path,
    visited_cells: visited,
  })
}
