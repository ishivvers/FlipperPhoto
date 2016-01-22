pro tychocal_limits, imhdr, ralow, rahigh, declow, dechigh, boxedge=boxedge,$
	rac=rac,decc=decc
;+
; NAME:	TYCHOCAL_LIMITS
;
; CALLING SEQUENCE:	tychocal_limits, imhdr, ralow, rahigh, declow, dechigh
;
; INPUTS:	imhdr: header from the image in question
;
; OUTPUTS:	ralow, rahigh, declow, dechigh: limits for selection from
;			the matching catalog
;
; INPUT KEYWORDS:
;		boxedge: length of square box edge to apply in degrees
;			
; KEYWORD OUTPUTS:
;		rac, decc: Center of the image in ra and dec
;		
; PROCEDURE:	Finds limits for a ROTSEI observation
;
; REVISION HISTORY:  
;	Tim McKay		UM		10/23/98	
;		Generated from catmatch_s
;******************************************************************************

 if N_params() eq 0 then begin
        print,"Syntax - tychocal_limits, imhdr, ralow, rahigh, declow, dechigh, boxedge=boxedge, rac=rac, decc=decc"
	return
 endif

 if (keyword_set(boxedge)) then begin
	edge=boxedge/2.0
 endif else begin
	edge=5.0
 endelse

;Start by finding the rac and decc centers of the image
 ram=sxpar(imhdr,'mountra')
 if (ram eq 0) then begin
	print,"Can't find mountra in imhdr! Aborting"
	return
 endif
 decm=sxpar(imhdr,'mountdec')
 if (decm eq 0) then begin
	print,"Can't find mountdec in imhdr! Aborting"
	return
 endif
 offsetra=sxpar(imhdr,'offstra')
 if (offsetra eq 0) then begin
	print,"Can't find offsetra in imhdr! Aborting"
	return
 endif
 offsetdec=sxpar(imhdr,'offstdec')
 if (offsetdec eq 0) then begin
	print,"Can't find offsetdec in imhdr! Aborting"
	return
 endif
 decc=decm+offsetdec
 rac=ram+offsetra/cos(decc/!radeg)

;Now calculate the limits and watch for wrapping!
 declow=decc-edge
 dechigh=decc+edge
 if (dechigh gt 90.0) then begin
	dechigh=90.0
 endif

 if (dechigh eq 90.0) then begin
	ralow=0.0
	rahigh=360.0
 endif else begin
  	ralow=rac-edge/cos(dechigh/!radeg)
 	rahigh=rac+edge/cos(dechigh/!radeg)
 	if (ralow lt 0) then begin
		ralow=ralow+360.0
 	endif
 	if (rahigh gt 360) then begin
		rahigh=rahigh-360.0
	 endif
 endelse

 return
 end










