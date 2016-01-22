pro sflag_select, match, flag_struct

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Makes cuts based on flag structure. These cuts are strictly "anded" 
; together, so they must all be true for the object to survive.
; 
; Inputs:  pstruct: a photo output structure (must have .flags tag...)
;	   flag_struct: Premade flag structure. This will require any
;		flags set to 'Y' and insist that any flag set to 'N' be
;		off
;
; Outputs: selext_index: indices of selected objects....
;
; Author:  Tim McKay
; Date: 3/1/99
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Help message
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  if n_params() eq 0 then begin
   print,'-syntax sflag_select, match, flag_struct'
   return
  endif

  printf,'I'm not sure how to structure this yet!!!'
  return

; Should probably return some kind of array of "good" observations of each
; object which could then be fed to a WS routine....

  k=lindgen(n_elements(pstruct))

  f=long(pstruct(k).flags(colorindex))
  if keyword_set(objc) then begin
    f=long(pstruct(k).objc_flags)
  endif
  
  fs=flag_struct

  if (fs.CANONICAL_CENTER eq 'Y') then begin
	h=where((f(k) and 2L^0) ne 0)
	k=k(h)
  endif 
  if (fs.CANONICAL_CENTER eq 'N') then begin
	h=where((f(k) and 2L^0) eq 0)
	k=k(h)
  endif

  if (fs.BRIGHT eq 'Y') then begin
	h=where((f(k) and 2L^1) ne 0)
	k=k(h)
  endif 
  if (fs.BRIGHT eq 'N') then begin
	h=where((f(k) and 2L^1) eq 0)
	k=k(h)
  endif

  if (fs.EDGE eq 'Y') then begin
	h=where((f(k) and 2L^2) ne 0)
	k=k(h)
  endif 
  if (fs.EDGE eq 'N') then begin
	h=where((f(k) and 2L^2) eq 0)
	k=k(h)
  endif

  if (fs.BLENDED eq 'Y') then begin
	h=where((f(k) and 2L^3) ne 0)
	k=k(h)
  endif 
  if (fs.BLENDED eq 'N') then begin
	h=where((f(k) and 2L^3) eq 0)
	k=k(h)
  endif

  if (fs.CHILD eq 'Y') then begin
	h=where((f(k) and 2L^4) ne 0)
	k=k(h)
  endif 
  if (fs.CHILD eq 'N') then begin
	h=where((f(k) and 2L^4) eq 0)
	k=k(h)
  endif

  if (fs.PEAKCENTER eq 'Y') then begin
	h=where((f(k) and 2L^5) ne 0)
	k=k(h)
  endif 
  if (fs.PEAKCENTER eq 'N') then begin
	h=where((f(k) and 2L^5) eq 0)
	k=k(h)
  endif

  if (fs.NODEBLEND eq 'Y') then begin
	h=where((f(k) and 2L^6) ne 0)
	k=k(h)
  endif 
  if (fs.NODEBLEND eq 'N') then begin
	h=where((f(k) and 2L^6) eq 0)
	k=k(h)
  endif

  if (fs.NOPROFILE eq 'Y') then begin
	h=where((f(k) and 2L^7) ne 0)
	k=k(h)
  endif 
  if (fs.NOPROFILE eq 'N') then begin
	h=where((f(k) and 2L^7) eq 0)
	k=k(h)
  endif

  if (fs.NOPETRO eq 'Y') then begin
	h=where((f(k) and 2L^8) ne 0)
	k=k(h)
  endif 
  if (fs.NOPETRO eq 'N') then begin
	h=where((f(k) and 2L^8) eq 0)
	k=k(h)
  endif

  if (fs.MANYPETRO eq 'Y') then begin
	h=where((f(k) and 2L^9) ne 0)
	k=k(h)
  endif 
  if (fs.MANYPETRO eq 'N') then begin
	h=where((f(k) and 2L^9) eq 0)
	k=k(h)
  endif

  if (fs.NOPETRO_BIG eq 'Y') then begin
	h=where((f(k) and 2L^10) ne 0)
	k=k(h)
  endif 
  if (fs.NOPETRO_BIG eq 'N') then begin
	h=where((f(k) and 2L^10) eq 0)
	k=k(h)
  endif

  if (fs.DEBLEND_TOO_MANY_PEAKS eq 'Y') then begin
	h=where((f(k) and 2L^11) ne 0)
	k=k(h)
  endif 
  if (fs.DEBLEND_TOO_MANY_PEAKS eq 'N') then begin
	h=where((f(k) and 2L^11) eq 0)
	k=k(h)
  endif

  if (fs.CR eq 'Y') then begin
	h=where((f(k) and 2L^12) ne 0)
	k=k(h)
  endif 
  if (fs.CR eq 'N') then begin
	h=where((f(k) and 2L^12) eq 0)
	k=k(h)
  endif

  if (fs.MANYR50 eq 'Y') then begin
	h=where((f(k) and 2L^13) ne 0)
	k=k(h)
  endif 
  if (fs.MANYR50 eq 'N') then begin
	h=where((f(k) and 2L^13) eq 0)
	k=k(h)
  endif

  if (fs.MANYR90 eq 'Y') then begin
	h=where((f(k) and 2L^14) ne 0)
	k=k(h)
  endif 
  if (fs.MANYR90 eq 'N') then begin
	h=where((f(k) and 2L^14) eq 0)
	k=k(h)
  endif

  if (fs.BAD_RADIAL eq 'Y') then begin
	h=where((f(k) and 2L^15) ne 0)
	k=k(h)
  endif 
  if (fs.BAD_RADIAL eq 'N') then begin
	h=where((f(k) and 2L^15) eq 0)
	k=k(h)
  endif

  if (fs.INCOMPLETE_PROFILE eq 'Y') then begin
	h=where((f(k) and 2L^16) ne 0)
	k=k(h)
  endif 
  if (fs.INCOMPLETE_PROFILE eq 'N') then begin
	h=where((f(k) and 2L^16) eq 0)
	k=k(h)
  endif

  if (fs.INTERP eq 'Y') then begin
	h=where((f(k) and 2L^17) ne 0)
	k=k(h)
  endif 
  if (fs.INTERP eq 'N') then begin
	h=where((f(k) and 2L^17) eq 0)
	k=k(h)
  endif

  if (fs.SATUR eq 'Y') then begin
	h=where((f(k) and 2L^18) ne 0)
	k=k(h)
  endif 
  if (fs.SATUR eq 'N') then begin
	h=where((f(k) and 2L^18) eq 0)
	k=k(h)
  endif

  if (fs.NOTCHECKED eq 'Y') then begin
	h=where((f(k) and 2L^19) ne 0)
	k=k(h)
  endif 
  if (fs.NOTCHECKED eq 'N') then begin
	h=where((f(k) and 2L^19) eq 0)
	k=k(h)
  endif

  if (fs.SUBTRACTED eq 'Y') then begin
	h=where((f(k) and 2L^20) ne 0)
	k=k(h)
  endif 
  if (fs.SUBTRACTED eq 'N') then begin
	h=where((f(k) and 2L^20) eq 0)
	k=k(h)
  endif

  if (fs.NOSTOKES eq 'Y') then begin
	h=where((f(k) and 2L^21) ne 0)
	k=k(h)
  endif 
  if (fs.NOSTOKES eq 'N') then begin
	h=where((f(k) and 2L^21) eq 0)
	k=k(h)
  endif

  if (fs.BADSKY eq 'Y') then begin
	h=where((f(k) and 2L^22) ne 0)
	k=k(h)
  endif 
  if (fs.BADSKY eq 'N') then begin
	h=where((f(k) and 2L^22) eq 0)
	k=k(h)
  endif

  if (fs.PETROFAINT eq 'Y') then begin
	h=where((f(k) and 2L^23) ne 0)
	k=k(h)
  endif 
  if (fs.PETROFAINT eq 'N') then begin
	h=where((f(k) and 2L^23) eq 0)
	k=k(h)
  endif

  if (fs.TOO_LARGE eq 'Y') then begin
	h=where((f(k) and 2L^24) ne 0)
	k=k(h)
  endif 
  if (fs.TOO_LARGE eq 'N') then begin
	h=where((f(k) and 2L^24) eq 0)
	k=k(h)
  endif

  if (fs.DEBLENDED_AS_PSF eq 'Y') then begin
	h=where((f(k) and 2L^25) ne 0)
	k=k(h)
  endif 
  if (fs.DEBLENDED_AS_PSF eq 'N') then begin
	h=where((f(k) and 2L^25) eq 0)
	k=k(h)
  endif

  if (fs.DEBLEND_PRUNED eq 'Y') then begin
	h=where((f(k) and 2L^26) ne 0)
	k=k(h)
  endif 
  if (fs.DEBLEND_PRUNED eq 'N') then begin
	h=where((f(k) and 2L^26) eq 0)
	k=k(h)
  endif

  if (fs.ELLIPFAINT eq 'Y') then begin
	h=where((f(k) and 2L^27) ne 0)
	k=k(h)
  endif 
  if (fs.ELLIPFAINT eq 'N') then begin
	h=where((f(k) and 2L^27) eq 0)
	k=k(h)
  endif

  if (fs.BINNED1 eq 'Y') then begin
	h=where((f(k) and 2L^28) ne 0)
	k=k(h)
  endif 
  if (fs.BINNED1 eq 'N') then begin
	h=where((f(k) and 2L^28) eq 0)
	k=k(h)
  endif

  if (fs.BINNED2 eq 'Y') then begin
	h=where((f(k) and 2L^29) ne 0)
	k=k(h)
  endif 
  if (fs.BINNED2 eq 'N') then begin
	h=where((f(k) and 2L^29) eq 0)
	k=k(h)
  endif

  if (fs.BINNED4 eq 'Y') then begin
	h=where((f(k) and 2L^30) ne 0)
	k=k(h)
  endif 
  if (fs.BINNED4 eq 'N') then begin
	h=where((f(k) and 2L^30) eq 0)
	k=k(h)
  endif

  if (fs.MOVED eq 'Y') then begin
	h=where((f(k) and 2L^31) ne 0)
	k=k(h)
  endif 
  if (fs.MOVED eq 'N') then begin
	h=where((f(k) and 2L^31) eq 0)
	k=k(h)
  endif

  select_index=k 


return

end

