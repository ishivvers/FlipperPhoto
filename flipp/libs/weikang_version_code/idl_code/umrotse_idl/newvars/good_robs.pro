FUNCTION good_robs, m, i, uf, urf
  
  nobs = m.nobs
  nobj = m.nobj
  passarr = bytarr(nobs)
  passarr = passarr*0 + 1

  pair1=indgen(nobs/2.0)*2.0
  pair2=pair1+1

; First, throw out all -1 or -2 magnitudes
  neg = where(m.m[0:nobs-1,i] LT 0,nbad)
  IF nbad GT 0 THEN passarr[neg] = 0

; Second, test the sextractor flags
  k = 1
  FOR sf=0,n_elements(uf)-1 DO BEGIN 
      IF uf[sf] EQ 1 THEN BEGIN
          z = m.flags[0:nobs-1,i] AND k
          IF sf NE 1 THEN BEGIN ; blends will be tested later 
              q = where(z NE 0,nq)
              IF nq GT 0 THEN passarr[q] = 0
          ENDIF
      ENDIF 
      k = k * 2
  ENDFOR 

; Now check the rflags
  k = 1
  FOR sf=0,n_elements(urf)-1 DO BEGIN 
      IF urf[sf] EQ 1 THEN BEGIN
          z = m.rflags[0:nobs-1,i] AND k
          q = where(z NE 0,nq)
          IF nq GT 0 THEN passarr[q] = 0
      ENDIF 
      k = k * 2
  ENDFOR 

; If one element of a pair fails, both should be tossed.
  pass1 = where(passarr[pair1] EQ 0, n)
  IF n GT 0 THEN passarr[pair2[pass1]] = 0
  pass2 = where(passarr[pair2] EQ 0, n)
  IF n GT 0 THEN passarr[pair1[pass2]] = 0

; Finally, check for blending problems with the obs that pass so far.
; I don't trust this algorithm. 
;  IF uf[1] EQ 1 THEN BEGIN
;      mags = m.m[*,i]
;      mwer = sqrt(m.merr[*,i]^2 + (float(m.msys[*,i])/200.)^2)
;      good = where(passarr EQ 1,ng)
;      IF ng GT 0 THEN BEGIN 
;          z = m.flags[good,i] AND 2
;          nobl = where(z EQ 0,nq)
;          IF nq GT 0 AND nq LT n_elements(z) THEN BEGIN ; if not all are 2 or 0
;              bl = where(z EQ 2)
;              mnob = weight_mean(mags[good[z[nobl]]],mwer[good[z[nobl]]])
;              mbl  = weight_mean(mags[good[z[bl]]],mwer[good[z[bl]]])
;              typ = mean(mwer[good])

;              IF (mnob - mbl)/3.0 GT typ THEN $; if the diff is three times the typical
;                passarr[*] = 0                    ; error, toss the whole object
;          ENDIF 
;      ENDIF 
;  ENDIF 

return, passarr
END
