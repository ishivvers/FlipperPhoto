PRO flag_consec, m
;+
; NAME: FLAG_CONSEC
;
; CALLING SEQUENCE: flag_consec, m, allstats
;
; INPUTS:       m: a match structure
;               allstats: the array of stat structures
;
; REVISION HISTORY:  
;       Don Smith      UM      10/23/01
;       Eli Rykoff             02/23/04 - works with new/old match strs
;================================================================================
;-

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


;;  nobs = n_elements(m.imagename)
  FOR k = 0,nobs-1 DO BEGIN
      find_consec,m.jd[k],m.jd,iconsec
        num_consec = (size(iconsec))[1]
        IF ((size(iconsec))[0] NE 0 AND num_consec GT 0) THEN BEGIN
           try_consec = where(m.consec[allobj] EQ 0 AND $
                              m.m[k,allobj] GT -1.0 , count)
           IF (count GT 0) THEN BEGIN
               FOR l = 0,num_consec-1 DO BEGIN
                   index = where(m.m[iconsec[l],try_consec] GT -1.0, count)
                   IF (count GT 0) THEN m.consec[try_consec[index]] = 1
               ENDFOR
           ENDIF
       ENDIF
   ENDFOR
END 
