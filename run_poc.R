# run_poc.R — Updated POC with character vector + S4 class + benchmarks
library(TMB)
source("uncertainty_flags.R")

compile("selective_adreport.cpp")
dyn.load(dynlib("selective_adreport"))

set.seed(123)
n <- 500; x <- seq(0, 10, length.out = n)
y <- 2 + 1.5 * x + rnorm(n, sd = 1)

fit_model <- function(y, x, report_uncertainty = "all") {
  flags <- parse_report_uncertainty(report_uncertainty)
  dat <- c(list(y = y, x = x, n = as.integer(length(y))), flags_to_integers(flags))
  obj <- MakeADFun(dat, list(a = 0, b = 0, log_sigma = 0),
                   DLL = "selective_adreport", silent = TRUE)
  opt <- nlminb(obj$par, obj$fn, obj$gr)
  t0 <- proc.time()
  sdr <- sdreport(obj, getReportCovariance = FALSE)
  dt <- (proc.time() - t0)["elapsed"]
  sdr_sum <- summary(sdr, select = "report")
  list(report = obj$report(), sdr = sdr_sum, time = dt,
       memory_kb = as.numeric(object.size(sdr)) / 1024,
       n_adreport = nrow(sdr_sum), flags = flags)
}

# --- Three configs ---
r1 <- fit_model(y, x, "all")
r2 <- fit_model(y, x, c("total_predicted", "rmse"))
r3 <- fit_model(y, x, "none")

# --- Regex demo ---
r4 <- fit_model(y, x, "predict")  # matches predicted + total_predicted

# --- Benchmarks ---
cat("\n=== Benchmark Results ===\n")
cat(sprintf("%-28s %8s %10s %8s\n", "Config", "Time(s)", "Mem(KB)", "Values"))
for (r in list(
  list("all", r1), list("c('total_predicted','rmse')", r2),
  list("none", r3), list("regex: 'predict'", r4)
)) cat(sprintf("%-28s %8.4f %10.1f %8d\n", r[[1]], r[[2]]$time, r[[2]]$memory_kb, r[[2]]$n_adreport))

# --- Point estimate verification ---
cat("\n=== Point Estimates Identical? ===\n")
cat("  total_predicted:", all.equal(r1$report$total_predicted, r3$report$total_predicted), "\n")
cat("  rmse:           ", all.equal(r1$report$rmse, r3$report$rmse), "\n")

# --- Validation demo ---
cat("\n=== Validation ===\n")
cat("Misspelled name: ")
tryCatch(parse_report_uncertainty("spawning_biomass"),
         error = function(e) cat(e$message, "\n"))
cat("list_derived_quantities(): ", toString(list_derived_quantities()), "\n")
cat("Flags after c('rmse'):      "); print(list_derived_quantities(r2$flags))
cat("set_false('rmse'):          "); print(list_derived_quantities(set_false(new_uncertainty_flags(), "rmse")))

dyn.unload(dynlib("selective_adreport"))
