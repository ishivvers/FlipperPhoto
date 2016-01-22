FUNCTION get_perc, perc, list
  x = sort(list)
  i = long(floor(perc/100. * n_elements(list)))
  return, list[x[i]]
END
