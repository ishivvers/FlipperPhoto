pro catmatch_s, rac,decc, usnocat,sobj, match, keep=keep, skip=skip, $
	iter=iter, kx=kx, ky=ky, hdr=hdr, catlim=catlim, subr=subr, $
	rskip=rskip, fail=fail, ebox=ebox, nusefrac=nusefrac
;+
; NAME:	CATMATCH_S
;
; CALLING SEQUENCE:	catmatch_s, rac, decc, usnocat, sobj, match
;
; INPUTS:	usnocat: structure extracted from USNOA1.0
;		sobj: object structure from image derived from Sextractor
;
; OUTPUTS:	match: concatenated list of matched objects
;
; INPUT KEYWORDS:
;		keep: how many objects to match
;		skip: how many of the brightest to skip
;		iter: how many iterations of the fit to do
;		kx:   return of transform x coefficients
;		ky:   return of transform y coefficients
;		hdr:  pass this to get times etc. in the output structure
;		catlim: include catalog objects to what magnitude?
;		subr: the fraction of the image to match to the catalog
;		rskip: number of brightest rotse objects to skip
;		fail: return 1 here if it doesn't match
;		ebox: size (in pixels) for final match requirement
;			
; PROCEDURE:	Matches and transforms two object structures
;		Structures must contain the following elements:
;		USNO: ra, dec, rmag, bmag
;		SOBJ: x_image, y_image, mag_best, fwhm_image
;
; REVISION HISTORY:  
;	Tim McKay		UM		9/26/97	
;	Tim McKay		UM		2/17/98	
;	Tim McKay		UM		2/24/98  Added times etc...
;	Tim Mckay		UM		4/16/98  Modified from
;							 twomatch
;	Tim McKay		UM		5/6/98 	 Fixing bugs,
;							 tuning performance
;	Tim McKay		UM		5/19/98  Adding xy->radec
;	Tim McKay		UM		7/6/98   Added keyword
;							 for final match size
;******************************************************************************

 if N_params() eq 0 then begin
        print,"Syntax - catmatch_s, rac, decc, usnocat, sobj, match, keep=keep, skip=skip, rskip=rskip, iter=iter, kx=kx, ky=ky, hdr=hdr, ebox=ebox"
        return
 endif

  if not keyword_set(skip) then begin
	skip=0
  end
  if not keyword_set(rskip) then begin
	rskip=0
  end
  if not keyword_set(keep) then begin
	keep=30
  end
  if not keyword_set(iter) then begin
	iter=4
  end
  if not keyword_set(subr) then begin
	subr=1.0
  end
  if not keyword_set(ebox) then begin
	ebox=1.0
  end
  if not keyword_set(nusefrac) then begin
	nusefrac=0.1
  end


  print, "Keep=",keep,"     Skip=",skip,"     Rskip=",rskip 

;First sort each image by magnitude
  sort=sort(usnocat.rmag)
;For now this is a structure of arrays, so all elements we need must
;be sorted individually. Would like to change this to an array of 
;structures like the sobj output.
  usnocat.ra=usnocat.ra(sort)
  usnocat.dec=usnocat.dec(sort)
  usnocat.bmag=usnocat.bmag(sort)
  usnocat.rmag=usnocat.rmag(sort)
;Now sort the list 
  sort=sort(sobj.mag_best)
  sobj=sobj(sort)
  nobs=N_elements(sobj)
  ncat=N_elements(usnocat.ra)

;Now project the catalog ra and dec to (x,y) coordinates
  convert2xy,usnocat.ra,usnocat.dec,xc,yc,rac=rac,decc=decc

;Now create a local copy of the image positions for use here
  xim=sobj.x_image-1
  yim=sobj.y_image-1

;First match the images to one another
  print, ""
  print, "Triangle matching the coordinates"
;As a first step, extract the central 30% of each list. This requires that
;the positions should be correct to about 10% of the width!
  sxmin=min(xim)
  sxmax=max(xim)
  symin=min(yim)
  symax=max(yim)
  sxrange=sxmax-sxmin
  syrange=symax-symin
  ssub=where(xim gt (sxmin+(1-subr)*0.5*sxrange) and $
	xim lt (sxmin+(1+subr)*0.5*sxrange) and $
	yim gt (symin+(1-subr)*0.5*syrange) and $
	yim lt (symin+(1+subr)*0.5*syrange))
  cxmin=min(xc)
  cxmax=max(xc)
  cymin=min(yc)
  cymax=max(yc)
  cxrange=cxmax-cxmin
  cyrange=cymax-cymin
  csub=where(xc gt (cxmin+(1-subr)*0.5*cxrange) and $
	xc lt (cxmin+(1+subr)*0.5*cxrange) and $
	yc gt (cymin+(1-subr)*0.5*cyrange) and $
	yc lt (cymin+(1+subr)*0.5*cyrange))

  print,''
  print,'Limits for subr cuts...'
  print,(sxmin+(1-subr)*0.5*sxrange),(sxmin+(1+subr)*0.5*sxrange)
  print,(cxmin+(1-subr)*0.5*cxrange),(cxmin+(1+subr)*0.5*cxrange)
  triangle_match,xim(ssub(rskip:rskip+keep)),$
	yim(ssub(rskip:rskip+keep)),$
	xc(csub(skip:skip+keep)),yc(csub(skip:skip+keep)),$
	0.005,1,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky

;If it fails to find a match then ...
  if n_elements(kx) eq 1 then begin
    print,'returning from catmatch without finding match'
    fail=1
    return
  endif

  magdiff=median(usnocat.rmag(m2)-sobj(m1).mag_best)
  mnew=sobj(m1).mag_best+magdiff
  print,magdiff
  print,sobj(m1).mag_best
  print,usnocat.rmag(m2)
  print,usnocat.rmag(m2)-mnew
  n=where(abs(usnocat.rmag(m2)-mnew) gt 1,nfound) 
  info=size(n)
  print,"Removing from the fit:",info(1)
  if (nfound gt 0) then begin
	  remove,n,m1,m2
  endif

;Assuming this works, now transform image 2 to image 1 coordinates
  print,""
  print,"Transforming list two to list one coordinates"
  kx(1,1)=0.0
  ky(1,1)=0.0
  kmap,xc,yc,xx,yy,kx,ky

;Now close match the two, only deal with the brightest fifth of the objects
  print, ""
  print, "Close matching the two lists"
  nuse=nobs*nusefrac-1
  if (nuse eq 0) then begin
	nuse=nobs
  endif
  if (nuse gt ncat-1) then begin
	nuse=ncat-1
  endif
  close_match,xim(0:nuse),yim(0:nuse),$
	xx(0:nuse),yy(0:nuse),m1,m2,2.0,1,miss1
  rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky

  magdiff=median(usnocat.rmag(m2)-sobj(m1).mag_best)
  mnew=sobj(m1).mag_best+magdiff
  n=where(abs(usnocat.rmag(m2)-mnew) gt 1,nfound) 
  info=size(n)
  print,"Removing from the fit:",info(1)
  if (nfound gt 0) then begin
	  remove,n,m1,m2
  endif

;Now iterate "iter" times on the solution
  for i=1,iter do begin 
	print, "Looping over solution:",i,"   of:",iter
	polywarp,xim(m1),yim(m1),xc(m2),yc(m2),3,kx,ky
	kmap,xc,yc,xx,yy,kx,ky
	if (i lt iter) then begin
	  print, "Close matching to 0.5 ebox"
  	  close_match,xim(0:nuse),yim(0:nuse),$
		xx(0:nuse),yy(0:nuse),m1,m2,0.5*ebox,1,miss1
	  magdiff=median(usnocat.rmag(m2)-sobj(m1).mag_best)
	  mnew=sobj(m1).mag_best+magdiff
	  n=where(abs(usnocat.rmag(m2)-mnew) gt 1,nfound) 
  	  info=size(n)
  	  print,"Removing from the fit:",info(1)
	  if (nfound gt 0) then begin
		  remove,n,m1,m2
	  endif

	endif else begin
	  print, 'Final close match to ',+string(ebox)+' pixels'
  	  close_match,xim,yim,xx,yy,m1,m2,ebox,1,miss1
	endelse 
  	rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky
  end

;Now create larger arrays of the observations
  print, ""
  print, "Stuffing objects"
  nmisses1=N_elements(miss1)
  nmatches=N_elements(m1)
  n2=n_elements(usnocat.rmag)
  miss2=lindgen(n2)
  remove,m2,miss2
  nmisses2=n_elements(miss2)
  nobj=nmatches+nmisses1+nmisses2
  print,"Objects:",nobj,"  nmatches:",nmatches
  print,"   nmisses1:",nmisses1,"   nmisses2:",nmisses2

  match=create_struct("kx",findgen(2,4,4),"ky",findgen(2,4,4),"jd",$
	dindgen(2),$
	"filter",sindgen(2),"exptime",findgen(2),$
	"imagename",sindgen(2),"airmass",findgen(2),$
	"rac",findgen(1),"decc",findgen(1),$
	"x",findgen(2,nobj),"y",findgen(2,nobj),$
	"m",findgen(2,nobj),$
	"merr",findgen(2,nobj),$
	"fwhm",findgen(2,nobj),$
	"ra",dindgen(nobj),$
	"dec",dindgen(nobj),$
	"rmag",findgen(nobj),$
	"bmag",findgen(nobj))
; Give default values to all new entries
  match.kx(*,*,*)=-1.0
  match.ky(*,*,*)=-1.0
  match.jd(*,*)=-1.0
  match.filter(*)='none'
  match.imagename(*)='unknown'
  match.exptime(*)=-1.0
  match.airmass(*)=-1.0
  match.x(*,*)=-1.0
  match.y(*,*)=-1.0
  match.m(*,*)=-1.0
  match.merr(*,*)=-1.0
  match.fwhm(*,*)=-1.0
  match.ra(*)=-1.0
  match.dec(*)=-1.0
  match.rmag(*)=-1.0
  match.bmag(*)=-1.0
;First stuff in the trans structures for each observation. These transform
;each observation to the coordinates of the first (FOR NOW, should be RA DEC).
  match.kx(1,*,*)=kx
  match.ky(1,*,*)=ky
;Now try to stuff the frame specific information. 
;To do this you must be passed the headers
;from the list or image which has this information
  if keyword_set(hdr) then begin
       match.jd(1)=sxpar(hdr,"JD")
       if (!err ne 0) then begin
	  match.jd(1)=-1.0
	  !err=0
       endif
       match.filter(1)=sxpar(hdr,"FILTERS")
       if (!err ne 0) then begin
	  match.filter(1)='none'
	  !err=0
       endif
       match.exptime(1)=sxpar(hdr,"EXPTIME")
       if (!err ne 0) then begin
	  match.exptime(1)=-1.0
	  !err=0
       endif
       match.airmass(1)=sxpar(hdr,"AIRMASS")
       if (!err ne 0) then begin
	  match.airmass(1)=-1.0
	  !err=0
       endif
  endif
; Now stuff the information on how you matched this
  match.rac(0)=rac
  match.decc(0)=decc
; Now stuff the real stuff
  match.x(0,0:nmatches-1)=xim(m1)
  match.y(0,0:nmatches-1)=yim(m1)
  match.m(0,0:nmatches-1)=sobj(m1).mag_best
  match.merr(0,0:nmatches-1)=sobj(m1).magerr_best
  match.fwhm(0,0:nmatches-1)=sobj(m1).fwhm_image
  match.x(1,0:nmatches-1)=xim(m1)
  match.y(1,0:nmatches-1)=yim(m1)
  match.m(1,0:nmatches-1)=sobj(m1).mag_best
  match.merr(1,0:nmatches-1)=sobj(m1).magerr_best
  match.fwhm(1,0:nmatches-1)=sobj(m1).fwhm_image
  match.ra(0:nmatches-1)=usnocat.ra(m2)
  match.dec(0:nmatches-1)=usnocat.dec(m2)
  match.bmag(0:nmatches-1)=usnocat.bmag(m2)
  match.rmag(0:nmatches-1)=usnocat.rmag(m2)
  print, ""
  print, "Stuffing misses from image"
  match.x(0,nmatches:nmatches+nmisses1-1)=xim(miss1)
  match.y(0,nmatches:nmatches+nmisses1-1)=yim(miss1)
  match.m(0,nmatches:nmatches+nmisses1-1)=sobj(miss1).mag_best
  match.merr(0,nmatches:nmatches+nmisses1-1)=sobj(miss1).magerr_best
  match.fwhm(0,nmatches:nmatches+nmisses1-1)=sobj(miss1).fwhm_image
  match.x(1,nmatches:nmatches+nmisses1-1)=xim(miss1)
  match.y(1,nmatches:nmatches+nmisses1-1)=yim(miss1)
  match.m(1,nmatches:nmatches+nmisses1-1)=sobj(miss1).mag_best
  match.merr(1,nmatches:nmatches+nmisses1-1)=sobj(miss1).magerr_best
  match.fwhm(1,nmatches:nmatches+nmisses1-1)=sobj(miss1).fwhm_image
; Need to generate ra and dec for unmatched positions
  kmap_inv,xim(miss1),yim(miss1),xp,yp,kx,ky
  convert2rd,xp,yp,r,d,rac=rac,decc=decc
  match.ra(nmatches:nmatches+nmisses1-1)=r
  match.dec(nmatches:nmatches+nmisses1-1)=d
  print, ""
  print, "Stuffing misses from catalog"
  match.x(0,nmatches+nmisses1:nobj-1)=xx(miss2)
  match.y(0,nmatches+nmisses1:nobj-1)=yy(miss2)
  match.ra(nmatches+nmisses1:nobj-1)=usnocat.ra(miss2)
  match.dec(nmatches+nmisses1:nobj-1)=usnocat.dec(miss2)
  match.bmag(nmatches+nmisses1:nobj-1)=usnocat.bmag(miss2)
  match.rmag(nmatches+nmisses1:nobj-1)=usnocat.rmag(miss2)

;Now we're done

  return
  end








