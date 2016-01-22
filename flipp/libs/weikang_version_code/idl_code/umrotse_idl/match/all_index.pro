pro all_index, match, index
;+
; NAME:	all_index
;
; CALLING SEQUENCE:	all_index, match, index
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;
; OUTPUTS:	index: index of objects found in all colors
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Checks to see how many observations there are in the structure
;		then produces an index of object found in all observations
;
; REVISION HISTORY:  
;	Tim McKay		UM		4/29/98	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - all_index, match, index'
        return
 endif

 info=size(match.x)
 nobs=info(1)-1
 print,nobs
 nobj=info(2)
 print,nobj
 index=lindgen(nobj)
 index(*)=0

 for i=1,nobs,1 do begin
	in=where(match.x(i,*) ne -1)
	index(in)=index(in)+1
	help,i,in
 end

 return
 end
