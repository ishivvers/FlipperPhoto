pro radec_merge,match1,match2,mcombine,m1=m1,m2=m2
;+
; NAME:	RADEC_MERGE
;
; CALLING SEQUENCE:	radec_merge,match1,match2,mcombine
;
; INPUTS:	match1: first match structure
;		match2: second match structure
;		
; OUTPUTS:	mcombine: concatenated list of matched objects
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Merges two "match" structures into a single structure
;		by making a merge in ra,dec space.
;
; REVISION HISTORY:  
;	Tim McKay		UM	9/23/98	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - radec_merge,match1,match2,mcombine'
        return
 endif

;First run the match to find corresponding objects
close_match_radec,match1.ra,match1.dec,match2.ra,match2.dec,$
	m1,m2,0.015,1,miss1

;Display the results....
plot,(match1.ra(m1)-match2.ra(m2))*250.0,$
	(match1.dec(m1)-match2.dec(m2))*250.0,psym=3

;Stuff the results into combined structure. This includes everything
;from the template as well as eveything in the new image NOT in the template.
;Cuts on what objects are acceptable should be made BEFORE inputting lists
;into this matcher.
    print, ""
    print, "Stuffing matches"
    template_obj=N_elements(match1.x(0,*))
    n2=N_elements(match2.x(0,*))
    miss2=lindgen(n2) 
    remove,m2,miss2
    nmisses=N_elements(miss2)
    nobj=template_obj+nmisses
    nobs1=N_elements(match1.x(*,0))
    nobs2=N_elements(match2.x(*,0))
    nobs=nobs1+nobs2-1
    print, "Number of observations=",nobs,"      Number of objects=",nobj

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
    match.kx(0:nobs1-1,*,*,*)=match1.kx(*,*,*)
    match.ky(0:nobs1-1,*,*,*)=match1.ky(*,*,*)
    match.kx(nobs1:nobs-1,*,*)=match2.kx(1:nobs2-1,*,*)
    match.ky(nobs1:nobs-1,*,*)=match2.ky(1:nobs2-1,*,*)
;Now try to stuff the frame specific information. 
;To do this you must be passed the headers
;from the list or image which has this information
    match.jd(0:nobs1-1)=match1.jd(*)
    match.jd(nobs1:nobs-1)=match2.jd(1:nobs2-1)
    match.filter(0:nobs1-1)=match1.filter(*)
    match.filter(nobs1:nobs-1)=match2.filter(1:nobs2-1)
    match.imagename(0:nobs1-1)=match1.imagename(*)
    match.imagename(nobs1:nobs-1)=match2.imagename(1:nobs2-1)
    match.exptime(0:nobs1-1)=match1.exptime(*)
    match.exptime(nobs1:nobs-1)=match2.exptime(1:nobs2-1)
    match.airmass(0:nobs1-1)=match1.airmass(*)
    match.airmass(nobs1:nobs-1)=match2.airmass(1:nobs2-1)
; Now stuff the information on how you matched this
    match.rac(0)=match1.rac(0)
    match.decc(0)=match1.decc(0)
; Now stuff the old stuff
    match.x(0:nobs1-1,0:template_obj-1)=match1.x(*,*)
    match.y(0:nobs1-1,0:template_obj-1)=match1.y(*,*)
    match.m(0:nobs1-1,0:template_obj-1)=match1.m(*,*)
    match.merr(0:nobs1-1,0:template_obj-1)=match1.merr(*,*) 
    match.fwhm(0:nobs1-1,0:template_obj-1)=match1.fwhm(*,*)
    match.ra(0:template_obj-1)=match1.ra
    match.dec(0:template_obj-1)=match1.dec
    match.bmag(0:template_obj-1)=match1.bmag
    match.rmag(0:template_obj-1)=match1.rmag

; Now add the matches
    match.x(nobs1:nobs-1,m1)=match2.x(1:nobs2-1,m2)
    match.y(nobs1:nobs-1,m1)=match2.y(1:nobs2-1,m2)
    match.m(nobs1:nobs-1,m1)=match2.m(1:nobs2-1,m2)
    match.merr(nobs1:nobs-1,m1)=match2.merr(1:nobs2-1,m2)
    match.fwhm(nobs1:nobs-1,m1)=match2.fwhm(1:nobs2-1,m2)

    print, ""
    print, "Stuffing misses from image"
    match.x(0,template_obj:nobj-1)=match2.x(0,miss2)
    match.x(nobs1:nobs-1,template_obj:nobj-1)=match2.x(1:nobs2-1,miss2)
    match.y(0,template_obj:nobj-1)=match2.y(0,miss2)
    match.y(nobs1:nobs-1,template_obj:nobj-1)=match2.y(1:nobs2-1,miss2)
    match.m(0,template_obj:nobj-1)=match2.m(0,miss2)
    match.m(nobs1:nobs-1,template_obj:nobj-1)=match2.m(1:nobs2-1,miss2)
    match.merr(0,template_obj:nobj-1)=match2.merr(0,miss2)
    match.merr(nobs1:nobs-1,template_obj:nobj-1)=match2.merr(1:nobs2-1,miss2)
    match.fwhm(0,template_obj:nobj-1)=match2.fwhm(0,miss2)
    match.fwhm(nobs1:nobs-1,template_obj:nobj-1)=match2.fwhm(1:nobs2-1,miss2)
    match.ra(template_obj:nobj-1)=match2.ra(miss2)
    match.dec(template_obj:nobj-1)=match2.dec(miss2)

;Now reassign the new match structure to the old name
    mcombine=match

  return
  end














