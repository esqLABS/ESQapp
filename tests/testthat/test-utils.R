test_that(".convertPoints handles valid conversions correctly", {
  expect_equal(.convertPoints(1, "pts/s", "pts/day(s)"), 86400)
  expect_equal(.convertPoints(1, "pts/min", "pts/day(s)"), 1440)
  expect_equal(.convertPoints(1, "pts/h", "pts/day(s)"), 24)
  expect_equal(.convertPoints(1, "pts/day", "pts/day(s)"), 1)

  expect_equal(.convertPoints(1, "pts/day", "pts/week(s)"), 1/7)
  expect_equal(.convertPoints(1, "pts/day", "pts/month(s)"), 1/30)
  expect_equal(.convertPoints(1, "pts/day", "pts/year(s)"), 1/365)
  expect_equal(.convertPoints(1, "pts/day", "pts/ks"), 1000/86400)
})

test_that(".convertPoints handles unsupported current units", {
  expect_error(.convertPoints(1, "pts/ms", "pts/day(s)"), "Unsupported current unit")
  expect_error(.convertPoints(1, "pts/yr", "pts/day(s)"), "Unsupported current unit")
})

test_that(".convertPoints handles unsupported target units", {
  expect_error(.convertPoints(1, "pts/s", "pts/decade"), "Unsupported target unit")
  expect_error(.convertPoints(1, "pts/s", "pts/hour"), "Unsupported target unit")
})
