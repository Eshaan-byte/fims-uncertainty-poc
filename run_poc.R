# run_poc.R
# Testing selective ADREPORT gating with DATA_INTEGER flags.
# Run: Rscript run_poc.R

library(TMB)

compile("selective_adreport.cpp")
dyn.load(dynlib("selective_adreport"))

set.seed(123)
n <- 500
x <- seq(0, 10, length.out = n)
y <- 2 + 1.5 * x + rnorm(n, sd = 1)

fit_model <- function(y, x, report_uncertainty = "all") {
  n <- length(y)
  qty_names <- c("predicted", "residuals", "total_predicted", "rmse")

  if (identical(report_uncertainty, "all")) {
    flags <- setNames(rep(1L, 4), qty_names)
  } else if (identical(report_uncertainty, "none")) {
    flags <- setNames(rep(0L, 4), qty_names)
  } else {
    flags <- setNames(rep(0L, 4), qty_names)
    for (nm in names(report_uncertainty)) {
      if (!nm %in% qty_names) stop("unknown quantity: ", nm)
      flags[nm] <- as.integer(report_uncertainty[[nm]])
    }
  }

  dat <- list(
    y = y, x = x, n = as.integer(n),
    do_se_predicted       = flags["predicted"],
    do_se_residuals       = flags["residuals"],
    do_se_total_predicted = flags["total_predicted"],
    do_se_rmse            = flags["rmse"]
  )
  pars <- list(a = 0, b = 0, log_sigma = 0)

  obj <- MakeADFun(dat, pars, DLL = "selective_adreport", silent = TRUE)
  opt <- nlminb(obj$par, obj$fn, obj$gr)

  t0 <- proc.time()
  sdr <- sdreport(obj, getReportCovariance = FALSE)
  dt <- (proc.time() - t0)["elapsed"]

  list(
    opt = opt,
    report = obj$report(),
    sdr = summary(sdr, select = "report"),
    time = dt,
    n_adreport = nrow(summary(sdr, select = "report"))
  )
}

# --- three configs ---

cat("Config 1: all SEs (current FIMS default)\n")
r1 <- fit_model(y, x, "all")
cat(sprintf("  sdreport: %.4fs, %d ADREPORT values\n\n", r1$time, r1$n_adreport))

cat("Config 2: SEs only for total_predicted and rmse\n")
r2 <- fit_model(y, x, list(total_predicted = TRUE, rmse = TRUE))
cat(sprintf("  sdreport: %.4fs, %d ADREPORT values\n\n", r2$time, r2$n_adreport))

cat("Config 3: no SEs (fast dev mode)\n")
r3 <- fit_model(y, x, "none")
cat(sprintf("  sdreport: %.4fs, %d ADREPORT values\n\n", r3$time, r3$n_adreport))

# --- the important check ---
cat("Point estimates match across all configs?\n")
cat(sprintf("  total_predicted: %s\n",
    all.equal(r1$report$total_predicted, r3$report$total_predicted)))
cat(sprintf("  rmse: %s\n",
    all.equal(r1$report$rmse, r3$report$rmse)))

# check predictions vector too
cat(sprintf("  predictions[1:5]: %s\n",
    all.equal(r1$report$predicted[1:5], r3$report$predicted[1:5])))

dyn.unload(dynlib("selective_adreport"))
