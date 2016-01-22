pro print_flags, pstruct, index, colorindex, objc=objc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Prints flags for a single object....
; 
; Inputs:  pstruct: a photo output structure (must have .flags tag...)
;	   index: index of the object of interest
;
; Outputs: Prints flags status
;
; Author:  Tim McKay
; Date: 1/7/99
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Help message
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if n_params() eq 0 then begin
   print,'-syntax print_flags, pstruct, index, colorindex, objc=objc'
   return
endif

f=long(pstruct(index).flags(colorindex))

if keyword_set(objc) then begin
   f = long(pstruct(index).objc_flags)
   print,'Printing objc flags!'
   print,f

   for j=0,31,1 do begin
     h=long(2L^j)
     if ((f and h) ne 0) then begin
	if (j eq 0) then print,'OBJC_CANONICAL_CENTER'
	if (j eq 1) then print,'OBJC_BRIGHT'
	if (j eq 2) then print,'OBJC_EDGE'
	if (j eq 3) then print,'OBJC_BLENDED '
	if (j eq 4) then print,'OBJC_CHILD'
	if (j eq 5) then print,'OBJC_PEAKCENTER'
	if (j eq 6) then print,'OBJC_NODEBLEND'
	if (j eq 7) then print,'OBJC_NOPROFILE'
	if (j eq 8) then print,'OBJC_NOPETRO'
	if (j eq 9) then print,'OBJC_MANYPETRO'
	if (j eq 10) then print,'OBJC_NOPETRO_BIG'
	if (j eq 11) then print,'OBJC_DEBLEND_TOO_MANY_PEAKS'
	if (j eq 12) then print,'OBJC_CR'
	if (j eq 13) then print,'OBJC_MANYR50'
	if (j eq 14) then print,'OBJC_MANYR90'
	if (j eq 15) then print,'OBJC_BAD_RADIAL'
	if (j eq 16) then print,'OBJC_INCOMPLETE_PROFILE'
	if (j eq 17) then print,'OBJC_INTERP'
	if (j eq 18) then print,'OBJC_SATUR'
	if (j eq 19) then print,'OBJC_NOTCHECKED'
	if (j eq 20) then print,'OBJC_SUBTRACTED'
	if (j eq 21) then print,'OBJC_NOSTOKES'
	if (j eq 22) then print,'OBJC_BADSKY'
	if (j eq 23) then print,'OBJC_PETROFAINT '
	if (j eq 24) then print,'OBJC_TOO_LARGE'
	if (j eq 25) then print,'OBJC_DEBLENDED_AS_PSF'
	if (j eq 26) then print,'OBJC_DEBLEND_PRUNED'
	if (j eq 27) then print,'OBJC_ELLIPFAINT'
	if (j eq 28) then print,'OBJC_BINNED1'
	if (j eq 29) then print,'OBJC_BINNED2'
	if (j eq 30) then print,'OBJC_BINNED4 '
	if (j eq 31) then print,'OBJC_MOVED'
     endif
   endfor
endif else begin

   print,f

   for j=0,31,1 do begin
     h=long(2L^j)
     if ((f and h) ne 0) then begin
	if (j eq 0) then print,'OBJECT1_CANONICAL_CENTER'
	if (j eq 1) then print,'OBJECT1_BRIGHT'
	if (j eq 2) then print,'OBJECT1_EDGE'
	if (j eq 3) then print,'OBJECT1_BLENDED '
	if (j eq 4) then print,'OBJECT1_CHILD'
	if (j eq 5) then print,'OBJECT1_PEAKCENTER'
	if (j eq 6) then print,'OBJECT1_NODEBLEND'
	if (j eq 7) then print,'OBJECT1_NOPROFILE'
	if (j eq 8) then print,'OBJECT1_NOPETRO'
	if (j eq 9) then print,'OBJECT1_MANYPETRO'
	if (j eq 10) then print,'OBJECT1_NOPETRO_BIG'
	if (j eq 11) then print,'OBJECT1_DEBLEND_TOO_MANY_PEAKS'
	if (j eq 12) then print,'OBJECT1_CR'
	if (j eq 13) then print,'OBJECT1_MANYR50'
	if (j eq 14) then print,'OBJECT1_MANYR90'
	if (j eq 15) then print,'OBJECT1_BAD_RADIAL'
	if (j eq 16) then print,'OBJECT1_INCOMPLETE_PROFILE'
	if (j eq 17) then print,'OBJECT1_INTERP'
	if (j eq 18) then print,'OBJECT1_SATUR'
	if (j eq 19) then print,'OBJECT1_NOTCHECKED'
	if (j eq 20) then print,'OBJECT1_SUBTRACTED'
	if (j eq 21) then print,'OBJECT1_NOSTOKES'
	if (j eq 22) then print,'OBJECT1_BADSKY'
	if (j eq 23) then print,'OBJECT1_PETROFAINT '
	if (j eq 24) then print,'OBJECT1_TOO_LARGE'
	if (j eq 25) then print,'OBJECT1_DEBLENDED_AS_PSF'
	if (j eq 26) then print,'OBJECT1_DEBLEND_PRUNED'
	if (j eq 27) then print,'OBJECT1_ELLIPFAINT'
	if (j eq 28) then print,'OBJECT1_BINNED1'
	if (j eq 29) then print,'OBJECT1_BINNED2'
	if (j eq 30) then print,'OBJECT1_BINNED4 '
	if (j eq 31) then print,'OBJECT1_MOVED'
     endif
   endfor
endelse

return

end