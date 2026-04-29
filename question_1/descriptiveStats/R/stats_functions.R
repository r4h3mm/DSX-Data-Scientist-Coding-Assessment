#' Calculate arithmetic mean
#'
#' @param x A numeric vector
#' @param na.rm Logical, whether to remove NA values. Default is TRUE
#' @return A single numeric value representing the mean
#' @examples
#' calc_mean(c(1, 2, 3, 4, 5))
#' @export
calc_mean <- function(x, na.rm = TRUE) {
  if (length(x) == 0) return(NA)
  if (!is.numeric(x)) stop("x must be a numeric vector")
  mean(x, na.rm = na.rm)
}

#' Calculate median
#'
#' @param x A numeric vector
#' @param na.rm Logical, whether to remove NA values. Default is TRUE
#' @return A single numeric value representing the median
#' @examples
#' calc_median(c(1, 2, 3, 4, 5))
#' @export
calc_median <- function(x, na.rm = TRUE) {
  if (length(x) == 0) return(NA)
  if (!is.numeric(x)) stop("x must be a numeric vector")
  median(x, na.rm = na.rm)
}

#' Calculate mode
#'
#' @param x A numeric vector
#' @param na.rm Logical, whether to remove NA values. Default is TRUE
#' @return A numeric vector of the most frequent value(s)
#' @examples
#' calc_mode(c(1, 2, 2, 3, 4))
#' @export
calc_mode <- function(x, na.rm = TRUE) {
  if (length(x) == 0) return(NA)
  if (!is.numeric(x)) stop("x must be a numeric vector")
  if (na.rm) x <- x[!is.na(x)]
  freq_table <- table(x)
  as.numeric(names(freq_table[freq_table == max(freq_table)]))
}

#' Calculate first quartile (Q1)
#'
#' @param x A numeric vector
#' @param na.rm Logical, whether to remove NA values. Default is TRUE
#' @return A single numeric value representing Q1
#' @examples
#' calc_q1(c(1, 2, 3, 4, 5))
#' @export
calc_q1 <- function(x, na.rm = TRUE) {
  if (length(x) == 0) return(NA)
  if (!is.numeric(x)) stop("x must be a numeric vector")
  unname(quantile(x, 0.25, na.rm = na.rm))
}

#' Calculate third quartile (Q3)
#'
#' @param x A numeric vector
#' @param na.rm Logical, whether to remove NA values. Default is TRUE
#' @return A single numeric value representing Q3
#' @examples
#' calc_q3(c(1, 2, 3, 4, 5))
#' @export
calc_q3 <- function(x, na.rm = TRUE) {
  if (length(x) == 0) return(NA)
  if (!is.numeric(x)) stop("x must be a numeric vector")
  unname(quantile(x, 0.75, na.rm = na.rm))
}

#' Calculate Interquartile Range (IQR)
#'
#' @param x A numeric vector
#' @param na.rm Logical, whether to remove NA values. Default is TRUE
#' @return A single numeric value representing the IQR (Q3 - Q1)
#' @examples
#' calc_iqr(c(1, 2, 3, 4, 5))
#' @export
calc_iqr <- function(x, na.rm = TRUE) {
  if (length(x) == 0) return(NA)
  if (!is.numeric(x)) stop("x must be a numeric vector")
  calc_q3(x, na.rm = na.rm) - calc_q1(x, na.rm = na.rm)
}
