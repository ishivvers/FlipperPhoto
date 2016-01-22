
pro addmatch_s, obj_template, obj_add, newmatch, keep=keep, skip=skip, $
	iter=iter, hdr=hdr, kx=kx, ky=ky, subr=subr, fail=fail, ebox=ebox
;+
; NAME:	ADDMATCH_S
;
; CALLING SEQUENCE:	addmatch_s, obj_template, obj_add, match
;
; INPUTS:	obj_template: input object structure from cat_match etc..
;		obj_add: object structure from new image (from sextractor)
;
; OUTPUTS:	newmatch: concatenated list of matched objects
;	
;
; INPUT KEYWORDS:
;		keep: how many to triangle match
;		skip: how many to skip at bright end
;		iter: how many iterations of the fit to do
;		hdr: header for observation
;		kx: x transformation
;		ky: y transformation
;		subr: fraction of image to use for triangle match
;               fail: returns 1 if no match is made else 0
;		ebox: size (in pixels) of final match box
;			
; PROCEDURE:	Matches and transforms two object structures
;		Structures must contain the following elements:
;			x_image, y_image, mag_best
;		And the structure type should be "SOBJ"
;		This version takes in a multiobservation list, and merges
;		in the observations from one new list
;
; REVISION HISTORY:  
;	Tim McKay		UM		9/26/97	
;	Tim McKay		UM	 	2/3/98 Altered for sextractor
;	Tim McKay		UM	 	2/17/98 Altered again for 
;						   simpler structure
;	Tim McKay		UM		5/6/98 Fixing small
                                ;bugs
;       Dave Johnston           UM              5/13/98 returns
                                ;       gracefully if
                                ;       triangle_match fails to find a
                                ;       match
                                ;       returns fail=1 if no match is made
;	Tim McKay		UM		5/19/98 Add calculation of
;					ra,dac for unmatched objects
;	Tim McKay		UM	Add ebox argument
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - addmatch_s, match, obj3, newmatch, keep=keep, skip=skip, iter=iter, hdr=hdr, kx=kx, ky=ky, subr=subr,fail=fail,ebox=ebox'
        return
 endif

  if not keyword_set(skip) then begin
	skip=0
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

;First sort the new image by magnitude
  sort=sort(obj_add.mag_best)
  obj_add=obj_add(sort)
  nobs=N_elements(obj_add)

;Making a local copy of the coordinates...Fix the sextractor thing here
  xim=obj_add.x_image-1
  yim=obj_add.y_image-1

  print, "Keep=",keep,"     Skip=",skip

;First match the images to one another
  print, ""
  print, "Triangle matching the coordinates"

;As a first step, extract the central 30% of each list. This requires that
;the positions should be correct to about 10% of the width!
  txmin=min(obj_template.x(0,*))
  txmax=max(obj_template.x(0,*))
  tymin=min(obj_template.y(0,*))
  tymax=max(obj_template.y(0,*))
  txrange=txmax-txmin
  tyrange=tymax-tymin
  tsub=where(obj_template.x(0,*) gt (txmin+(1-subr)*0.5*txrange) and $
	obj_template.x(0,*) lt (txmin+(1+subr)*0.5*txrange) and $
	obj_template.y(0,*) gt (tymin+(1-subr)*0.5*tyrange) and $
	obj_template.y(0,*) lt (tymin+(1+subr)*0.5*tyrange))
  axmin=min(xim)
  axmax=max(xim)
  aymin=min(yim)
  aymax=max(yim)
  axrange=axmax-axmin
  ayrange=aymax-aymin
  asub=where(xim gt (axmin+(1-subr)*0.5*axrange) and $
	xim lt (axmin+(1+subr)*0.5*axrange) and $
	yim gt (aymin+(1-subr)*0.5*ayrange) and $
	yim lt (aymin+(1+subr)*0.5*ayrange))

  triangle_match,obj_template.x(0,tsub(skip:skip+keep)), $
	obj_template.y(0,tsub(skip:skip+keep)),$
	xim(asub(skip:skip+keep)),$
	yim(asub(skip:skip+keep)),$
	0.005,1,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky

;If it fails to find a match then ...
if n_elements(kx) eq 1 then begin
    print,'returning from addmatch without adding match'
    fail=1
    return
endif

;Assuming this works, now transform image 2 to image 1 coordinates
  print,""
  print,"Transforming list two to list one coordinates"
  kmap,xim,yim,xx,yy,kx,ky

;Now close match the two
  print, ""
  nuse=nobs/10
  print, "Close matching the two lists"
  close_match,obj_template.x(0,0:nuse),obj_template.y(0,0:nuse), $
	xx(0:nuse),yy(0:nuse),m1,m2,0.5,1,miss1

  magdiff=median(obj_template.rmag(m1)-obj_add(m2).mag_best)
  mnew=obj_add(m2).mag_best+magdiff
  var=moment(obj_template.rmag(m1)-mnew)
  sigma=sqrt(var(1))
  print,"photometry",magdiff,sigma
  n=where(abs(obj_template.rmag(m1)-mnew) gt sigma,nfound) 
  print,"Removing from the fit:",n
  if (nfound gt 0) then begin
	  remove,n,m1,m2
  endif

  rpos_errors,obj_template.x(0,*),obj_template.y(0,*),$
	xim,yim,m1,m2,kx,ky
 
;Now iterate "iter" times on the solution
  for i=1,iter do begin 
	print, "Looping over solution:",i,"   of:",iter
	polywarp,obj_template.x(0,m1),obj_template.y(0,m1),$
		xim(m2),yim(m2),3,kx,ky
	kmap,xim,yim,xx,yy,kx,ky
	if (i lt iter) then begin
	  print, "Close matching to 0.5 pixel"
	  close_match,obj_template.x(0,0:nuse),obj_template.y(0,0:nuse),$
		xx(0:nuse),yy(0:nuse),m1,m2,0.5,1,miss1

	  magdiff=median(obj_template.rmag(m1)-obj_add(m2).mag_best)
	  mnew=obj_add(m2).mag_best+magdiff
 	  var=moment(obj_template.rmag(m1)-mnew)
 	  sigma=sqrt(var(1))
	  print,"photometry",magdiff,sigma
 	  n=where(abs(obj_template.rmag(m1)-mnew) gt sigma,nfound) 
 	  print,"Removing from the fit:",n
 	  if (nfound gt 0) then begin
	    remove,n,m1,m2
  	  endif

	endif else begin
	  print, 'Final close match to '+string(ebox)+' pixels'
	  close_match,obj_template.x(0,*),obj_template.y(0,*),$
		xx,yy,m1,m2,ebox,1,miss1
	endelse 

	rpos_errors,obj_template.x(0,*), $
		obj_template.y(0,*),$
		xim,yim,m1,m2,kx,ky

  end

;Now stuff the results into combined structure. This includes everything
;from the template as well as eveything in the new image NOT in the template.
;Cuts on what objects are acceptable should be made BEFORE inputting lists
;into this matcher.
  print, ""
  print, "Stuffing matches"
  template_obj=N_elements(obj_template.x(0,*))
  n2=N_elements(xim)
  miss2=lindgen(n2)
  remove,m2,miss2
  nmisses=N_elements(miss2)
  nobj=template_obj+nmisses
  nobs=N_elements(obj_template.x(*,0))+1
  print, "Number of observations=",nobs-1,"      Number of objects=",nobj

  match=create_struct("kx",findgen(nobs,4,4),"ky",findgen(nobs,4,4),"jd",$
	dindgen(nobs),$
	"filter",sindgen(nobs),"exptime",findgen(nobs),$
	"imagename",sindgen(nobs),"airmass",findgen(nobs),$
	"rac",findgen(1),"decc",findgen(1),$
	"x",findgen(nobs,nobj),"y",findgen(nobs,nobj),$
	"m",findgen(nobs,nobj),$
	"merr",findgen(nobs,nobj),$
	"fwhm",findgen(nobs,nobj),$
	"ra",dindgen(nobj),$
	"dec",dindgen(nobj),$
	"rmag",findgen(nobj),$
	"bmag",findgen(nobj))
; Give default values to all new entries
  match.kx(*,*,*)=-1.0
  match.ky(*,*,*)=-1.0
  match.jd(*)=-1.0
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
  match.kx(0:nobs-2,*,*,*)=obj_template.kx(*,*,*)
  match.ky(0:nobs-2,*,*,*)=obj_template.ky(*,*,*)
  match.kx(nobs-1,*,*)=kx
  match.ky(nobs-1,*,*)=ky
;Now try to stuff the frame specific information. 
;To do this you must be passed the headers
;from the list or image which has this information
  match.jd(0:nobs-2)=obj_template.jd(*)
  match.filter(0:nobs-2)=obj_template.filter(*)
  match.imagename(0:nobs-2)=obj_template.imagename(*)
  match.exptime(0:nobs-2)=obj_template.exptime(*)
  match.airmass(0:nobs-2)=obj_template.airmass(*)
  if keyword_set(hdr) then begin
       match.jd(nobs-1)=sxpar(hdr,"JD")
       if (!err ne 0) then begin
	  match.jd(nobs-1)=-1.0
	  !err=0
       endif
       match.filter(nobs-1)=sxpar(hdr,"FILTERS")
       if (!err ne 0) then begin
	  match.filter(nobs-1)='none'
	  !err=0
       endif
       match.imagename(nobs-1)=sxpar(hdr,"IMAGENAME")
       if (!err ne 0) then begin
	  match.imagename(nobs-1)='unknown'
	  !err=0
       endif
       match.exptime(nobs-1)=sxpar(hdr,"EXPTIME")
       if (!err ne 0) then begin
	  match.exptime(nobs-1)=-1.0
	  !err=0
       endif
       match.airmass(nobs-1)=sxpar(hdr,"AIRMASS")
       if (!err ne 0) then begin
	  match.airmass(nobs-1)=-1.0
	  !err=0
       endif
  endif
; Now stuff the information on how you matched this
  match.rac(0)=obj_template.rac(0)
  match.decc(0)=obj_template.decc(0)
; Now stuff the old stuff
  match.x(0:nobs-2,0:template_obj-1)=obj_template.x(*,*)
  match.y(0:nobs-2,0:template_obj-1)=obj_template.y(*,*)
  match.m(0:nobs-2,0:template_obj-1)=obj_template.m(*,*)
  match.merr(0:nobs-2,0:template_obj-1)=obj_template.merr(*,*)
  match.fwhm(0:nobs-2,0:template_obj-1)=obj_template.fwhm(*,*)
  match.ra(0:template_obj-1)=obj_template.ra
  match.dec(0:template_obj-1)=obj_template.dec
  match.bmag(0:template_obj-1)=obj_template.bmag
  match.rmag(0:template_obj-1)=obj_template.rmag

; Now add the matches
  match.x(nobs-1,m1)=xim(m2)
  match.y(nobs-1,m1)=yim(m2)
  match.m(nobs-1,m1)=obj_add(m2).mag_best
  match.merr(nobs-1,m1)=obj_add(m2).magerr_best
  match.fwhm(nobs-1,m1)=obj_add(m2).fwhm_image

  print, ""
  print, "Stuffing misses from image"
  match.x(0,template_obj:nobj-1)=xx(miss2)
  match.x(nobs-1,template_obj:nobj-1)=xim(miss2)
  match.y(0,template_obj:nobj-1)=yy(miss2)  
  match.y(nobs-1,template_obj:nobj-1)=yim(miss2)
  match.m(0,template_obj:nobj-1)=obj_add(miss2).mag_best
  match.m(nobs-1,template_obj:nobj-1)=obj_add(miss2).mag_best
  match.merr(0,template_obj:nobj-1)=obj_add(miss2).magerr_best
  match.merr(nobs-1,template_obj:nobj-1)=obj_add(miss2).magerr_best
  match.fwhm(0,template_obj:nobj-1)=obj_add(miss2).fwhm_image
  match.fwhm(nobs-1,template_obj:nobj-1)=obj_add(miss2).fwhm_image

; Need to generate ra and dec for unmatched positions
  kx_old=findgen(4,4)
  ky_old=findgen(4,4)
  kx_old(*,*)=obj_template.kx(1,*,*)
  ky_old(*,*)=obj_template.ky(1,*,*)
  kmap_inv,xx(miss2),yy(miss2),xp,yp,kx_old,ky_old
  convert2rd,xp,yp,r,d,rac=obj_template.rac,decc=obj_template.decc
  match.ra(template_obj:nobj-1)=r
  match.dec(template_obj:nobj-1)=d


;Now reassign the new match structure to the old name
  newmatch=match
  
  fail=0
  return
  end














