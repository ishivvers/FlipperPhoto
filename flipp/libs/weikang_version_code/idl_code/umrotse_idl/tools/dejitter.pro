PRO dejitter,iname,oname,nrows

; Purpose: shift jittered image by nrows
;
; Created: 1999 Bob Kehoe

im=mrdfits(iname,0,hdr)
datsize=size(im)
im2=fltarr(datsize[1],datsize[2])
for k = 0,datsize[1]-1 do begin
   for l = 0,datsize[2]-1 do begin
      tmp = l - nrows
      if (tmp ge 0 and tmp lt datsize[2]) then begin
	 im2[k,l] = im[k,tmp]
      endif else begin 
	 im2[k,l] = 0 
      endelse
   endfor
endfor
comment = 'IDL> dejitter, ' + iname + ', ' + oname + ', ' + string(nrows,'(I3)')
sxaddhist, comment, hdr
mwrfits, im2, oname, hdr

END
