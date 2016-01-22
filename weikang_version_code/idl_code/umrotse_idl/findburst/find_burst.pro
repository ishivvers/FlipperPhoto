function find_burst,oldmatch,mindelta,minsig,minchisq=minchisq,log=log,emask=emask,rmask=rmask
;+
; NAME:	find_burst
;
; CALLING SEQUENCE:	var = find_burst(match, mindelta, minsig)
;
; INPUTS:
;	match = match structure produced by make_match_struct
;	mindelta = threshold for total variation
;	minsig = number of stddev (stat.+sys.) for variation
;
; Keywords:
;	minchisq = minimum clipped chis-squared of good observations
;	emask = mask for extraction flags
;	rmask = mask for ROTSE observation flags
;	log = toggles whether to produce output text and postscript
;
; Return Value:	structure containing summary information on transient candidates
;
; PROCEDURE:	Searches for brief optical transients in a matched object
;		list from ROTSE trigger response data.
;
; Created:  4-23-99  Bob Kehoe
; Updated:  9-23-99  Bob Kehoe
; Updated: 11-10-99  Bob Kehoe
; Updated: 00-04-14  Bob Kehoe -- added relative photometry correction 
; Updated: 05-31-00  Bob Kehoe -- many mods
; Updated: 08-21-00  Bob Kehoe -- use new var struct, add some variables (eg. ivalue calc.)
; Updated: 12-07-00  Bob Kehoe -- added duration parameter to var struct
;******************************************************************************

if N_params() lt 3 then begin
   print, 'Syntax var = find_burst(match,mindeltaold,minsig,minchisq=minchisq,emask=emask,rmask=rmask,/fakes,log=log'
   return, -1
endif

; Initialization

nobj = long((size(oldmatch.m))[2])
totobs = (size(oldmatch.m))[1]
print, 'Total number of objects found in ', totobs, ' epochs = ', nobj
match = oldmatch
bad_eflags = ['ATEDGE', 'SATURATED', 'APINCOMPL']
bad_rflags = ['NOISYPIX', 'HOTPIX', 'STRANGEPIX', 'BADPOS', 'NOTEMPL', 'PHOTSDEV']
if not keyword_set(emask) then emask = set_flags(bad_eflags, type='EFLAGS')
if not keyword_set(rmask) then rmask = set_flags(bad_rflags, type='RFLAGS')

; Filter observations

if keyword_set(minchisq) then begin
   goodobj = filter_obs(match,mindelta,minsig,chisq=minchisq,emask=emask,rmask=rmask)
endif else begin
   goodobj = filter_obs(match,mindelta,minsig,emask=emask,rmask=rmask)
endelse
nvar = long((size(goodobj))[1])
print, 'Number of variables found = ',nvar

; Calculate lightcurve quantities from good observations.

if (nvar gt 0L) then begin
   var = make_var_struct(nvar, totobs)
   for k = 0L,nvar-1L do begin

;     Get identification for this variable

      var[k].ptr = long(goodobj[k])
      ptr = var[k].ptr
      var[k].name = make_rotse_name(match.ra[ptr], match.dec[ptr])

;     Find observations where source was not seen but should have been

      misses = where(match.m[*,ptr] eq -1.0 and var[k].avgmag lt (match.stat.m_lim-1.0), count)
      var[k].nmiss = count
      if (var[k].nmiss gt 0) then var[k].obs[misses].state = 1

;     Find observations where source seen, and calculate position and duration information

      okobs = where(match.flags[*,ptr] gt -1, count)
      var[k].nobs = count
      var[k].obs[okobs].state = 2
      dra = conv2deg(match.dra[*,ptr])
      ddec = conv2deg(match.ddec[*,ptr])
      var[k].obs.dis = sqrt(dra^2.0 + ddec^2.0)
      var[k].obs.posangle = atan(ddec/dra)
      var[k].pos_sdv = (stddev(dra)+stddev(ddec)) / 2.0
      var[k].posrange = (max(dra)-min(dra)) > (max(ddec)-min(ddec))
      var[k].duration = max(match.jd[okobs]) - min(match.jd[okobs])

;     Obtain list of good observations and use to calculate lightcurve information

      gdobs = where(match.flags[*,ptr] gt -1 and $
		check_flags(emask,match.flags[*,ptr],type='EFLAGS') eq 0 and $
		check_flags(rmask,match.rflags[*,ptr],type='RFLAGS') eq 0, count)
      var[k].ngdobs = count
      var[k].obs[gdobs].state = 3
      var[k].obs[gdobs].err = sqrt(match.merr[gdobs,ptr]^2.0 + $
				     (match.msys[gdobs,ptr]/200.0)^2.0)
      kth_var = var[k]
      lightcurve, match.m[gdobs,ptr], var[k].obs[gdobs].err, match.stat[gdobs].m_lim,$
		  mindelta, minsig, kth_var
      var[k] = kth_var
      ivalue,match.m[gdobs,ptr],var[k].obs[gdobs].err,ival,mn_iter=0
      var[k].ival = ival
      ivalue,match.m[gdobs,ptr],var[k].obs[gdobs].err,ival,mn_iter=4,/robust
      var[k].ival2 = ival
   endfor
endif

if keyword_set(log) then begin
   txtfile = log + '.txt'
   print_var,match,var,fname=txtfile
   set_plot, 'ps'
   !P.MULTI = [0,2,3]
   psfile = log + '.ps'
   device, file=psfile
   lcplot2,match,indgen(totobs),var.ptr,/good,/syserr,/offset,emask=emask,rmask=rmask,/nowait
   device, /close
   set_plot, 'X'
endif

   return, var
end

