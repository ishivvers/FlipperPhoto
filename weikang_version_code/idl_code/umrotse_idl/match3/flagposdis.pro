PRO flagposdis, m, cdelt
;+
; NAME: FLAGPOSDIS
;
; CALLING SEQUENCE: flagposdis, m, cdelt
;
; INPUTS:       m: the match structure to be processed
;               cdelt: the allowed deviation in a single object's position (deg)
;
; PROCEDURE:    Based on make_match_struct, this program will flag in "rflags" 
;                those observations that deviate more than cdelt from the mean.
;       
; REVISION HISTORY:  
;       Don Smith   UM      10/31/01
;       Don Smith   UM      11/13/01 - Changed dra/ddec to longs
;       Eli Rykoff          02/23/04 - works with new/old match strs
;====================================================================================
;-

  IF (N_params() LT 2) THEN $
    print, 'Syntax: flagposdis, m, cdelt' $
  ELSE BEGIN 
      if tag_exist(m,'nobs') then begin
          allobs = lindgen(m.nobs)
          allobj = lindgen(m.nobj)
          nobs = m.nobs
          nobj = m.nobj
      endif else begin
          allobs = lindgen(n_elements(m.jd))
          allobj = lindgen(n_elements(m.ra))
          nobs = n_elements(m.jd)
          nobj = n_elements(m.ra)
      endelse



;;      nobs = (size(m.m))[1]
      lra = long(m.ra[allobj]*1000000.)
      ldec = long(m.dec[allobj]*1000000.)
      FOR l = 0, nobs-1 DO BEGIN
          ddec = double(m.ddec[l,allobj]-ldec)/1000000.
          dra = double(m.dra[l,allobj]-lra)/1000000./cos(m.dec*!DTOR)
          gdobj = where(m.m[l,allobj] GT 0.0, count3)
          IF (count3 NE 0) THEN BEGIN
              dis = sqrt(dra[gdobj]^2.0 + ddec[gdobj]^2.0)
              badpos = where(dis gt cdelt, count4)
              IF (count4 NE 0) THEN BEGIN
                  tmparr = make_array(count4, /INT, value=set_flags3('BADPOS',type='RFLAGS'))
                  m.rflags[l,gdobj[badpos]] = m.rflags[l,gdobj[badpos]] OR tmparr
              ENDIF  
          ENDIF
      ENDFOR
  ENDELSE 
END
