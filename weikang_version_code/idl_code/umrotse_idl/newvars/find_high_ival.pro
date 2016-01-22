PRO  find_high_ival, ival, numdev
  high = where(ival.ival GT numdev*ival.siglim,nh)
  IF nh GT 0 THEN ival[high].tophase = ival[high].tophase + 1
END 
