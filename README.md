# Selective ADREPORT — Proof of Concept

Standalone TMB example showing how `DATA_INTEGER` flags can gate `ADREPORT()` calls, controlled by a character vector interface with S4 validation. This is the pattern used by [sdmTMB](https://github.com/pbs-assess/sdmTMB) and [WHAM](https://github.com/timjmiller/wham), and what I'm proposing for [FIMS issue #1241](https://github.com/NOAA-FIMS/FIMS/issues/1241).

## How to run

```bash
Rscript run_poc.R
```

Needs R with TMB installed (`install.packages("TMB")`).

## What's here

| File | Description |
|------|-------------|
| `selective_adreport.cpp` | TMB C++ template. Linear regression (`y ~ a + b*x`) with 4 derived quantities (`predicted`, `residuals`, `total_predicted`, `rmse`), each gated by a `DATA_INTEGER` flag. |
| `uncertainty_flags.R` | S4 `UncertaintyFlags` class with `set_true`/`set_false` methods, regex-based `parse_report_uncertainty()`, and `flags_to_integers()` converter. |
| `run_poc.R` | Compiles and runs the model under 4 configs with timing and memory benchmarks. Verifies point estimates are identical regardless of SE flags. |

## Design

Users pass a character vector to `report_uncertainty`:

- `"all"` — compute SEs for every derived quantity (current FIMS default)
- `"none"` — skip all SEs (fast diagnostic mode)
- `c("total_predicted", "rmse")` — compute SEs only for named quantities
- `"predict"` — regex match (matches `predicted` and `total_predicted`)

The character vector is parsed into an S4 `UncertaintyFlags` object that validates names, supports regex patterns, and converts to `DATA_INTEGER` flags for TMB.

## Sample output

```
=== Benchmark Results ===
Config                        Time(s)    Mem(KB)   Values
all                            0.0690       26.8     1002
c('total_predicted','rmse')    0.0020        3.3        2
none                           0.0010        3.0        0
regex: 'predict'               0.0250       15.0      501

=== Point Estimates Identical? ===
  total_predicted: TRUE
  rmse:            TRUE

=== Validation ===
Misspelled name: No quantities matched. Available: predicted, residuals, total_predicted, rmse
list_derived_quantities():  predicted, residuals, total_predicted, rmse

=== All assertions passed ===
```

*Note: Timing numbers are approximate and will vary by machine.*

## References

- [TMB issue #174](https://github.com/kaskr/adcomp/issues/174) — selective sdreport discussion
- [TMB issue #270](https://github.com/kaskr/adcomp/issues/270) — why flags must be DATA not PARAMETER
- [FIMS issue #1241](https://github.com/NOAA-FIMS/FIMS/issues/1241) — the GSoC project issue
