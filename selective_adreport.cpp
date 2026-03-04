// selective_adreport.cpp
// Minimal TMB model to test conditional ADREPORT with DATA_INTEGER flags.
// Based on the approach described in https://github.com/kaskr/adcomp/issues/174
// and used by sdmTMB, WHAM, etc.
//
// Model: y ~ N(a + b*x, sigma^2)
// Derived quantities: predicted values, residuals, total_predicted, rmse

#include <TMB.hpp>

template<class Type>
Type objective_function<Type>::operator() ()
{
  DATA_VECTOR(y);
  DATA_VECTOR(x);
  DATA_INTEGER(n);

  // flags to toggle which derived quantities get SEs
  // Important: must be DATA_INTEGER, not PARAMETER —
  // TMB strips if-branches that depend on parameters (see TMB issue #270)
  DATA_INTEGER(do_se_predicted);
  DATA_INTEGER(do_se_residuals);
  DATA_INTEGER(do_se_total_predicted);
  DATA_INTEGER(do_se_rmse);

  PARAMETER(a);
  PARAMETER(b);
  PARAMETER(log_sigma);

  Type sigma = exp(log_sigma);

  vector<Type> predicted(n);
  vector<Type> resid(n);
  for(int i = 0; i < n; i++){
    predicted(i) = a + b * x(i);
    resid(i) = y(i) - predicted(i);
  }

  // aggregate quantities (like SSB or Fbar in a stock assessment)
  Type total_predicted = predicted.sum();

  Type ss = Type(0);
  for(int i = 0; i < n; i++) ss += resid(i) * resid(i);
  Type rmse = sqrt(ss / Type(n));

  // nll
  Type nll = Type(0);
  for(int i = 0; i < n; i++){
    nll -= dnorm(y(i), predicted(i), sigma, true);
  }

  // always report point estimates — this has no sdreport cost
  REPORT(predicted);
  REPORT(resid);
  REPORT(total_predicted);
  REPORT(rmse);

  // only ADREPORT the ones we actually want SEs for
  if(do_se_predicted)       ADREPORT(predicted);
  if(do_se_residuals)       ADREPORT(resid);
  if(do_se_total_predicted) ADREPORT(total_predicted);
  if(do_se_rmse)            ADREPORT(rmse);

  return nll;
}
