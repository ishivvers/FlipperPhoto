pro find_consec, this_jd, jd_list, iconsec

; Purpose:	identify indices for consecutive epochs.
;
; Inputs:	this_jd: julian date time to compare to
;		jd_list: list of date times to search
;
; Outputs:	iconsec: indices of consecutive epochs in jd_list
;
; Created 00-05-30 Bob Kehoe

if N_params() lt 3 then begin
   print, 'Syntax find_consec, this_jd, jd_list, iconsec'
   return
endif

inext = -1
ilast = -1
delta_t = 24.0D*60.0D*60.0D*(jd_list-this_jd)
othertimes = where(abs(delta_t) gt 5.0, count)
if (count gt 0) then begin
   postimes = where(delta_t[othertimes] gt 0.0, poscount)
   nextcount = 0
   if (poscount ne 0) then begin
      i = othertimes[postimes]
      next_epoch = min(delta_t[i])
      inext = where(abs(delta_t - next_epoch) lt 2.0, nextcount)
   endif
   negtimes = where(delta_t[othertimes] lt 0.0, negcount)
   lastcount = 0
   if (negcount ne 0) then begin
      i = othertimes[negtimes]
      last_epoch = max(delta_t[i])
      ilast = where(abs(delta_t - last_epoch) lt 2.0, lastcount)
   endif
   iconsec = intarr(nextcount + lastcount)
   if (nextcount gt 0) then iconsec[0:nextcount-1] = inext
   if (lastcount gt 0) then iconsec[nextcount:nextcount+lastcount-1] = ilast
endif else print, 'There are no other times!'

return
end