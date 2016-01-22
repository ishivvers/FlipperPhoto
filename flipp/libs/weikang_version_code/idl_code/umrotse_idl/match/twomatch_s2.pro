
pro twomatch_s2, obj1, obj2, match, keep=keep, skip=skip, iter=iter, $
	kx=kx, ky=ky, ohdr1=ohdr1, ohdr2=ohdr2
;+
; NAME:	TWOMATCH_S2
;
; CALLING SEQUENCE:	twomatch_s2, obj1, obj2, match
;
; INPUTS:	obj1: object structure from image 1
;		obj2: object structure from image 2
;
; OUTPUTS:	match: concatenated list of matched objects
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Matches and transforms two object structures
;		Structures must contain the following elements:
;			x_image, y_image, mag_best, fwhm_image
;
; REVISION HISTORY:  
;	Tim McKay		UM		9/26/97	
;	Tim McKay		UM		2/17/98	
;	Tim McKay		UM		2/24/98  Added times etc...
;******************************************************************************

 if N_params() eq 0 then begin
        print,"Syntax - twomatch_s2, obj1, obj2, match, keep=keep, skip=skip, iter=iter, kx=kx, ky=ky"
        return
 endif

  if not keyword_set(skip) then begin
	skip=0
  end
  if not keyword_set(keep) then begin
	keep=30
  end
  if not keyword_set(iter) then begin
	iter=1
  end


  print, "Keep=",keep,"     Skip=",skip

;First sort each image by magnitude
  sort=sort(obj1.mag_best)
  obj1=obj1(sort)
  sort=sort(obj2.mag_best)
  obj2=obj2(sort)
  nobs1=N_elements(obj1)
  nobs2=N_elements(obj2)
  if(nobs1 gt nobs2) then begin
	nobs=nobs2
  endif else begin
	nobs=nobs1
  endelse


;First match the images to one another
  print, ""
  print, "Triangle matching the coordinates"
  triangle_match,obj1(skip:skip+keep).x_image,obj1(skip:skip+keep).y_image,$
	obj2(skip:skip+keep).x_image,obj2(skip:skip+keep).y_image,$
	0.005,1,trans21,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky

;Assuming this works, now transform image 2 to image 1 coordinates
  print,""
  print,"Transforming list two to list one coordinates"
  kmap,obj2.x_image,obj2.y_image,xx,yy,kx,ky

;Now close match the two
  print, ""
  print, "Close matching the two lists"
  nuse=nobs/5
  close_match,obj1(0:nuse).x_image,obj1(0:nuse).y_image,$
	xx(0:nuse),yy(0:nuse),m1,m2,1.0,2,miss1
  rpos_errors,obj1.x_image,obj1.y_image,obj2.x_image,obj2.y_image,m1,m2,kx,ky

;Now iterate "iter" times on the solution, in the final match open the 
;restriction for matching to 1.5 pixels!
  for i=1,iter do begin 
	print, "Looping over solution:",i,"   of:",iter
	polywarp,obj1(m1).x_image,obj1(m1).y_image,$
		obj2(m2).x_image,obj2(m2).y_image,3,kx,ky
	kmap,obj2.x_image,obj2.y_image,xx,yy,kx,ky
	if (i lt iter) then begin
	  print, "Close matching to 1 pixel"
	  close_match,obj1(0:nuse).x_image,obj1(0:nuse).y_image,$
		xx(0:nuse),yy(0:nuse),m1,m2,1.0,1,miss1
	endif else begin
	  print, "Final close match to 1.5 pixels"
	  close_match,obj1.x_image,obj1.y_image,$
		xx,yy,m1,m2,1.5,1,miss1
	endelse 
	rpos_errors,obj1.x_image,obj1.y_image,obj2.x_image,$
		obj2.y_image,m1,m2,kx,ky
  end

;Now create larger arrays of the observations
  print, ""
  print, "Stuffing matches"
  nmisses1=N_elements(miss1)
  nmatches=N_elements(m1)
  n2=N_elements(obj2)
  miss2=lindgen(n2)
  remove,m2,miss2
  nmisses2=N_elements(miss2)
  nobj=nmatches+nmisses1+nmisses2

  match=create_struct("kx",findgen(3,4,4),"ky",findgen(3,4,4),"jd",dindgen(3),$
	"filter",sindgen(3),"exptime",findgen(3),$
	"x",findgen(3,nobj),"y",findgen(3,nobj),$
	"m",findgen(3,nobj),$
	"merr",findgen(3,nobj),$
	"fwhm",findgen(3,nobj))
; Give default values to all new entries
  match.kx(*,*,*)=-1.0
  match.ky(*,*,*)=-1.0
  match.jd(*)=-1.0
  match.filter(*)='none'
  match.exptime(*)=-1.0
  match.x(*,*)=-1.0
  match.y(*,*)=-1.0
  match.m(*,*)=-1.0
  match.merr(*,*)=-1.0
  match.fwhm(*,*)=-1.0
;First stuff in the trans structures for each observation. These transform
;each observation to the coordinates of the first (FOR NOW, should be RA DEC).
  match.kx(2,*,*)=kx
  match.ky(2,*,*)=ky
;Now try to stuff the frame specific information. 
;To do this you must be passed the headers
;from the list or image which has this information
  if keyword_set(ohdr1) then begin
       match.jd(1)=sxpar(ohdr1,"JD")
       if (!err ne 0) then begin
	  match.jd(1)=-1.0
	  !err=0
       endif
       match.filter(1)=sxpar(ohdr1,"FILTERS")
       if (!err ne 0) then begin
	  match.filter(1)='none'
	  !err=0
       endif
       match.exptime(1)=sxpar(ohdr1,"EXPTIME")
       if (!err ne 0) then begin
	  match.exptime(1)=-1.0
	  !err=0
       endif
  endif
  if keyword_set(ohdr2) then begin
       match.jd(2)=sxpar(ohdr2,"JD")
       if (!err ne 0) then begin
	  match.jd(2)=-1.0
	  !err=0
       endif
       match.filter(2)=sxpar(ohdr2,"FILTERS")
       if (!err ne 0) then begin
	  match.filter(2)='none'
	  !err=0
       endif
       match.exptime(2)=sxpar(ohdr2,"EXPTIME")
       if (!err ne 0) then begin
	  match.exptime(2)=-1.0
	  !err=0
       endif
  endif
; Now stuff the real stuff
  match.x(0,0:nmatches-1)=obj1(m1).x_image-1
  match.y(0,0:nmatches-1)=obj1(m1).y_image-1
  match.x(1,0:nmatches-1)=obj1(m1).x_image-1
  match.y(1,0:nmatches-1)=obj1(m1).y_image-1
  match.x(2,0:nmatches-1)=obj2(m2).x_image-1
  match.y(2,0:nmatches-1)=obj2(m2).y_image-1
  match.m(0,0:nmatches-1)=obj1(m1).mag_best
  match.m(1,0:nmatches-1)=obj1(m1).mag_best
  match.m(2,0:nmatches-1)=obj2(m2).mag_best
  match.merr(0,0:nmatches-1)=obj1(m1).magerr_best
  match.merr(1,0:nmatches-1)=obj1(m1).magerr_best
  match.merr(2,0:nmatches-1)=obj2(m2).magerr_best
  match.fwhm(0,0:nmatches-1)=obj1(m1).fwhm_image
  match.fwhm(1,0:nmatches-1)=obj1(m1).fwhm_image
  match.fwhm(2,0:nmatches-1)=obj2(m2).fwhm_image
  print, ""
  print, "Stuffing misses from image 1"
  match.x(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).x_image-1
  match.x(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).x_image-1
  match.y(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).y_image-1
  match.y(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).y_image-1
  match.m(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).mag_best
  match.m(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).mag_best
  match.merr(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).magerr_best
  match.merr(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).magerr_best
  match.fwhm(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).fwhm_image
  match.fwhm(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).fwhm_image
  print, ""
  print, "Stuffing misses from image 2"
  match.x(0,nmatches+nmisses1:nobj-1)=xx(miss2)-1
  match.x(2,nmatches+nmisses1:nobj-1)=obj2(miss2).x_image-1
  match.y(0,nmatches+nmisses1:nobj-1)=yy(miss2)-1
  match.y(2,nmatches+nmisses1:nobj-1)=obj2(miss2).y_image-1
  match.m(0,nmatches+nmisses1:nobj-1)=obj2(miss2).mag_best
  match.m(2,nmatches+nmisses1:nobj-1)=obj2(miss2).mag_best
  match.merr(0,nmatches+nmisses1:nobj-1)=obj2(miss2).magerr_best
  match.merr(2,nmatches+nmisses1:nobj-1)=obj2(miss2).magerr_best
  match.fwhm(0,nmatches+nmisses1:nobj-1)=obj2(miss2).fwhm_image
  match.fwhm(2,nmatches+nmisses1:nobj-1)=obj2(miss2).fwhm_image

;Now we're done

  return
  end









