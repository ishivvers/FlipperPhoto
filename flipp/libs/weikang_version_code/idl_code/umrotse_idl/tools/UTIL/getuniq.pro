PRO getuniq, array, outarr, indices=indices, nonew=nonew

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    GETUNIQ
;       
; PURPOSE: 
;    get the unique elements from an array.
;	
;
; CALLING SEQUENCE: 
;    getuniq, array, outarr, indices=indices, nonew=nonew
;      
;                 
;
; INPUTS: 
;    array of any type
;
; KEYWORD PARAMETERS:
;         /nonew: if set, don't make a new array.  Saves space.
;
; OPTIONAL OUTPUTS:
;         outarr: array containing unique elements
;         indices: array containing indices of unique elements
;
;
; REVISION HISTORY:
;	Author: Erin Scott Sheldon UofM 6/15/99
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  IF N_params() EQ 0 THEN BEGIN 
     print,'-Syntax: getuniq, array [, outarr, indices=indices, nonew=nonew'
     print,''
     print,'Use doc_library,"getuniq"  for more help.'  
     return
  ENDIF 

  IF NOT keyword_set(nonew) THEN nonew=0

  indices=[-1]
  FOR i=0, n_elements(array)-1 DO BEGIN
    
    w=where(array EQ array[i],nw)
    IF nw EQ 1 AND w[0] EQ i THEN BEGIN
      IF indices[0] EQ -1 THEN indices = i ELSE indices = [indices,i]
    ENDIF 
  ENDFOR

  IF NOT nonew THEN outarr = array[indices]
return
END
