pro find_exp, match, index, nim=nim
;+
; NAME:
;       FIND_EXP
; PURPOSE:
;	Find things which appear in a sequential set of images, and 
;	never again
;
; CALLING SEQUENCE:
;       find_exp, match, index, nim=nim
;
; INPUTS:
;	match: a match structure
;       
; OUTPUTS:
;	index: the indices of the things you want
;
; OPTIONAL INPUTS:
;	nim: Number of images you want it to be in (default is 6)
;
; OPTIONAL OUTPUT ARRAYS:
; 
; PROCEDURE:
;
; REVISION HISTORY:
;	Tim McKay	UM 	3/1/99
;		Created 
;-

 On_error,2              ;Return to caller

 if N_params() lt 1 then begin
        print,'Syntax - find_exp, match, index, nim=nim'
        return
 endif

 if not keyword_set(nim) then begin
	nim = 6
 endif

 nobs = n_elements(match.jd)
 print,nobs
 ngood_array,match,indgen(nobs),hits
 help,hits
 obj=where(hits eq nim)

 nobj=n_elements(obj)
 index=indgen(1)

 print,'Number of candidate objects: ',nobj
 for i=0,nobj-1,1 do begin
	h=where(match.m(*,obj(i)) ne -1)
	good = 'Y'
	for k=1,nim-1,1 do begin
	   if (h(k) ne h(0)+k) then begin
		good = 'N'
	   endif
	end
	if (good eq 'Y') then begin
		index = [index,obj(i)]
	endif
  end

  nfound=n_elements(index)
  index=index(1:nfound-1)
  print,'Found a total of: ',nfound-1
 
  return
  end











