FUNCTION targ2lims, t
  l = t
  r = t[3] * t[2]
  IF r EQ 0 THEN r = 1.0
  l[2] = t[1] - r 
  l[3] = t[1] + r
  l[0] = t[0] - r / cos(!dpi * l[2] / 180.)
  l[1] = t[0] + r / cos(!dpi * l[3] / 180.)
  return, l
END
