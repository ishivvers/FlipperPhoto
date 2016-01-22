pro all_obj, match, obs_array
;+
; NAME:	all_obj
;
; CALLING SEQUENCE:	all_obj, match, obs_array
;
; INPUTS:	match: match structure produced by tycho_regmatch
;
; OUTPUTS:	obs_array: number of objects per observation
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Checks to see how many observations there are in the structure
;		then produces an array of how many objects are in each obs...
;
; REVISION HISTORY:  
;	Tim McKay		UM		11/19/98	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - all_obj, match, obs_array'
        return
 endif

 info=size(match.m)
 nobs=info(1)-1
 print,nobs
 nobj=info(2)
 print,nobj
 obs_array=lindgen(nobs)
 obs_array(*)=0

 for i=0,nobs-1,1 do begin
	in=where(match.m(i,*) ne -1)
	obs_array(i)=(size(in))(1)
	help,i,in
 end

 return
 end
