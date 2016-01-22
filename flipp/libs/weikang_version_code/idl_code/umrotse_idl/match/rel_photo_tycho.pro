pro rel_photo_tycho, match, newmatch, grid=grid
;+
; NAME:	rel_photo_tycho
;
; CALLING SEQUENCE:	rel_photo, match, newmatch
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;
; OUTPUTS:	newmatch: copy of match calibrated to the USNO information
;			  then with relative photometry between observations
;	
; INPUT KEYWORDS:
;			
; PROCEDURE:	Does observation to observation photometry of objects
;
; REVISION HISTORY:  
;	Tim McKay		UM		4/29/98	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - rel_photo, match, newmatch, grid=grid'
        return
 endif

 info=size(match.x)
 nimages=info(1)-1
 print,nimages

 newmatch=match

 ;in=where(match.m(1,*) ne -1 and match.rmag ne -1)
 ;info=size(in)
 ;nobs=info(1)-1
 ;nb=long(nobs*0.1)
 ;nl=long(nobs*0.2)
 ;magdiff=median(match.rmag(in(nb:nl))-$
	;match.m(1,in(nb:nl)))
 ;mnew=match.m(1,*)+magdiff
 ;var=moment(match.rmag(in(nb:nl))-mnew(in(nb:nl)))
 ;print,median(match.rmag(in(nb:nl))-$
;	mnew(in(nb:nl)))
; sigma=sqrt(var(1))
; print,"photometry",magdiff,sigma
; f=where(match.m(1,*) ne -1)
; newmatch.m(1,f)=mnew(f)
; f=where(match.m(0,*) ne -1)
; newmatch.m(0,f)=mnew(f)

 if not keyword_set(grid) then begin
	grid = 10
 endif


 for i=1,nimages,1 do begin
	print,'Mapping photometry for image:',i
	relphoto_map,newmatch,1,i,nmags,nbox=grid,frac=0.2
	j=where(nmags(1,*) gt -1 and nmags(1,*) lt 30)
	newmatch.m(i,j)=nmags(1,j)
;	in=where(newmatch.m(1,*) ne -1 and match.m(i,*) ne -1)
; 	info=size(in)
; 	nobs=info(1)-1
; 	nb=long(nobs*0.1)
; 	nl=long(nobs*0.2)
; 	magdiff=median(newmatch.m(1,in(nb:nl))-$
;		match.m(i,in(nb:nl)))
; 	mnew=match.m(i,*)+magdiff
; 	var=moment(newmatch.m(1,in(nb:nl))-mnew(in(nb:nl)))
; 	print,median(newmatch.m(1,in(nb:nl))-$
;		mnew(in(nb:nl)))
; 	sigma=sqrt(var(1))
; 	print,"photometry",i,magdiff,sigma
;	f=where(match.m(i,*) ne -1)
;	newmatch.m(i,f)=mnew(f)
 end

 return
 end

