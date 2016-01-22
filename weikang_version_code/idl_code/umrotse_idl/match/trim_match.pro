pro trim_match,match,index,newmatch
;+
; NAME:	TRIM_MATCH
;
; CALLING SEQUENCE:	trim_match,match,index,newmatch
;
; INPUTS:	match: the input match structure
;		index: the indices of those you want to keep
;
; OUTPUTS:	newmatch: a new match structure reduced to what you want
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Makes a copy of match with few objects, stuffs it 
;			appropriately
;
; REVISION HISTORY:  
;		Tim McKay UM 6/26/98	Created
;-

 if N_params() eq 0 then begin
        print,'Syntax - trim_match,match,index,newmatch'
        return
 endif

 info=size(index)
 if (info(0) ne 1) then begin
	print,'No objects selected!'
	return
 endif
 nobj=info(1)

 info=size(match.jd)
 nobs=info(1)

 print,'Will make an output structure with:'
 print,'         '+string(nobs)+' observations'
 print,'         '+string(nobj)+' objects'

;Now create the space for what you want
 newmatch=create_struct("kx",findgen(nobs,4,4),"ky",findgen(nobs,4,4),"jd",$
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
  
;Now stuff it
 newmatch.kx=match.kx
 newmatch.ky=match.ky
 newmatch.jd=match.jd
 newmatch.filter=match.filter
 newmatch.imagename=match.imagename
 newmatch.rac=match.rac
 newmatch.decc=match.decc
 newmatch.x=match.x(*,index)
 newmatch.y=match.y(*,index)
 newmatch.m=match.m(*,index)
 newmatch.merr=match.merr(*,index)
 newmatch.fwhm=match.fwhm(*,index)
 newmatch.ra=match.ra(index)
 newmatch.dec=match.dec(index)
 newmatch.rmag=match.rmag(index)
 newmatch.bmag=match.bmag(index)

 return
 end

