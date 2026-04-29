test_that("calc_mean works correctly", {
  expect_equal(calc_mean(c(1, 2, 3, 4, 5)), 3)
  expect_true(is.na(calc_mean(c())))
  expect_error(calc_mean("text"))
})

test_that("calc_median works correctly", {
  expect_equal(calc_median(c(1, 2, 3, 4, 5)), 3)
  expect_equal(calc_median(c(1, 2, 3, 4)), 2.5)
  expect_true(is.na(calc_median(c())))
})

test_that("calc_mode works correctly", {
  expect_equal(calc_mode(c(1, 2, 2, 3, 4)), 2)
  expect_equal(calc_mode(c(1, 2, 2, 3, 3)), c(2, 3))
  expect_true(is.na(calc_mode(c())))
})

test_that("calc_q1 works correctly", {
  expect_equal(calc_q1(c(1, 2, 3, 4, 5)), 2)
  expect_true(is.na(calc_q1(c())))
})

test_that("calc_q3 works correctly", {
  expect_equal(calc_q3(c(1, 2, 3, 4, 5)), 4)
  expect_true(is.na(calc_q3(c())))
})

test_that("calc_iqr works correctly", {
  expect_equal(calc_iqr(c(1, 2, 3, 4, 5)), 2)
  expect_true(is.na(calc_iqr(c())))
})
