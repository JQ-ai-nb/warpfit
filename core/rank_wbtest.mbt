///|
test "ranking evaluates complete candidates and preserves equal-score order" {
  let query = univariate([0.0, 1.0, 0.0])
  let candidates = [
    { id: "same-first", series: query, },
    { id: "different", series: univariate([1.0, 0.0, 1.0]), },
    { id: "same-second", series: query, },
  ]
  let r = rank_candidates(query, candidates, alignment_options(0.4), 2, 10000).unwrap()
  assert_eq(r.matches.length(), 2)
  assert_eq(r.candidates_evaluated, 3)
  assert_eq(r.matches[0].id, "same-first")
  assert_eq(r.matches[1].id, "same-second")
  near(r.matches[0].value, 0.0)
  assert_eq(r.work_units, 63)
}

///|
test "ranking rejects duplicate ids and insufficient complete-set budgets" {
  let q = univariate([0.0])
  let candidates = [{ id: "one", series: q, }, { id: "one", series: q, }]
  assert_true(
    failed(rank_candidates(q, candidates, alignment_options(1.0), 1, 100)),
  )
  let unique = [{ id: "one", series: q, }]
  assert_true(failed(rank_candidates(q, unique, alignment_options(1.0), 1, 2)))
  assert_true(
    failed(rank_candidates(q, unique, alignment_options(1.0), 0, 100)),
  )
}

///|
test "ranking does not mutate caller series or candidate order" {
  let q = univariate([0.0])
  let candidates = [
    { id: "far", series: univariate([2.0]), },
    { id: "near", series: q, },
  ]
  let r = rank_candidates(q, candidates, alignment_options(1.0), 2, 100).unwrap()
  assert_eq(r.matches[0].id, "near")
  assert_eq(candidates[0].id, "far")
  near(candidates[0].series.values[0], 2.0)
}
