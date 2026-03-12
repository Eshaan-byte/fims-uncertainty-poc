// selective_adreport.cpp
// Minimal TMB model testing conditional ADREPORT with DATA_INTEGER flags.
// See: https://github.com/kaskr/adcomp/issues/174
// Model: y ~ N(a + b*x, sigma^2)

#include <TMB.hpp>

template<class Type>
Type objective_function<Type>::operator() ()
{
  DATA_VECTOR(y);
  DATA_VECTOR(x);
  DATA_INTEGER(n);

  // must be DATA_INTEGER not PARAMETER — TMB strips if-branches on parameters
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

  Type total_predicted = predicted.sum();

  Type ss = Type(0);
  for(int i = 0; i < n; i++) ss += resid(i) * resid(i);
  Type rmse = sqrt(ss / Type(n));

  Type nll = Type(0);
  for(int i = 0; i < n; i++){
    nll -= dnorm(y(i), predicted(i), sigma, true);
  }

  // point estimates always available
  REPORT(predicted);
  REPORT(resid);
  REPORT(total_predicted);
  REPORT(rmse);

  // SEs only for flagged quantities
  if(do_se_predicted)       ADREPORT(predicted);
  if(do_se_residuals)       ADREPORT(resid);
  if(do_se_total_predicted) ADREPORT(total_predicted);
  if(do_se_rmse)            ADREPORT(rmse);

  return nll;
}
