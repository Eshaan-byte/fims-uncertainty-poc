# Selective ADREPORT - Proof of Concept

Standalone TMB example showing how `DATA_INTEGER` flags can gate `ADREPORT()` calls, with a character-vector interface and S4 validation on top. This is the approach used by [sdmTMB](https://github.com/pbs-assess/sdmTMB) and [WHAM](https://github.com/timjmiller/wham), and what I'm proposing for [FIMS issue #1241](https://github.com/NOAA-FIMS/FIMS/issues/1241).

## How to run

```bash
Rscript run_poc.R
```

Needs R with TMB installed (`install.packages("TMB")`).

## Files

- `selective_adreport.cpp` - TMB C++ template. Simple linear regression with 4 derived quantities, each gated by a `DATA_INTEGER` flag.
- `uncertainty_flags.R` - S4 `UncertaintyFlags` class with `set_true`/`set_false`, regex parsing, and conversion to integer flags.
- `run_poc.R` - Compiles and runs the model under 4 configs, benchmarks timing/memory, checks point estimates match.

## Design

Users pass a character vector to `report_uncertainty`:

- `"all"` - SEs for everything (current FIMS default)
- `"none"` - skip all SEs (fast diagnostic runs)
- `c("total_predicted", "rmse")` - only named quantities
- `"predict"` - regex matching (hits `predicted` + `total_predicted`)

Internally, the character input gets parsed into an S4 `UncertaintyFlags` object that validates names, does regex matching, and converts to `DATA_INTEGER` flags for TMB.

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

=== All assertions passed ===
```

Timing will vary by machine.

## References

- [TMB #174](https://github.com/kaskr/adcomp/issues/174) - selective sdreport discussion
- [TMB #270](https://github.com/kaskr/adcomp/issues/270) - why flags must be DATA not PARAMETER
- [FIMS #1241](https://github.com/NOAA-FIMS/FIMS/issues/1241) - the GSoC project issue
