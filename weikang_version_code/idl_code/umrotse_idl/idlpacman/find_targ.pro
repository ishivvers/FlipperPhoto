FUNCTION find_targ, c, s=s, f=f
  targ = dblarr(4)
  IF NOT keyword_set(s) THEN s = mrdfits(c,2)
  IF NOT keyword_set(f) THEN f = 1.5
  targ[0] = s.trig_ra 
  targ[1] = s.trig_dec
  targ[2] = s.trig_err
  targ[3] = f
  return, targ
END
