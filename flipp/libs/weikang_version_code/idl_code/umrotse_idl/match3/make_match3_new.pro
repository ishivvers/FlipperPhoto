pro make_match3_new,match,iobs,iobj,useold=useold,migrate=migrate
;+
;; NAME: MAKE_MATCH3_NEW
;;
;;  This program replaces the make_match3 function for new-style match
;;  structures
;;
;; CALLING SEQUENCE: make_match3_new,match,iobs,iobj,useold=useold,
;;                   migrate=migrate
;;
;; INPUTS: match: match structure (used if /useold is set)
;;         iobs:  number of observations
;;         iobj:  number of objects
;;
;; OUTPUTS: match: the new match structure
;;
;; KEYWORDS: useold: use the old match structure (passed in match)
;;           migrate: migrate an old-style match structure to a new-style one
;;
;; PROCEDURE: based on make_match3.  Now, improved memory usage, faster match
;; structure creation, etc.
;;
;; REVISION HISTORY:
;;      Eli Rykoff     UM     02/23/04
;;      Don Smith      UM     05/12/04 - Made nobj and nobs long ints, so they wouldn't cause crash.
;; 
;-

if n_params() lt 3 then begin
    print,'syntax- make_match3_new,match,iobs,iobj,useold=useold,migrate=migrate'
    return
endif

if n_elements(iobs) ne 1 then begin
    print,'must specify iobs'
    return
endif
if n_elements(iobj) ne 1 then begin
    print,'must specify iobj'
    return
endif
if n_elements(match) ne 1 and keyword_set(useold) then begin
    print,'must give an old match structure if useold is set'
    return
endif

if keyword_set(migrate) then begin
    if (tag_exist(match,'NOBJ')) then begin
        print,'Cannot migrate a new style match structure!'
        return
    endif
endif

; check if we have anything to do

make_new_match = 0

if keyword_set(useold) then begin
    nobj_slots = n_elements(match.ra)
    nobs_slots = n_elements(match.jd)

    if keyword_set(migrate) then begin
        nobj_cp = nobj_slots
        nobs_cp = nobs_slots
        nobj_slots = 1
        nobs_slots = 1
    endif

    if ((iobj gt nobj_slots) or (iobs gt nobs_slots)) then begin
        make_new_match = 1
        if not keyword_set(migrate) then begin
            nobj_cp = match.nobj
            nobs_cp = match.nobs
        endif

        nobj = nobj_slots
        while (nobj lt iobj) do nobj = nobj * 2
        
        nobs = nobs_slots
        while (nobs lt iobs) do nobs = nobs * 2

        i_obs = lindgen(nobs_cp)
        i_obj = lindgen(nobj_cp)
    endif
    
    if (make_new_match) then old = match
endif else begin
    ;; brand new match structure
    ;; want multiple of 2

    make_new_match = 1
    nobs = 1l
    while (nobs lt iobs) do nobs = nobs * 2l
    nobj = 1l
    while (nobj lt iobj) DO nobj = nobj * 2l
endelse

; create new match structure and initialize values
if make_new_match then begin
  
    match = create_struct("nobs", -1l, "nobj", -1l, $
                          "kx", fltarr(nobs,4,4) - 1.0, $
                          "ky", fltarr(nobs,4,4) - 1.0, $
                          "jd", dblarr(nobs) - 1.0, $
                          "exptime", fltarr(nobs) - 1.0, $
                          "imagename", strarr(nobs), $
                          "rac", fltarr(nobs) - 1.0, $
                          "decc", fltarr(nobs) - 1.0, $
                          "ral", 0.0, "rah", 0.0, "decl", 0.0, "dech", 0.0, $
                          "m", fltarr(nobs,nobj) - 1.0, $
                          "merr", fltarr(nobs,nobj) - 1.0, $
                          "flags", intarr(nobs,nobj) - 1, $
                          "dra", lonarr(nobs,nobj), $
                          "ddec", lonarr(nobs,nobj), $
                          "rflags", bytarr(nobs,nobj), $
                          "msys", bytarr(nobs,nobj), $
                          "ra", dblarr(nobj), $
                          "dec", dblarr(nobj), $
                          "numobs", intarr(nobj), $
                          "consec", bytarr(nobj), $
                          "ngood", intarr(nobj), $
                          "mavg", fltarr(nobj) - 1.0, $
                          "mstd", fltarr(nobj) - 1.0, $
                          "m_lim", fltarr(nobs) - 1.0)

    if keyword_set(useold) then begin
        for k=0l,nobs_cp-1 do begin
            match.kx[k,*,*] = old.kx[i_obs[k],*,*]
            match.ky[k,*,*] = old.ky[i_obs[k],*,*]
        endfor
        match.jd = old.jd[i_obs]
        match.m_lim = old.m_lim[i_obs]
        match.exptime = old.exptime[i_obs]
        match.imagename = old.imagename[i_obs]
        match.rac = old.rac[i_obs]
        match.decc = old.decc[i_obs]
        match.ral = old.ral
        match.rah = old.rah
        match.decl = old.decl
        match.dech = old.dech
        for k = 0,nobs_cp-1 do begin
            match.m[k,0L:nobj_cp-1L] = old.m[i_obs[k], i_obj[0L:nobj_cp-1L]]
            match.merr[k,0L:nobj_cp-1L] = old.merr[i_obs[k], i_obj[0L:nobj_cp-1L]]
            match.flags[k,0L:nobj_cp-1L] = old.flags[i_obs[k], i_obj[0L:nobj_cp-1L]]
            match.dra[k,0L:nobj_cp-1L] = old.dra[i_obs[k], i_obj[0L:nobj_cp-1L]]
            match.ddec[k,0L:nobj_cp-1L] = old.ddec[i_obs[k], i_obj[0L:nobj_cp-1L]]
            match.rflags[k,0L:nobj_cp-1L] = old.rflags[i_obs[k], i_obj[0L:nobj_cp-1L]]
            match.msys[k,0L:nobj_cp-1L] = old.msys[i_obs[k], i_obj[0L:nobj_cp-1L]]
        endfor
        match.ra = old.ra[i_obj]
        match.dec = old.dec[i_obj]
        match.numobs = old.numobs[i_obj]
        match.consec = old.consec[i_obj]
        match.ngood = old.ngood[i_obj]
        match.mavg = old.mavg[i_obj]
        match.mstd = old.mstd[i_obj]
    endif

    if keyword_set(migrate) then begin
        match.nobs = nobs_cp
        match.nobj = nobj_cp
    endif
endif 

return
end
