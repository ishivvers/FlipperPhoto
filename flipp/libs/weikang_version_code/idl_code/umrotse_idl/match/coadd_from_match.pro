pro coadd_from_match,match,refobs,obslist,imtot,threshold=threshold
;+
; NAME:	COADD_FROM_MATCH
;
; CALLING SEQUENCE: coadd_from_match,match,obslist,imtot,threshold=threshold
;
; INPUTS:	match: input object structure from cat_match etc..
;		obslist: numbers of images to coadd
;
; OUTPUTS:	imtot: sum of all the images selected
;	
;
; INPUT KEYWORDS:
;	threshold: All pixels with values above this will be "zeroed" out in
;		the final image. They will ultimately be replaced with sky...
;			
; PROCEDURE:	Warps the images into one another and adds them together
;
; REVISION HISTORY:  
;	Tim McKay		UM	6/19/98
;


 if N_params() eq 0 then begin
        print,'Syntax - coadd_from_match,match,refobs,obslist,imtot,threshold=threshold'
        return
 endif

 info=size(obslist)
 nobs=info(1)
 print,'Merging a total of ',nobs,' observations'
 print,'Reference observation is ',refobs

 if not keyword_set(threshold) then begin
	threshold = 16000.0
 endif

 for i=0,nobs-1,1 do begin
	obs=obslist(i)
	print,'Loading observation:',obs
	j=where(match.x(refobs,*) ne -1 and match.x(obs,*) ne -1)
	im=mrdfits(match.imagename(obs),0,hdr)
	print,'Warping image'
	n=n_elements(j)
	num=fix(0.1*n)
	imw=warp_tri(match.x(refobs,j(0:num)),match.y(refobs,j(0:num)),$
		match.x(obs,j(0:num)),$
		match.y(obs,j(0:num)),im)
	;Now zero out "bad" pixels in either list
	if (i eq 0) then begin
		k=where(imw gt threshold)
		if((size(k))(0) ne 0) then begin
		  imw(k)=0
		endif
		imtot=float(imw)
	endif else begin
		k=where(imw gt threshold)
		if((size(k))(0) ne 0) then begin
		  imw(k)=0
		endif
		l=where(imtot eq 0)
		if((size(l))(0) ne 0) then begin
		  imw(l)=0
		endif
		imtot=imtot+float(imw)
	endelse
 endfor

 return
 end