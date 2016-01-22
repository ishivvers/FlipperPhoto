PRO crop_match, m, nmx
;+
; PRO crop_match, m, nmx
;
; FUNCTION - to allow you to reduce a match structure easily
;     
; INPUTS: m: the match structure in question
;         nmx: can be either the number of elements you wish to keep
;              (sequentially from zero) or an array of object index
;              numbers you wish to keep
;
; At this time, it will not allow you to eliminate observations, just objects
;
; CREATED: Don Smith - UM - 4/1/03
;          Eli Rykoff       02/23/04 -- works with new match strs
;-

  if n_params() eq 0 then begin
      print,'syntax- crop_match,m,nmx'
      return
  endif

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




  IF (size(nmx))[0] GT 0 THEN BEGIN
      keep = nmx
      nmx = n_elements(keep)
  ENDIF ELSE BEGIN 
      keep = lindgen(nmx)
  ENDELSE 

  make_match3_new,m2,nobs,nmx

  allnewobj = lindgen(nmx)

  m2.nobs = nobs
  m2.nobj = nmx

  m2.jd[allobs] = m.jd[allobs]
  m2.exptime[allobs] = m.exptime[allobs]
  m2.imagename[allobs] = m.imagename[allobs]

  for i=0l,nobs-1 do begin
      m2.kx[i,*,*] = m.kx[i,*,*]
      m2.ky[i,*,*] = m.ky[i,*,*]
  endfor
;;  m2.kx = m.kx
;;  m2.ky = m.ky

  m2.rac[allobs] = m.rac[allobs]
  m2.decc[allobs] = m.decc[allobs]
  m2.m_lim[allobs] = m.m_lim[allobs]
  m2.ral[allobs] = m.ral[allobs]
  m2.rah[allobs] = m.rah[allobs]
  m2.decl[allobs] = m.decl[allobs]
  m2.dech[allobs] = m.dech[allobs]
  
  for i=0l,nobs-1 do begin
      m2.m[i,allnewobj] = m.m[i,keep]
      m2.merr[i,allnewobj] = m.merr[i,keep]
      m2.flags[i,allnewobj] = m.flags[i,keep]
      m2.rflags[i,allnewobj] = m.rflags[i,keep]
      m2.dra[i,allnewobj] = m.dra[i,keep]
      m2.ddec[i,allnewobj] = m.ddec[i,keep]
      m2.msys[i,allnewobj] = m.msys[i,keep]
  endfor

;;  m2.m[allobs,allnewobj] = m.m[allobs,keep]
;;  m2.merr[allobs,allnewobj] = m.merr[allobs,keep]
;;  m2.flags[allobs,allnewobj] = m.flags[allobs,keep]
;;  m2.rflags[allobs,allnewobj] = m.rflags[allobs,keep]
;;  m2.dra[allobs,allnewobj] =   m.dra[allobs,keep]
;;  m2.ddec[allobs,allnewobj] =   m.ddec[allobs,keep]
;;  m2.msys[allobs,allnewobj] =   m.msys[allobs,keep]

  m2.ra[allnewobj] = m.ra[keep]
  m2.dec[allnewobj] =   m.dec[keep]
  m2.numobs[allnewobj] =   m.numobs[keep]
  m2.consec[allnewobj] =   m.consec[keep]
  m2.ngood[allnewobj] =   m.ngood[keep]
  m2.mavg[allnewobj] =   m.mavg[keep]
  m2.mstd[allnewobj] =   m.mstd[keep]
  
  m = m2

END
