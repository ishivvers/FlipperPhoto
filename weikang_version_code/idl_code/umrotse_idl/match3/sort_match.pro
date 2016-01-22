PRO sort_match, old, new, os, ns

 if n_params() lt 4 then begin
     print,'syntax- sort_match, old, new, os, ns'
     return
 endif

 if tag_exist(old,'nobs') then begin
     allobs = lindgen(old.nobs)
     allobj = lindgen(old.nobj)
     nobs = old.nobs
     nobj = old.nobj
 endif else begin
     allobs = lindgen(n_elements(old.jd))
     allobj = lindgen(n_elements(old.ra))
     nobs = n_elements(old.jd)
     nobj = n_elements(old.ra)
 endelse
 

  t = sort(old.jd[allobs])
  new = old
  ns = os[t]

  new.jd[allobs] = old.jd[t]
  new.exptime[allobs] = old.exptime[t]
  new.imagename[allobs] = old.imagename[t]
  new.rac[allobs] = old.rac[t]
  new.decc[allobs] = old.decc[t]
  new.m_lim[allobs] = old.m_lim[t]
;;  FOR s = 0,n_elements(old.ngood)-1 DO BEGIN 
  for s=0l,nobj-1 do begin
      new.m[allobs,s] = old.m[t,s]
      new.merr[allobs,s] = old.merr[t,s]
      new.flags[allobs,s] = old.flags[t,s]
      new.dra[allobs,s] = old.dra[t,s]
      new.ddec[allobs,s] = old.ddec[t,s]
      new.rflags[allobs,s] = old.rflags[t,s]
      new.msys[allobs,s] = old.msys[t,s]
  ENDFOR
  FOR i=0,3 DO BEGIN  
      FOR j=0,3 DO BEGIN 
          new.kx[allobs,i,j] = old.kx[t,i,j]
          new.ky[allobs,i,j] = old.ky[t,i,j]
      ENDFOR 
  ENDFOR 
END 
