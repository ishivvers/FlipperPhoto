FUNCTION find_sigma, x, xbar
  sig = sqrt(total((x - xbar)^2)/n_elements(x))
return, sig
END 
