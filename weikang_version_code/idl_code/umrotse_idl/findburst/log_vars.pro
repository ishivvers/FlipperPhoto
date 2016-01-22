pro log_vars,match,var,logname, ivars=ivars
;+
; NAME: log_vars	
;
; CALLING SEQUENCE:	find_burst, match, var, logname, ivars=ivars
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;		thresh: threshold for total variation
;		errfact: number of stddev (stat.) beyond thresh for variation
;
; OUTPUTS:	var: structure containing summary information on transient 
;			candidates
;
; PROCEDURE:	Searches for brief optical transients in a matched object
;		list from ROTSE trigger response data.
;
; Created:  4-23-99  Bob Kehoe
; Updated:  9-23-99  Bob Kehoe
; Updated: 11-10-99  Bob Kehoe
; Updated: 00-04-14  Bob Kehoe -- added relative photometry correction 
; Updated: 05-31-00 Bob Kehoe -- many mods
;******************************************************************************

if N_params() lt 1 then begin
   print, 'Syntax find_burst,match,threshold,errfact,vars,/no_chisq,/fakes,log=log'
   return
endif

totobs = (size(match.imagename))[1]
if keyword_set(ivars) then begin 
   ptr = var.ptr[ivars]
   maxmag = var.maxmag[ivars]
   errmaxmag = var.errmaxmag[ivars]
   minmag = var.minmag[ivars]
   avgmag = var.avgmag[ivars]
   delta = var.delta[ivars]
   delta_maxsig = var.delta_maxsig[ivars]
   nobs = var.nobs[ivars]
   nobs_good = var.nobs_good[ivars]
   sdev = var.sdev[ivars]
   sdev_clip = var.sdev_clip[ivars]
   chisq = var.chisq[ivars]
   chisq_clip = var.chisq_clip[ivars]
   maxsig = var.maxsig[ivars]
   dis = var.dis[*,ivars]
   dra = var.dra[*,ivars]
   ddec = var.ddec[*,ivars]
   sdev_pos = var.sdev_pos[ivars]
   delta_pos = var.delta_pos[ivars]
   mdev = var.mdev[ivars]
   skewness = var.skewness[ivars]
   kurtosis = var.kurtosis[ivars]
   err_mdn = var.err_mdn[ivars]
   errfract = var.errfract[ivars]
   errfract_clip = var.errfract_clip[ivars]
   name = var.name[ivars]
   maxdelta = var.maxdelta[ivars]
   maxerr = var.maxerr[ivars]
   tvar = create_struct('ptr', ptr, 'maxmag', maxmag, 'errmaxmag', $
        errmaxmag, 'minmag', minmag, 'avgmag', avgmag, 'delta', $
	delta, 'delta_maxsig', delta_maxsig, 'nobs', nobs, $
        'nobs_good', nobs_good, 'sdev', sdev, 'sdev_clip', sdev_clip,$
	'chisq', chisq, 'chisq_clip', chisq_clip, 'maxsig', maxsig, $
	'dis', dis, 'dra', dra, 'ddec', ddec, 'sdev_pos', sdev_pos[ptr], 'delta_pos', $
	delta_pos[ptr], 'mdev', mdev, 'skewness', skewness, 'kurtosis', $
	kurtosis, 'err_mdn', err_mdn, 'errfract', errfract, 'errfract_clip', $
	errfract_clip, 'name', name, 'maxdelta', maxdelta, 'maxerr', maxerr)
endif else begin
   tvar = var
endelse

!P.MULTI=[0,2,3]
txtfile = logname + '.txt'
print_var,match,tvar,fname=txtfile
set_plot, 'ps'
psfile = logname + '.ps'
device, file=psfile
lcplot,match,indgen(totobs),tvar.ptr,/good,/syserr,/offset,names=tvar.name
device, /close
set_plot, 'X'

end

