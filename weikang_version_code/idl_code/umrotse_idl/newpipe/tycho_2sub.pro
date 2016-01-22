pro tycho_2sub,name1,name2,imdiff,im1=im1,im2=im2,threshold=threshold,write=write,str=str,frad=frad
;+
; NAME:	TYCHO_2SUB
;
; CALLING SEQUENCE: tycho_2sub,name1,name2,imdiff
;
; INPUTS:	name1, name2: names of cobj files to use
;
; OUTPUTS:	
;		im1 is the original image 1
;		im2 is the second image warped to image 1
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
;	Tim McKay		UM	10/19/98
;

 if N_params() eq 0 then begin
        print,'Syntax - tycho_2sub,name1,name2,imdiff,im1=im1,im2=im2,threshold=threshold,write=write,str=str'
	return
 endif

 if not keyword_set(threshold) then begin
	threshold = 16000.0
 endif
 if not keyword_set(frad) then begin
	frad=3.0
 endif

;First read in the two image lists and images
 l1=mrdfits(name1,1,hdr)
 l2=mrdfits(name2,1,hdr)
 narr=str_sep(name1,'_cobj.')
 imname1=narr(0)+'_c.fit'
 im1=readfits(imname1,imhdr1)
 cname1=narr(0)+'_cal.fit'
 c1=mrdfits(cname1,1,hdr)
 narr=str_sep(name2,'_cobj.')
 imname2=narr(0)+'_c.fit'
 im2=readfits(imname2,imhdr2)
 cname2=narr(0)+'_cal.fit'
 c2=mrdfits(cname2,1,hdr)
 
 
 close_match_radec,l1.ra,l1.dec,l2.ra,l2.dec,m1,m2,0.005,1.0,miss1
 if (n_elements(m1) eq 0) then begin
	print,'No matches found! ABORTING'
	return
 endif

 m2n=where(l2(m2).m gt 9.0 and l2(m2).m lt 12.0)
 m1n=m1(m2n)
 m2n=m2(m2n)
; im2w=warp_tri(l1(m1n).x,l1(m1n).y,l2(m2n).x,l2(m2n).y,im2)
;Try the polywarp instead....
 polywarp,l2(m2n).x,l2(m2n).y,l1(m1n).x,l1(m1n).y,3,kx,ky
 im2w=poly_2d(im2,kx,ky,2,cubic=-.5)

;Find the limits of overlap in x,y
 xmx_ov=max(l1(m1n).x)
 xmn_ov=min(l1(m1n).x)
 ymx_ov=max(l1(m1n).y)
 ymn_ov=min(l1(m1n).y)
 if (xmx_ov gt 2025) then xmx_ov=2025
 if (xmn_ov lt 10) then xmn_ov=10
 if (ymx_ov gt 2059) then ymx_ov=2059
 if (ymn_ov lt 10) then ymn_ov=10

 magdiff=c1.zp_offset-c2.zp_offset
 magdiff=magdiff/2.5
 brightness_ratio=10^(magdiff)
 print,'brightness_ratio=',brightness_ratio

 sky,im1(900:1100,900:1100),im1sky,im1skyerr
 sky,im2w(900:1100,900:1100),im2sky,im2skyerr
 print,im1sky,im2sky

; imdiff=im1-(im1sky/im2sky)*im2w
 imdiff=im1 - brightness_ratio*im2w
 sky,im1
 sky,im2
 sky,imdiff

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
 if ((size(j))(0) ne 0) then begin
   imdiff(j)=totsky
 endif

 if (keyword_set(write)) then begin
	namearray=str_sep(name1,'_cobj.')
	s1=namearray(0)
	namearray=str_sep(name2,'_cobj.')
	s2=namearray(0)
	difffile=s1+'_'+s2+"_csub.fit"
	print, "Writing subtracted frame to file:",difffile
	writefits,difffile,imdiff	
	outfile=s2+"_warp.fit"
	print, "Writing warped original frame to file:",outfile
	writefits,outfile,im2
	;Note, should really add information to the headers!!!!
	;Now extract the objects in the difference image
	rextract_setup,ps
	ps.CATALOG_NAME=s1+'_'+s2+'_sobj.fit'
	ps.checkimage_type='none'
	rextract,ps,difffile
	l=mrdfits(ps.catalog_name,1,hdr)
	;Remove objects which are negative in flux...
	k=where(l.mag_aper ne 99)
	help,k
	l=l(k)
	x=l.x_image-1
	y=l.y_image-1
	;Now reduce this list to measure things ONLY within the overlap area
	overlap=where(x lt xmx_ov and x gt xmn_ov and $
		y lt ymx_ov and y gt ymn_ov)
	x=x(overlap)
	y=y(overlap)
	;Now find the fluxes by aper in each of the images
	aper,im1,x,y,f1,errap,sky1,skyerr,8.0,[frad],$
		[5.0,9.0],[-33000,65000],/silent,/flux
	f1=reform(f1)
	aper,brightness_ratio*im2w,x,y,f2,errap,sky2,skyerr,8.0,[frad],$
		[5.0,9.0],[-33000,65000],/silent,/flux
	f2=reform(f2)
	aper,imdiff,x,y,fd,errap,skyd,skyerr,8.0,[frad],$
		[5.0,9.0],[-33000,65000],/silent,/flux
	fd=reform(fd)
	nobj=n_elements(x)
	help,nobj
	str=create_struct('x',findgen(nobj),'y',findgen(nobj),$
		'f1',findgen(nobj),'s1',findgen(nobj), $
		'f2',findgen(nobj),'s2',findgen(nobj), $
		'fd',findgen(nobj),'sd',findgen(nobj))
	help,str,/struct
	str.x=x
	str.y=y
	str.f1=f1
	str.s1=sky1
	str.f2=f2
	str.s2=sky2
	str.fd=fd
	str.sd=skyd
	outfile=s1+'_'+s2+'_diff_flux.fit'
	print,'Writing: '+outfile
	mwrfits,str,outfile
 endif		

 im2=im2w

 return
 end





