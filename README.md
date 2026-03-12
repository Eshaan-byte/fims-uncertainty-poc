# Selective ADREPORT — Proof of Concept

Standalone TMB example showing how `DATA_INTEGER` flags can gate `ADREPORT()` calls. This is the pattern used by [sdmTMB](https://github.com/pbs-assess/sdmTMB) and [WHAM](https://github.com/timjmiller/wham), and what I'm proposing for [FIMS issue #1241](https://github.com/NOAA-FIMS/FIMS/issues/1241).

## How to run

```bash
Rscript run_poc.R
```

Needs R with TMB installed (`install.packages("TMB")`).

## What's here

- `selective_adreport.cpp` — TMB C++ template. Linear regression with 4 derived quantities, each gated by a `DATA_INTEGER` flag.
- `run_poc.R` — Compiles and runs the model under 3 configs (all SEs / selective / none). Checks that point estimates are identical regardless of flags.

## Sample output

```
Config 1: all SEs (current FIMS default)
  sdreport: 0.0080s, 1002 ADREPORT values

Config 2: SEs only for total_predicted and rmse
  sdreport: 0.0010s, 2 ADREPORT values

Config 3: no SEs (fast dev mode)
  sdreport: 0.0003s, 0 ADREPORT values

Point estimates match across all configs?
  total_predicted: TRUE
  rmse: TRUE
  predictions[1:5]: TRUE
```

## References

- [TMB issue #174](https://github.com/kaskr/adcomp/issues/174) — selective sdreport discussion
- [TMB issue #270](https://github.com/kaskr/adcomp/issues/270) — why flags must be DATA not PARAMETER
