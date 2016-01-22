PRO calc_diag_parms, m
;+
; NAME: CALC_DIAG_PARMS
;
; CALLING SEQUENCE: calc_diag_parms, m
;
; INPUTS:       m: a match structure
;       
; PROCEDURE:    The purpose of this function is to calculate various
;               diagnostic parameters from a completed match structure.
;       
; REVISION HISTORY:  
;       Don Smith       UM      10/24/01
;       Eli Rykoff      UM      02/23/04 -- works with new/old match strs
;====================================================================================
;-

;;  nobj = n_elements(m.m[0,*])
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



  output=findgen(5,nobj)
  FOR i=0L,nobj-1 DO BEGIN 
; First, determine the good observations
;;      j = where((m.flags[*,i] EQ 0 OR m.flags[*,i] EQ 2) AND m.m[*,i] GT 0
;;      AND m.m[*,i] LT 30.0)
      j = where((m.flags[allobs,i] eq 0 or m.flags[allobs,i] eq 2) and $
                m.m[allobs,i] gt 0 and m.m[allobs,i] lt 30.0)
      if ((size(j))[0] ne 0) then begin
          if ((size(j))[1] gt 2) then begin
              k=moment(m.m[j,i])
              output[0:3,i]=k
              output[4,i]=(size(j))[1]
          endif 
          if ((size(j))[1] eq 2) then begin
              output[0,i]=0.5*(m.m[j[0],i]+m.m[j[1],i])
              output[1,i]=m.m[j[0],i]-m.m[j[1],i]
              output[4,i]=(size(j))[1]
          ENDIF
          if ((size(j))[1] eq 1) then begin       
              output[0,i]=-1.5
              output[1,i]=0.0
              output[4,i]=0
          ENDIF        
      endif else begin
          output[0,i]=-2.0
          output[1,i]=0.0
          output[4,i]=0
      ENDELSE 
  ENDFOR 
  m.ngood[allobj] = output[4,*]
  m.mavg[allobj] = output[0,*]
  m.mstd[allobj] = output[1,*]
  pos = where (output[1,*] GE 0.0,npos)
  IF (npos GT 0) THEN m.mstd[pos] = sqrt(output[1,pos])
END
