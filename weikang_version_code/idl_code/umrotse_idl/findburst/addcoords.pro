PRO addcoords, iname, oname, mountra, mountdec, offra, offdec 

; Purpose:  Add coordinates info. into old FITS headers so that 
;	    calibration with tychocal will work.
;
; Created:  99-09-17  Bob Kehoe

im=mrdfits(iname,0,hdr)
sxaddpar,hdr,'MOUNTRA',mountra
sxaddpar,hdr,'MOUNTDEC',mountdec
if (offra gt -900 and offdec gt -900) then begin
   sxaddpar,hdr,'OFFSTRA',offra
   sxaddpar,hdr,'OFFSTDEC',offdec
endif
mwrfits, im, oname, hdr

END
