# S4 class for per-quantity SE toggling

setClass("UncertaintyFlags", slots = list(
  predicted = "logical", residuals = "logical",
  total_predicted = "logical", rmse = "logical"
))

new_uncertainty_flags <- function() {
  new("UncertaintyFlags", predicted = FALSE, residuals = FALSE,
      total_predicted = FALSE, rmse = FALSE)
}

setGeneric("set_true", function(x, names) standardGeneric("set_true"))
setMethod("set_true", "UncertaintyFlags", function(x, names) {
  slots <- slotNames(x)
  targets <- if (identical(names, "all")) slots else names
  bad <- setdiff(targets, slots)
  if (length(bad)) stop("Unknown: '", bad[1], "'. Available: ", toString(slots))
  for (nm in targets) slot(x, nm) <- TRUE
  x
})

setGeneric("set_false", function(x, names) standardGeneric("set_false"))
setMethod("set_false", "UncertaintyFlags", function(x, names) {
  slots <- slotNames(x)
  if (identical(names, "all")) { for (s in slots) slot(x, s) <- FALSE; return(x) }
  bad <- setdiff(names, slots)
  if (length(bad)) stop("Unknown: '", bad[1], "'. Available: ", toString(slots))
  for (s in names) slot(x, s) <- FALSE
  x
})

flags_to_integers <- function(obj) {
  setNames(
    lapply(slotNames(obj), function(s) as.integer(slot(obj, s))),
    paste0("do_se_", slotNames(obj))
  )
}

list_derived_quantities <- function(obj = NULL) {
  qty <- c("predicted", "residuals", "total_predicted", "rmse")
  if (!is.null(obj) && is(obj, "UncertaintyFlags"))
    return(sapply(qty, function(s) slot(obj, s)))
  qty
}

parse_report_uncertainty <- function(input) {
  flags <- new_uncertainty_flags()
  slots <- slotNames(flags)
  if (identical(input, "all")) return(set_true(flags, "all"))
  if (identical(input, "none")) return(flags)
  if (!is.character(input))
    stop("report_uncertainty must be 'all', 'none', or character vector")
  matched <- unique(unlist(lapply(input, function(p) grep(p, slots, value = TRUE))))
  if (!length(matched)) stop("No quantities matched. Available: ", toString(slots))
  set_true(flags, matched)
}
