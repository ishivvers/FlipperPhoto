FUNCTION find_lims, c, f=f
  M_PI = 3.14159
  lims = fltarr(4)
  st = mrdfits(c,2)
  IF NOT keyword_set(f) THEN f = 2.0

  er = st.trig_err
  if (er gt 2.0) then er = 0.07

  lims[0] = st.trig_ra - f*er / cos(er * M_PI / 180.)
  lims[1] = st.trig_ra + f*er / cos(er * M_PI / 180.)
  lims[2] = st.trig_dec - f*er
  lims[3] = st.trig_dec + f*er
      

  return, lims
END
