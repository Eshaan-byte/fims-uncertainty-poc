# Selective ADREPORT — Proof of Concept

Standalone TMB example showing how `DATA_INTEGER` flags can gate `ADREPORT()` calls to control which derived quantities get standard errors.

This is the pattern used by [sdmTMB](https://github.com/pbs-assess/sdmTMB) and [WHAM](https://github.com/timjmiller/wham), and what I'm proposing for [FIMS issue #1241](https://github.com/NOAA-FIMS/FIMS/issues/1241).

## Quick start

```bash
cd poc/
Rscript run_poc.R
```

Requires R with TMB installed (`install.packages("TMB")`).

## What's here

- `selective_adreport.cpp` — TMB C++ template. Simple linear regression with 4 derived quantities. Each one has a `DATA_INTEGER` flag that controls whether it gets `ADREPORT()`'d. `REPORT()` always runs so point estimates are always available.
- `run_poc.R` — Compiles the model and runs it under 3 configs: all SEs, selective SEs, no SEs. Checks that point estimates are identical regardless of flags.

## Why this matters for FIMS

FIMS currently `ADREPORT()`s ~35 derived quantities unconditionally. The `sdreport()` cost scales with the number of ADREPORT'd values. This POC shows that gating with `DATA_INTEGER` flags lets you skip the expensive ones without touching point estimates.

See also:
- [TMB issue #174](https://github.com/kaskr/adcomp/issues/174) — discussion about selective sdreport
- [TMB issue #270](https://github.com/kaskr/adcomp/issues/270) — why flags must be DATA, not PARAMETER
