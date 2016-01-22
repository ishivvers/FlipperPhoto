FUNCTION weight_mean, x, e
  s = total(x/e^2)
  n = total(1.0/e^2)
return, s/n
END 
