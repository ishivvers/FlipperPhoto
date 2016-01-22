
pro twomatch_s2_ctio, obj1, obj2, match, keep=keep, skip=skip, iter=iter, $
	kx=kx, ky=ky
;+
; NAME:	TWOMATCH
;
; CALLING SEQUENCE:	twomatch_s2_ctio, obj1, obj2, match
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
;******************************************************************************

 if N_params() eq 0 then begin
        print,"Syntax - twomatch_s2_ctio, obj1, obj2, match, keep=keep, skip=skip, iter=iter, kx=kx, ky=ky"
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


;First match the images to one another
  print, ""
  print, "Triangle matching the coordinates"
  triangle_match,obj1(skip:skip+keep).x_image,obj1(skip:skip+keep).y_image,$
	obj2(skip:skip+keep).x_image,obj2(skip:skip+keep).y_image,$
	0.005,1,trans21,m1,m2,t1,s1,t2,s2,votearr,kx,ky

;Assuming this works, now transform image 2 to image 1 coordinates
  print,""
  print,"Transforming list two to list one coordinates"
  transform,obj2.x_image,obj2.y_image,xx,yy,kx,ky

;Now close match the two
  print, ""
  print, "Close matching the two lists"
  close_match,obj1.x_image,obj1.y_image,xx,yy,m1,m2,1.0,2,miss1
  rpos_errors,obj1.x_image,obj1.y_image,obj2.x_image,obj2.y_image,m1,m2,kx,ky

;Now iterate "iter" times on the solution
  for i=1,iter do begin 
	print, "Looping over solution:",i,"   of:",iter
	find_trans,obj1(m1).x_image,obj1(m1).y_image,$
		obj2(m2).x_image,obj2(m2).y_image,kx,ky
	transform,obj2.x_image,obj2.y_image,xx,yy,kx,ky
	if (i lt iter) then begin
	  print, "Close matching to 1 pixel"
	  close_match,obj1.x_image,obj1.y_image,$
		xx,yy,m1,m2,1.0,1,miss1
	endif else begin
	  print, "Final close match to 2.5 pixels"
	  close_match,obj1.x_image,obj1.y_image,$
		xx,yy,m1,m2,2.5,1,miss1
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

  match=create_struct("trans",findgen(3,2,2,2),$
	"x",findgen(3,nobj),"y",findgen(3,nobj),$
	"m",findgen(3,nobj),$
	"merr",findgen(3,nobj),$
	"theta",findgen(3,nobj),$
	"ellip",findgen(3,nobj),$
	"fwhm",findgen(3,nobj))
; Give default values to all new entries
  match.trans(*,*,*,*)=-1.0
  match.x(*,*)=-1.0
  match.y(*,*)=-1.0
  match.m(*,*)=-1.0
  match.merr(*,*)=-1.0
  match.theta(*,*)=-1.0
  match.ellip(*,*)=-1.0
  match.fwhm(*,*)=-1.0
;First stuff in the trans structures for each observation. These transform
;each observation to the coordinates of the first (FOR NOW, should be RA DEC).
  match.trans(2,0,*,*)=kx
  match.trans(2,1,*,*)=ky
; Now stuff the real stuff
  match.x(0,0:nmatches-1)=obj1(m1).x_image
  match.y(0,0:nmatches-1)=obj1(m1).y_image
  match.x(1,0:nmatches-1)=obj1(m1).x_image
  match.y(1,0:nmatches-1)=obj1(m1).y_image
  match.x(2,0:nmatches-1)=xx(m2)
  match.y(2,0:nmatches-1)=yy(m2)
  match.m(0,0:nmatches-1)=obj1(m1).mag_best
  match.m(1,0:nmatches-1)=obj1(m1).mag_best
  match.m(2,0:nmatches-1)=obj2(m2).mag_best
  match.merr(0,0:nmatches-1)=obj1(m1).magerr_best
  match.merr(1,0:nmatches-1)=obj1(m1).magerr_best
  match.merr(2,0:nmatches-1)=obj2(m2).magerr_best
  match.theta(0,0:nmatches-1)=obj1(m1).theta_image
  match.theta(1,0:nmatches-1)=obj1(m1).theta_image
  match.theta(2,0:nmatches-1)=obj2(m2).theta_image
  match.ellip(0,0:nmatches-1)=obj1(m1).ellipticity
  match.ellip(1,0:nmatches-1)=obj1(m1).ellipticity
  match.ellip(2,0:nmatches-1)=obj2(m2).ellipticity
  match.fwhm(0,0:nmatches-1)=obj1(m1).fwhm_image
  match.fwhm(1,0:nmatches-1)=obj1(m1).fwhm_image
  match.fwhm(2,0:nmatches-1)=obj2(m2).fwhm_image
  print, ""
  print, "Stuffing misses from image 1"
  match.x(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).x_image
  match.x(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).x_image
  match.y(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).y_image
  match.y(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).y_image
  match.m(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).mag_best
  match.m(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).mag_best
  match.merr(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).magerr_best
  match.merr(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).magerr_best
  match.theta(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).theta_image
  match.theta(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).theta_image
  match.ellip(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).ellipticity
  match.ellip(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).ellipticity
  match.fwhm(0,nmatches:nmatches+nmisses1-1)=obj1(miss1).fwhm_image
  match.fwhm(1,nmatches:nmatches+nmisses1-1)=obj1(miss1).fwhm_image
  print, ""
  print, "Stuffing misses from image 2"
  match.x(0,nmatches+nmisses1:nobj-1)=xx(miss2)
  match.x(2,nmatches+nmisses1:nobj-1)=xx(miss2)
  match.y(0,nmatches+nmisses1:nobj-1)=yy(miss2)  
  match.y(2,nmatches+nmisses1:nobj-1)=yy(miss2)
  match.m(0,nmatches+nmisses1:nobj-1)=obj2(miss2).mag_best
  match.m(2,nmatches+nmisses1:nobj-1)=obj2(miss2).mag_best
  match.merr(0,nmatches+nmisses1:nobj-1)=obj2(miss2).magerr_best
  match.merr(2,nmatches+nmisses1:nobj-1)=obj2(miss2).magerr_best
  match.theta(0,nmatches+nmisses1:nobj-1)=obj2(miss2).theta_image
  match.theta(2,nmatches+nmisses1:nobj-1)=obj2(miss2).theta_image
  match.ellip(0,nmatches+nmisses1:nobj-1)=obj2(miss2).ellipticity
  match.ellip(2,nmatches+nmisses1:nobj-1)=obj2(miss2).ellipticity
  match.fwhm(0,nmatches+nmisses1:nobj-1)=obj2(miss2).fwhm_image
  match.fwhm(2,nmatches+nmisses1:nobj-1)=obj2(miss2).fwhm_image

;Now we're done

  return
  end









