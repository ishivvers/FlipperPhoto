
pro addmatch_s2, obj_template, obj_add, newmatch, keep=keep, skip=skip, $
	iter=iter, ohdr=ohdr,$
	kx=kx, ky=ky, m1=m1, m2=m2
;+
; NAME:	ADDMATCH_S2
;
; CALLING SEQUENCE:	addmatch_s2, obj_template, obj_add, match, miss
;
; INPUTS:	obj_template: input object structure 
;		obj_add: object structure from new image
;
; OUTPUTS:	match: concatenated list of matched objects
;		miss: list of misses, in coordinates of image 1!
;
; INPUT KEYWORDS:
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
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - addmatch_s2, match, obj3, newmatch, keep=keep, skip=skip, iter=iter, kx=kx, ky=ky, m1=m1, m2=m2'
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

;First sort the new image by magnitude
  sort=sort(obj_add.mag_best)
  obj_add=obj_add(sort)
  nobs=N_elements(obj_add)


  print, "Keep=",keep,"     Skip=",skip

;First match the images to one another
  print, ""
  print, "Triangle matching the coordinates"
  help,obj_template,/structures
  triangle_match,obj_template.x(0,skip:skip+keep), $
	obj_template.y(0,skip:skip+keep),$
	obj_add(skip:skip+keep).x_image,obj_add(skip:skip+keep).y_image,$
	0.005,1,trans21,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky

;Assuming this works, now transform image 2 to image 1 coordinates
  print,""
  print,"Transforming list two to list one coordinates"
  kmap,obj_add.x_image,obj_add.y_image,xx,yy,kx,ky

;Now close match the two
  print, ""
  print, "Close matching the two lists"
  nuse=nobs/5
  close_match,obj_template.x(0,0:nuse),obj_template.y(0,0:nuse), $
	xx(0:nuse),yy(0:nuse),m1,m2,1.0,2,miss1
  rpos_errors,obj_template.x(0,*),obj_template.y(0,*),$
	obj_add.x_image,obj_add.y_image,m1,m2,kx,ky

;Now iterate "iter" times on the solution
  for i=1,iter do begin 
	print, "Looping over solution:",i,"   of:",iter
	polywarp,obj_template.x(0,m1), $
		obj_template.y(0,m1),$
		obj_add(m2).x_image,obj_add(m2).y_image,3,kx,ky
	kmap,obj_add.x_image,obj_add.y_image,xx,yy,kx,ky
	if (i lt iter) then begin
	  print, "Close matching to 1 pixel"
	  close_match,obj_template.x(0,0:nuse),obj_template.y(0,0:nuse),$
		xx(0:nuse),yy(0:nuse),m1,m2,1.0,1,miss1
	endif else begin
	  print, "Final close match to 1.5 pixels"
	  close_match,obj_template.x(0,*),obj_template.y(0,*),$
		xx,yy,m1,m2,1.5,1,miss1
	endelse 
	rpos_errors,obj_template.x(0,*), $
		obj_template.y(0,*),$
		obj_add.x_image,obj_add.y_image,m1,m2,kx,ky
  end

;Now stuff the results into combined structure. This includes everything
;from the template as well as eveything in the new image NOT in the template.
;Cuts on what objects are acceptable should be made BEFORE inputting lists
;into this matcher.
  print, ""
  print, "Stuffing matches"
  template_obj=N_elements(obj_template.x(0,*))
  n2=N_elements(obj_add.x_image)
  miss2=lindgen(n2)
  remove,m2,miss2
  nmisses=N_elements(miss2)
  nobj=template_obj+nmisses
  nobs=N_elements(obj_template.x(*,0))+1
  print, "Number of observations=",nobs,"      Number of objects=",nobj

  match=create_struct("kx",findgen(nobs,4,4),"ky",findgen(nobs,4,4),"jd",dindgen(nobs),$
	"filter",sindgen(nobs),"exptime",findgen(nobs),$
	"x",findgen(nobs,nobj),"y",findgen(nobs,nobj),$
	"m",findgen(nobs,nobj),$
	"merr",findgen(nobs,nobj),$
	"fwhm",findgen(nobs,nobj))
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
;Also stuff the header information for the frame specific stuff like 
;exposure time.
  match.kx(0:nobs-2,*,*)=obj_template.kx(*,*,*)
  match.kx(nobs-1,*,*)=kx
  match.ky(0:nobs-2,*,*)=obj_template.ky(*,*,*)
  match.ky(nobs-1,*,*)=ky
  match.jd(0:nobs-2)=obj_template.jd(*)
  match.filter(0:nobs-2)=obj_template.filter(*)
  if keyword_set(ohdr) then begin
       match.jd(nobs-1)=sxpar(ohdr,"JD")
       if (!err ne 0) then begin
	  match.jd(nobs-1)=-1.0
	  !err=0
       endif
       match.filter(nobs-1)=sxpar(ohdr,"FILTERS")
       if (!err ne 0) then begin
	  match.filter(nobs-1)='none'
	  !err=0
       endif
       match.exptime(nobs-1)=sxpar(ohdr,"EXPTIME")
       if (!err ne 0) then begin
	  match.exptime(nobs-1)=-1.0
	  !err=0
       endif
  endif  
;You can use the "reform" comand to extract these later
;Now stuff the old observations in the new structure and add the new ones
;where they match.
  match.x(0:nobs-2,0:template_obj-1)=obj_template.x(*,*)
  match.y(0:nobs-2,0:template_obj-1)=obj_template.y(*,*)
  match.x(nobs-1,m1)=xx(m2)
  match.y(nobs-1,m1)=yy(m2)
  match.m(0:nobs-2,0:template_obj-1)=obj_template.m(*,*)
  match.m(nobs-1,m1)=obj_add(m2).mag_best
  match.merr(0:nobs-2,0:template_obj-1)=obj_template.merr(*,*)
  match.merr(nobs-1,m1)=obj_add(m2).magerr_best
  match.fwhm(0:nobs-2,0:template_obj-1)=obj_template.fwhm(*,*)
  match.fwhm(nobs-1,m1)=obj_add(m2).fwhm_image
  print, ""
  print, "Stuffing misses"
  match.x(0,template_obj:nobj-1)=xx(miss2)
  match.x(2,template_obj:nobj-1)=xx(miss2)
  match.y(0,template_obj:nobj-1)=yy(miss2)  
  match.y(2,template_obj:nobj-1)=yy(miss2)
  match.m(0,template_obj:nobj-1)=obj_add(miss2).mag_best
  match.m(2,template_obj:nobj-1)=obj_add(miss2).mag_best
  match.merr(0,template_obj:nobj-1)=obj_add(miss2).magerr_best
  match.merr(2,template_obj:nobj-1)=obj_add(miss2).magerr_best
  match.fwhm(0,template_obj:nobj-1)=obj_add(miss2).fwhm_image
  match.fwhm(2,template_obj:nobj-1)=obj_add(miss2).fwhm_image

;Now assign this to the input variable name....
  newmatch=match

  return
  end









