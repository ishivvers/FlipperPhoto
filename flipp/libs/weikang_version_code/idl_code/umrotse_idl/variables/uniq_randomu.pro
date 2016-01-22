pro uniq_randomu,num,min,max,ind
;+
; NAME: UNIQ_RANDOMU
;
; PURPOSE: To create an array of unique random integers between some
;     min and max value. 
;
; CALLING SEQUENCE: uniq_randomu,num,min,max,ind
;
; INPUTS: num - the number of integers to create.
;         min - the minimum value an integer can have.
;         max - the maximum value an integer can have. 
;
; OPTIONAL INPUTS:
;
; OUTPUTS: ind - array of 'num' unique integers
;
; OPTIONAL OUTPUTS:
;
; NOTES: Based on IDL randomu routine.
;
; EXAMPLE: To randomly sample 100 elements of a 5000 element array, do:
;   IDL> uniq_randomu,100,0,5000,ind
;   IDL> random_sample=array(ind)
;
; PROCEDURES CALLED: UNIQ, REMOVE
;       
; REVISION HISTORY:
;       Susan Amrose     UM     3/23/99
;-
 On_error,2                                      ;Return to caller

if n_params() eq 0 then begin
	print,'syntax-uniq_randomu,num,min,max,ind'
	return
endif
if max-min lt num then begin
	print,'Number of indicies required must be less than MAX-MIN'
	return
endif

 num=long(num)
 ind=lonarr(num)
 array=lindgen(max-min)+min
 n=long(0)
 u=long(0)
 while n lt num do begin
   try=long(randomu(seed,num-n)*n_elements(array)-1)
   try=try(sort(try))
   u=uniq(try)
   ind(n:n+n_elements(u)-1)=array(try(u))
   if n_elements(u) ne n_elements(array) then remove,try(u),array
   n=n+n_elements(u)
 endwhile
  
return
end