pro fix_hotpix,pix,im
;+
; NAME:	FIX_HOTPIX
;
; CALLING SEQUENCE: fix_hotpix,pix,im
;
; INPUTS:	pix; array containing hot pixel list
;		im:  image to correct
;
; OUTPUTS:	im:  corrected image
;			
; PROCEDURE:	Replaces hot pixel values with reasonable estimates.  All
;		pixels are given the global sky value.  Then those at least
;		2 pixels from the frame edge are given the mean value of
;		their eight surrounding neighbors.  This allows a more
;		reasonable value for situations of sky level variation or hot 
;		pixels inside of stars.
;
; Created: 08-15-00 Bob Kehoe

 if N_params() eq 0 then begin
    print,'Syntax - fix_hotpix,pix,im'
    return
 endif

; Start by replacing all hot pixels with global sky value

 sky, im, sky, skyerr
 im[pix.x, pix.y] = sky

; Now calculate local 'sky' values for hot pixels away from frame edges

 naxis1 = (size(im))[1]
 naxis2 = (size(im))[2]
 nhot = (size(pix.x))[1]
 loc_sky = fltarr(nhot)
 i = where(pix.x gt 1 and pix.x lt naxis1-2 and $
	   pix.y gt 1 and pix.y lt naxis2-2, count)
 index = 0
 for k = 0,count-1 do begin
    tot = total(im[pix[i[k]].x-1:pix[i[k]].x+1, pix[i[k]].y-1:pix[i[k]].y+1]) 
    loc_sky[i[k]] = loc_sky[i[k]] + tot - im[pix[i[k]].x, pix[i[k]].y]
 endfor

; Update hot pixel values with local 'sky' where appropriate

 im[pix[i].x, pix[i].y] = loc_sky[i] / 8.0 

 return
end



