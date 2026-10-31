///|
pub(all) struct Candidate {
  id : String
  series : Series
}

///|
pub(all) struct Match {
  id : String
  input_index : Int32
  value : Double
  raw_cross : Double
  raw_self_candidate : Double
}

///|
pub(all) struct Ranking {
  matches : Array[Match]
  raw_self_query : Double
  work_units : Int32
  candidates_evaluated : Int32
}

///|
/// Complete, bounded query-by-example ranking. Scores are alignment objectives,
/// not probabilities. Ties retain input order; no result is returned partially.
pub fn rank_candidates(
  query : Series,
  candidates : Array[Candidate],
  options : AlignOptions,
  top_k : Int32,
  max_work_units : Int32,
) -> Result[Ranking, WarpError] {
  if candidates.is_empty() ||
    candidates.length() > 32 ||
    top_k < 1 ||
    top_k > candidates.length() {
    return Err(
      failure("candidate_count", "expected 1..32 candidates and a valid top_k"),
    )
  }
  if max_work_units < 1 || max_work_units > 100000000 {
    return Err(
      failure("work_budget", "max_work_units must be within 1..100000000"),
    )
  }
  match validate_pair(query, query, options) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let seen : Map[String, Bool] = Map([])
  let mut units = query.count * query.count * query.dimensions
  for candidate in candidates {
    if candidate.id.length() < 1 ||
      candidate.id.length() > 80 ||
      seen.contains(candidate.id) {
      return Err(
        failure(
          "candidate_id", "candidate ids must be nonempty, unique and at most 80 UTF-16 units",
        ),
      )
    }
    seen[candidate.id] = true
    match validate_pair(query, candidate.series, options) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
    match validate_pair(candidate.series, candidate.series, options) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
    units += (
        query.count * candidate.series.count +
        candidate.series.count * candidate.series.count
      ) *
      query.dimensions
  }
  if units > max_work_units {
    return Err(
      failure(
        "work_budget", "ranking cannot evaluate the entire candidate set within the budget",
      ),
    )
  }
  let qq = match soft_dtw_with(query, query, options) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let matches : Array[Match] = []
  for i, candidate in candidates {
    let xy = match soft_dtw_with(query, candidate.series, options) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    let yy = match soft_dtw_with(candidate.series, candidate.series, options) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    matches.push({
      id: candidate.id,
      input_index: i,
      value: xy.value - 0.5 * qq.value - 0.5 * yy.value,
      raw_cross: xy.value,
      raw_self_candidate: yy.value,
    })
  }
  matches.sort_by(fn(a, b) {
    if a.value < b.value {
      -1
    } else if a.value > b.value {
      1
    } else {
      a.input_index - b.input_index
    }
  })
  let selected = []
  for i = 0; i < top_k; i = i + 1 {
    selected.push(matches[i])
  }
  Ok({
    matches: selected,
    raw_self_query: qq.value,
    work_units: units,
    candidates_evaluated: candidates.length(),
  })
}
