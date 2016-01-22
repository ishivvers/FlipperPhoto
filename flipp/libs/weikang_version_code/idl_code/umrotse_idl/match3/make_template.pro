FUNCTION make_template, n1, n2=n2
  IF (size(n1))[0] GT 0 THEN n1 = n1[0]
  c1 = mrdfits(n1,1)
  ng = n_elements(c1)
  nra = c1.ra
  ndec = c1.dec

  IF keyword_set(n2) THEN BEGIN 
      IF (size(n2))[0] GT 0 THEN n2 = n2[0]
      c2 = mrdfits(n2,1)
      close_match_radec, c1.ra, c1.dec, c2.ra, c2.dec, m1, m2, 0.0009d, 1, miss,/box
      nra = (c1[m1].ra+c2[m2].ra)/2.
      ndec = (c1[m1].dec+c2[m2].dec)/2.
      ng = n_elements(m1)
  ENDIF 

  flst = dblarr(2,ng)
  flst[0,*] = nra
  flst[1,*] = ndec
  
  return, flst
END 
