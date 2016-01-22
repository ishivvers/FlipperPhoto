function filter_obs,match,delta,maxsig,chisq=chisq,ival=ival,emask=emask,rmask=rmask

; Purpose:	Filter list of observations to a preliminary set of probable 
;	variables.  Good observations are selected for each source, and these are 
;	used to obtain general lightcurve characteristics for further cuts.
;
; Inputs:
;	match			list of source observations
;	delta			minimum magnitude range
;	maxsig			minimum significance of variation
;
; Outputs:  NONE
;
; Keywords:
;	chisq			minimum chi-squared per degree-of-freedom, clipped 
;				of most extreme well-observed value
;	ival			minimum modified Welch-Stetson I-value
;	emask			mask for extraction flags
;	rmask			mask for ROTSE observation flags
;
; Return Value:
;	goodobj			list of indices of candidate variables
;
; Created: 99-11-03 Bob Kehoe
; Updated: 00-04-10 Bob Kehoe
; Updated: 06-01-00 Bob Kehoe -- added flags cuts on bad observations
; Updated: 08-21-00 Bob Kehoe -- re-worked

; Initialization

 print, 'Filtering for significant variation in good observations:'
 print, '   DELTA > ', delta
 print, '   MAXSIG > ', maxsig
 min_nobs = 2
 if keyword_set(chisq) then begin
    print, '   CHISQ > ', chisq
    min_nobs = 3
 endif else chisq = 0.0
 if keyword_set(emask) then begin
    print, '   EMASK = ', emask
 endif else emask = 0
 if keyword_set(rmask) then begin
    print, '   RMASK = ', rmask
 endif else rmask = 0
 nobs = (size(match.m))[1]
 nobj = long((size(match.m))[2])
 max_delta = fltarr(nobj)
 max_err = fltarr(nobj)
 chisq_clip = fltarr(nobj)

; Find objects with significant variation in good observations...

 for k = 0L,nobj-1L do begin
    diff = 0.0
    goodobs = where(match.flags[*,k] gt -1 and $
		check_flags(emask,match.flags[*,k],type='EFLAGS') eq 0 and $
		check_flags(rmask,match.rflags[*,k],type='RFLAGS') eq 0, ngdobs)
    if (ngdobs ge min_nobs) then begin
       diff = max(match.m[goodobs,k])-min(match.m[goodobs,k])
       if (diff gt delta) then begin
	  maxdelta = fltarr(ngdobs)
	  maxerr = fltarr(ngdobs)
	  err = sqrt(match.merr[goodobs,k]^2.0 + (match.msys[goodobs,k]/200.0)^2.0)
          for l = 0,ngdobs-1 do begin
	     diffs = abs(match.m[goodobs[l],k] - match.m[goodobs,k])
	     sig = diffs / sqrt(err^2.0 + err[l]^2.0)
	     i = where(diffs gt delta and sig gt maxsig and sig gt maxerr[l], count)
	     if (count gt 0) then begin
		maxerr[l] = max(sig[i], iobs)
		maxdelta[l] = diffs[i[iobs]]
	     endif
	  endfor
          max_err[k] = max(maxerr, iobs)
          max_delta[k] = maxdelta[iobs]
          avgmag = (moment(match.m[goodobs,k]))[0]
          max_off = max(abs(match.m[goodobs,k]-avgmag), iobs)
          i = where(match.m[goodobs,k] ne match.m[goodobs[iobs],k], count)
          dof = ngdobs - 2
          if (count ge 2) then begin
             avgmag_clip = (moment(match.m[goodobs[i],k]))[0]
             chisq_clip[k] = total(((match.m[goodobs[i],k] - avgmag_clip)/err[i])^2.0)$
						/float(dof)
          endif
       endif
    endif
 endfor
 goodobj = where(max_delta gt delta and max_err gt maxsig and chisq_clip gt chisq,$
		ngdobj)

 return, goodobj
end



