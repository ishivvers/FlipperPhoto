function varmonitor_make_struct,iobs,old=old,fail=fail

;+
; NAME: VARMONITOR_MAKE_STRUCT
;
; CALLING SEQUENCE: varmonitor_make_struct, iobs, old=old
;
; INPUTS:       iobs: number of observations
;
; OUTPUTS:      the new variable monitor structure
;       
; INPUT KEYWORDS:
;               old: if there is an old variable monitor structure to start with.
;                       
; PROCEDURE:    This program will create and initialize
;               a variable monitor
;
;==========================================================================
;-

fail = 0

if n_params() lt 1 then begin
    print,'syntax: varstr = varmonitor_make_struct(iobs,old=old,fail=fail)'
    fail = 1
    return,-1
endif

nobs=n_elements(iobs)

if ((n_elements(old) eq 0) and (nobs ne 1)) then begin
    print,'cannot filter old variable montior structure.'
    fail = 1
    return,-1
endif

if keyword_set(old) then begin
    i_obs = iobs
    if (nobs eq 1) then begin
        nobs = iobs
        nobs_cp = (size(old.jd))[1] < iobs
        i_obs = indgen(nobs_cp)
    endif else begin
        nobs = n_elements(i_obs)
        nobs_cp = nobs
    endelse
endif else begin
    nobs = iobs
endelse

;; create a new varstr and initialize values
    
varstr = create_struct("name",'',"position",'',"othername",'', $
                    "ra",0.0d,"dec",0.0d,$
                    "nobs",0l,"jd",dblarr(nobs),$
                    "iobj",lonarr(nobs),$
                    "imagename",sindgen(nobs),$
                    "m", fltarr(nobs), "merr", fltarr(nobs),$
                    "flags",lonarr(nobs),"rflags", bytarr(nobs),$
                    "msys", bytarr(nobs),"m_lim",fltarr(nobs))

varstr.m[*] = -1.0
varstr.merr[*] = -1.0
varstr.flags[*] = -1
varstr.rflags[*] = 0
varstr.msys[*] = 0
varstr.m_lim[*] = 0.0

;; if an old varstr was input, copy into new structure

IF keyword_set(old) THEN BEGIN
    varstr.name=old.name
    varstr.position=old.position
    varstr.othername=old.othername
    varstr.ra=old.ra
    varstr.dec=old.dec
    
    varstr.nobs=old.nobs
    
    varstr.jd = old.jd[i_obs]
    varstr.imagename = old.imagename[i_obs]
    varstr.iobj = old.iobj[i_obs]     
    varstr.m = old.m[i_obs]
    varstr.merr = old.merr[i_obs]
    varstr.flags = old.flags[i_obs]
    varstr.rflags = old.rflags[i_obs]
    varstr.msys = old.msys[i_obs]
    varstr.m_lim = old.m_lim[i_obs]
ENDIF

return,varstr

end
