#' Compare traditional, max, and second generation P-values across studies
#'
#' @param data Data frame with two variables `xbar` and `se`.
#' @param delta_lb Numeric. Lower bound of the indifference zone
#' @param delta_ub Numeric. Upper bound of the indifference zone
#' @param h0 Numeric. Value of the null hypothesis
#' @param plot Logical. Whether to produce a plot of the study values with the
#'   indifference zone (default = `TRUE`).
#'
#' @return data frame with the following columns:
#'  * xbar: Mean corresponding to the input `xbar` value
#'  * se: Standard error corresponding to the input `se` value
#'  * lb: Lower bound of the effect (95% CI)
#'  * ub: Upper bound of the effect (95% CI)
#'  * p_old: Traditional P-value
#'  * p_max: Maximum P-value over the interval null
#'  * p_new: Second Generation P-value
#'
#'  If `plot = TRUE` (default), will also output a plot of the studies with the
#'  indifference zone.
#' @export
#'
#' @examples
#' ## Figure 2 from the second generation P-value paper
#' data <- data.frame(
#'   xbar = c(146, 145.5, 145, 146, 144, 143.5, 142, 141),
#'   se = c(0.5, 0.25, 1.25, 2.25, 1, 0.5, 1, 0.5)
#'   )
#' compare_p(data, delta_lb = 144, delta_ub = 148, h0 = 146)
compare_p <- function(data, delta_lb, delta_ub, h0, plot = TRUE) {
  if (!is.data.frame(data) || !(c("xbar", "se") %in% names(data))) {
    stop("Parameter `data` must be a data frame with columns:\n  * xbar\n  * se", call. = FALSE)
  }

  if (!(delta_lb < h0 && h0 < delta_ub)) {
    stop("`delta_lb` must be less than `h0` which must be less than `delta_ub`", call. = FALSE)
  }

  data$lb <- data$xbar - 1.96 * data$se
  data$ub <- data$xbar + 1.96 * data$se
  z1 <- (data$xbar - h0) / data$se

  p_old <- round(2 * stats::pnorm(- abs(z1)), 5)

  z2 <- ifelse(abs(data$xbar - delta_ub) < abs(data$xbar - delta_lb),
               (data$xbar - delta_ub) / data$se,
               (data$xbar - delta_lb) / data$se)

  z2 <- ifelse(data$xbar > delta_ub | delta_lb > data$xbar,
               z2,
               0)

  p_max <- round(2 * stats::pnorm(- abs(z2)), 5)

  p_new <- purrr::map2_dbl(data$lb,
                           data$ub,
                           p_delta,
                           delta_lb = delta_lb,
                           delta_ub = delta_ub
  )

  if (plot) {
    graphics::plot(c(data$xbar, NA),
         1:(length(data$xbar) + 1),
         xlim = c(min(data$lb) - 2, max(data$ub, delta_ub)),
         xaxt = "n",
         yaxt = "n",
         ylab = "",
         xlab = "",
         type = "n")
    graphics::axis(side = 1,
         at = seq(round(min(data$lb, delta_lb)),
                  round(max(data$ub, delta_ub)),
                  delta_ub - h0)
    )

    graphics::rect(delta_lb,
         length(data$xbar) + 1,
         delta_ub,
         0,
         col = grDevices::rgb(208, 216, 232, max = 255),
         border = NA)

    graphics::abline(v = h0,
           lty = 2,
           lwd = 2,
           col = "black")

    steps = seq(nrow(data), 1)
    study_name <- paste("Study", steps)
    for  (i in steps){
      graphics::points(data$xbar[i], nrow(data) - i + 1, pch=16)
      graphics::lines(c(data$lb[i], data$ub[i]), c(nrow(data) - i + 1, nrow(data) - i + 1), lwd = 1.5)
      graphics::text(min(data$lb) - 1.2, i, study_name[i], font = 2)
    }
  }
  data.frame(xbar = data$xbar,
             se = data$se,
             lb = data$lb,
             ub = data$ub,
             p_old = p_old,
             p_max = p_max,
             p_new = p_new)
}
