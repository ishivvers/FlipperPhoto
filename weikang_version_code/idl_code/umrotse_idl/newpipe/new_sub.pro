pro new_sub,match,refobs,obs,im2,imdiff,im1=im1,threshold=threshold,write=write
;+
; NAME:	NEW_SUB
;
; CALLING SEQUENCE: new_sub,match,refobs,obs,im2,imdiff
;
; INPUTS:	match is the match structure
;		refobs is the reference image number
;		obs is the number of image im1
;		(im1 and im2 are the two to be subtracted (im1-im2=imdiff))
;		im2 is the output of a coadd_from_list command
;
; OUTPUTS:	
;		im1 is the original image warped to the reference...
;		imdiff is the subtracted image with "bad" pixels
;			set to sky. It is assumed that "bad"
;			pixels in im2 are set to 0, and that 
;			anything over threshold is bad in im1
;	
; INPUT KEYWORDS:
;	threshold: All pixels with values above this will be "zeroed" out in
;		the final image. They will ultimately be replaced with sky...
;			
; PROCEDURE:	
;
; REVISION HISTORY:  
;	Tim McKay		UM	11/8/98
;

 if N_params() eq 0 then begin
        print,'Syntax - new_sub,match,refobs,obs,im2,imdiff,im1=im1,threshold=threshold'
	return
 endif

 if not keyword_set(threshold) then begin
	threshold = 16000.0
 endif

 j=where(match.m(obs,*) gt -1 and match.m(obs,*) lt 13 and $
		   match.m(refobs,*) gt -1 and match.m(refobs,*) lt 13)

;Now project the ras and decs of these to the plane for the reference....
;Do this for all the objects with ras and decs....
 rac=match.rac
 decc=match.decc
 convert2xy,match.ra,match.dec,xc,yc,rac=rac,decc=decc
 kx=reform(match.kx(refobs,*,*))
 ky=reform(match.ky(refobs,*,*))
 kmap,xc,yc,xr,yr,kx,ky

;Now project the ras and decs of these to the plane:
 convert2xy,match.ra,match.dec,xc,yc,rac=rac,decc=decc
 kx=reform(match.kx(obs,*,*))
 ky=reform(match.ky(obs,*,*))
 kmap,xc,yc,xo,yo,kx,ky

 im=readfits(match.imagename(obs),hdr)
 print,'Warping image'
 n=n_elements(j)
 num=fix(0.1*n)
 im1=warp_tri(xr(j(0:num)),yr(j(0:num)),$
		xo(j(0:num)),$
		yo(j(0:num)),im)

 sky,im1(900:1100,900:1100),im1sky,im1skyerr
 sky,im2(900:1100,900:1100),im2sky,im2skyerr

 imdiff=im1-(im1sky/im2sky)*im2

 k=where(im1 gt threshold)
 if((size(k))(0) ne 0) then begin
   imdiff(k)=0
 endif

 k=where(im2 eq 0.0)
 if((size(k))(0) ne 0) then begin
   imdiff(k)=0
 endif

 sky,imdiff,totsky,totskyerr
 j=where(imdiff eq 0)
 imdiff(j)=totsky

 if (keyword_set(write)) then begin
	name=match.imagename(obs)
	namearray=str_sep(name,'.')
	outfile=namearray(0)+"_sub.fit"
	print, "Writing subtracted frame to file:",outfile
	writefits,outfile,imdiff,hdr		
	outfile=namearray(0)+"_warp.fit"
	print, "Writing warped original frame to file:",outfile
	writefits,outfile,im1,hdr
	;Note, should really add information to the headers!!!!
	imdiff=0.0
 endif		

 return
 end



