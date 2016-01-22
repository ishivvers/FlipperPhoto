pro tycho_coadd_from_match,match,refobs,obslist,imtot,threshold=threshold
;+
; NAME:	TYCHO_COADD_FROM_MATCH
;
; CALLING SEQUENCE: tycho_coadd_from_match,match,obslist,imtot,threshold=threshold
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
        print,'Syntax - tycho_coadd_from_match,match,refobs,obslist,imtot,threshold=threshold'
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

 	if (keyword_set(obj_index)) then begin
		in=obj_index
 	endif else begin
  		in=where(match.m(obs,*) ne -1 and match.m(refobs,*) ne -1)
 	endelse

;Now project the ras and decs of these to the plane:
 	rac=match.rac
 	decc=match.decc
 	convert2xy,match.ra(in),match.dec(in),xc,yc,rac=rac,decc=decc
 	kx=reform(match.kx(refobs,*,*))
 	ky=reform(match.ky(refobs,*,*))
 	kmap,xc,yc,xr,yr,kx,ky

;Now project the ras and decs of these to the plane:
 	convert2xy,match.ra(in),match.dec(in),xc,yc,rac=rac,decc=decc
 	kx=reform(match.kx(obs,*,*))
 	ky=reform(match.ky(obs,*,*))
 	kmap,xc,yc,xo,yo,kx,ky

	im=readfits(match.imagename(obs),hdr)
	print,'Warping image'
	n=n_elements(in)
	num=fix(0.1*n)
	if (num gt 2000) then num=2000
	imw=warp_tri(xr(in(0:num)),yr(in(0:num)),$
		xo(in(0:num)),$
		yo(in(0:num)),im)
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









