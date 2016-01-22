pro lightcurve,mag,err,m_lim,thresh,errfact,var

; Purpose:  Determine if have range of magnitudes consistent with search
;
; Created 11-03-99 Bob Kehoe
; Updated: 05-23-00 Bob Kehoe  -- calculate many new parameters
; Updated: 08-21-00 Bob Kehoe  -- add new parameters, fix chisq bug 

; Find general lightcurve characteristics

var.ngdobs = (size(mag))[1]
var.maxmag = max(mag, iobs)
var.errmaxmag = err[iobs]
var.minmag = min(mag)
var.maxsig = max(-1.0*(mag - m_lim)/err)
var.delta = var.maxmag - var.minmag
var.avgdev = meanabsdev(mag)
result = moment(mag)
var.avgmag = result[0]
var.sdev = sqrt(result[1])
var.skew = result[2]
var.kurt = result[3]
var.mdnerr = median(err)
var.avgdevsig = var.avgdev/var.mdnerr

; Calculate most significant variation

maxdelta = fltarr(var.ngdobs)
maxerr = fltarr(var.ngdobs)
for l = 0,var.ngdobs-1 do begin
   diffs = abs(mag[l] - mag)
   sigs = diffs / sqrt(err^2.0 + err[l]^2.0)
   i = where(diffs gt thresh and sigs gt errfact and sigs gt maxerr[l], count)
   if (count gt 0) then begin
      maxerr[l] = max(sigs,iobs)
      maxdelta[l] = diffs[iobs]
   endif
endfor
var.bestsig = max(maxerr, iobs)
var.bestdelta = maxdelta[iobs]

; Calculate lightcurve chi-squared

chisq = total(((mag - var.avgmag)/err)^2.0)
dof = var.ngdobs - 1
var.chisq = chisq / float(dof)
max_off = max(abs(mag-var.avgmag), iobs)
i = where(mag ne mag[iobs], count)
if (count ge 2) then begin
   var.sdevcl = (moment(mag[i]))[1]
   var.avgdevsigcl = meanabsdev(mag[i])/median(err[i])
   avgmag_clip = (moment(mag[i]))[0]
   var.chisqcl = total(((mag[i] - avgmag_clip)/err[i])^2.0)/float(dof-1.0)
endif

end









