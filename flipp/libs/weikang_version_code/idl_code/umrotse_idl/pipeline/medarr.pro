pro medarr,inarr,outarr
;+
; NAME:
;	medarr
; PURPOSE: (one line)
;	Combine arrays with a median average.
; DESCRIPTION:
;       This will combine a series of arrays into a single array by filling each
;       pixel in the output array with the median of the corresponding pixels
;       in the input arrays.
; CATEGORY:
;	CCD data processing
; CALLING SEQUENCE:
;       medarr, inarr, outarr
; INPUTS:
;       inarr  -- A three dimensional array containing the input arrays to
;                 combine together.  Each of the input arrays must be two
;                 dimensional and must have the same dimensions.  These arrays
;                 should then be stacked together into a single 3-D array,
;                 creating INARR.
; OPTIONAL INPUT PARAMETERS:
;	None.
; KEYWORD PARAMETERS:
;	None.
; OUTPUTS:
;       outarr -- The output array.  It will have dimensions equal to the
;                 first two dimensions of the input array.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	This will run VERY slow if inarr and outarr won't fit into real memory
;	on your computer.  Don't try this using virtual memory.
; PROCEDURE:
;       The output array is created and then each pixel is extracted from the
;	cube.  Once extracted, the pixel stack is sorted and the middle value
;	is put into the output array.
; MODIFICATION HISTORY:
;	Written by Marc W. Buie, Lowell Observatory, 17 January 1992
;-

; Check parameters
if n_params(0) lt 2 then begin
   print,"medarr -- Syntax:  medarr, inputarr, outputarr"
   return
endif

s = size(inarr)
if (s(0) ne 3) then begin
   print,"ERROR - Input arry must have 3 dimensions."
   return
endif

; Create the output array.
ncol = s(1)
nrow = s(2)
narr = s(3)
type = s(s(0) + 1)
;outarr = make_array(dimen=[s(1),s(2)],type=type,/nozero)
outarr = fltarr(s(1),s(2),/nozero)

;Make the plane indexing vector
planes=indgen(narr)

even = fix(narr/2) * 2 eq narr

; Combine the input arrays.
if even then begin
   val = [narr/2,narr/2-1]
   for row = 0,nrow-1 do begin
      for col = 0,ncol-1 do begin
         allpix=inarr(col,row,planes)
         ord = sort(allpix)
         outarr(col,row) = total(allpix(ord(val)))/2
      endfor
   endfor
endif else begin
   val = narr/2
   for row = 0,nrow-1 do begin
      for col = 0,ncol-1 do begin
         allpix=inarr(col,row,planes)
         ord = sort(allpix)
         outarr(col,row) = allpix(ord(val))
      endfor
   endfor
endelse

return
end
