pro fill_lightcurve, pars, mlim, type, seed, match
;+
; NAME: Fill Lightcurve
;
; PURPOSE:
;	calculate lightcurve values at each epoch
;
; CALLING SEQUENCE:
;       fill_lightcurve, pars, mlim, type, seed, match
;
; INPUTS:
;	pars:		parameters defining lighturve
;	mlim:		limiting magnitude for each object position in each 
;			observation
;	type:		type of lightcurve to generate
;	seed:		starting seed for random number generation
;
; OUTPUT: 
;	match:  structure containing lightcurves of various objects
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	9/19/00
;	Bob Kehoe	UM	11/30/00  -- improve way deal with orphans data
;-
 On_error,2              ;Return to caller

 if N_params() lt 2 then begin
    print, 'Syntax:  fill_lightcurve, pars, mlim, type, seed, match'
    return
 endif

; Generate lightcurves

 nobs = (size(match.m))[1]
 nobj = (size(match.m))[2]
 times = 3600.0*24.0*(match.jd-match.jd[0])
 endtimes = fltarr(nobs)
 endtimes[0:nobs-2] = times[1:nobs-1]  
 starttime = times[nobs-1]*randomu(seed,nobj)
 for l = 0L, nobj-1L do begin
    startobs = (where(times lt starttime[l] and endtimes gt starttime[l]))[0]
    diff = abs(starttime[l] - times[startobs] - match.exptime[startobs])
    if (diff lt 10.0 and startobs lt (nobs-1)) then startobs = startobs + 1
    thesetimes = times[startobs:nobs-1] - times[startobs] + 10.0
    diff = abs(starttime[l] - times[startobs])
    if (diff lt 10.0) then thesetimes[0] = 10.0
    delta_m = -1.0*pars[l].index*alog(thesetimes/10.0)
    for k = startobs,nobs-2 do begin
       match.m[k,l] = pars[l].peak + (delta_m[k-startobs]+delta_m[k-startobs+1])/2.0
       match.merr[k,l] = 0.2*(2.0^(match.m[k,l]-mlim[k,l]))
    endfor
    match.m[nobs-1,l] = pars[l].peak + delta_m[nobs-startobs-1]
    match.merr[nobs-1,l] = 0.2*(2.0^(match.m[nobs-1,l]-mlim[nobs-1,l]))
 endfor
 match.msys = 2

; Filter objects

 i = where(match.m gt -1.0 and match.m lt (mlim+2.0), count)
 if (count gt 0) then begin
    error = sqrt((match.msys[i]/200.0)^2.0 + match.merr[i]^2.0)
    match.m[i] = match.m[i] + error*randomn(seed,count)
    match.merr[i] = 0.2*(2.0^(match.m[i]-mlim[i]))
 endif
 i = where(match.m gt mlim, count)
 if (count gt 0) then begin
    match.m[i] = -1.0
    match.merr[i] = -1.0
    match.msys[i] = 0
 endif
 i = where(match.m gt -1.0, count)
 if (count gt 0) then begin
    match.flags[i] = 0
    match.rflags[i] = 0
 endif
 i = where(match.m lt (mlim-6.0) and match.m gt -1.0, count)
 if (count gt 0) then begin
    tmparr = make_array(count, /INT, value=set_flags('SATURATED',type='EFLAGS'))
    match.flags[i] = match.flags[i] + tmparr
 endif

 return
end


