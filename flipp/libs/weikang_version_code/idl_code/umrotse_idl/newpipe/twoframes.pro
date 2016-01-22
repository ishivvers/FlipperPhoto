pro twoframes,key,goodobs,passed

; Purpose:	look for object in a sequence of two adjacent images.  
;
; Created:  11-03-99 Bob Kehoe

if N_params() lt 3 then begin
   print, 'Syntax twoframes,key,goodobs,passed'
   return
endif

; Determine coarse order of frames based on trigger type

ntrigs = 4
tmp = size(key)
ksize = tmp[1]
order = intarr(ksize)
nframe = intarr(ksize)
seen = intarr(ksize)
seen[goodobs] = 1
for k = 0,ksize-1 do begin
   trigger = strmid(key[k], 0, 3)
   if (trigger eq 'grb') then order[k] = 0
   if (trigger eq 'grf') then order[k] = 1
   if (trigger eq 'grm') then order[k] = 2
   if (trigger eq 'grl') then order[k] = 3
   if (trigger eq 'sky') then order[k] = ntrigs
   nframe[k] = fix(strmid(key[k], 3, 3))
   imult = where(key eq key[k], count)
   if (count gt 1) then begin
      iseen = where(goodobs eq k, count2)
      if (count2 ne 0) then seen[imult] = 1
   endif
endfor
isort = sort(key)
iuniq = uniq(key, isort)
neworder = order[iuniq]
newframe = nframe[iuniq]
newseen = seen[iuniq]
newgoodobs = where(newseen eq 1)

; Time-order and flag each observation where object seen.

tmp = size(iuniq)
usize = tmp[1]
seen_in_epoch = intarr(usize)
index = 0
for i = 0, ntrigs do begin
   thistrig = where(neworder eq i, nobs)
   if (nobs ne 0) then begin
      re_sort = sort(newframe[thistrig])
      for k = 0, nobs-1 do begin
	 yes = where(newgoodobs eq thistrig[re_sort[k]], count)
	 if (count ne 0) then seen_in_epoch[index] = 1
	 index = index + 1
      endfor
   endif
endfor

; Look for two consecutive epochs where object seen.

passed = 0
for k = 1, usize-1 do begin
   if (seen_in_epoch[k] eq 1 and seen_in_epoch[k-1] eq 1) then passed = 1
endfor

end








