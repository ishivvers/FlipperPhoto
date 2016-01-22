pro filter_consec, match, xmatch

; Purpose:	to filter out objects which do not occur in at least two
;	consecutive epochs.
;
; Created 00-04-10 Bob Kehoe
; Updated 00-05-25 Bob Kehoe -- used make_match_struct

if N_params() lt 2 then begin
   print, 'Syntax filter_consec, oldmatch, newmatch'
   return
endif

; Find objects occurring in consecutive epochs.

get_imkeys, match.imagename, keys
msize = size(match.m)
totobs = long(msize[1])
nobj = long(msize[2])
passed = intarr(nobj)
for k = 0L,nobj-1L do begin
   goodobs = where(match.m[*,k] ne -1.0, nobs)
   if (nobs gt 1) then begin
      twoframes, keys, goodobs, pass
      passed[k] = pass
   endif
endfor
goodobj = where(passed gt 0, nobj)

; Fill new structure only containing good objects

xmatch = make_match_struct(totobs, goodobj, old=match, extended=1)
print, '   Stuffed ', nobj, ' objects into match structure.'

end
