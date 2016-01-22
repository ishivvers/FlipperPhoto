FUNCTION arrscl, arr, min, max, arrmin=arrmin, arrmax=arrmax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    ARRSCL
;       
; PURPOSE:
;    Rescale the range of an array.
;
; CALLING SEQUENCE:
;    result = arrscl(arr, min, max, arrmin=arrmin, arrmax=arrmax)
;                 
; INPUTS: 
;    arr:  The array.
;    min:  new minimum.
;    max:  new maximum.
;
; OPTIONAL INPUTS:
;    arrmin:  A number to be used as minimum of array range.
;    arrmax:  A number to be used as maximum of array range.
;
;    NOTE:  These are useful if the original array is known to only be a
;           sample of possible range.  e.g. 
;
;           if arr=randomu(seed,20) then one might wish to give arrmin=0, 
;           arrmax=1
;
; KEYWORD PARAMETERS:
;    None.
;       
; OUTPUTS:
;    The rescaled array. 
;
; PROCEDURE: 
;    See the code.
;	
;
; REVISION HISTORY:
;    Author: Erin Scott Sheldon UofMich 10/18/99  
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF n_params() NE 3 THEN BEGIN
      print,'-Syntax: arrscl, arr, min, max, arrmin=arrmin, arrmax=arrmax'
      print
      print,'Use doc_library,"arrscl"  for more help.' 
      return,0
  ENDIF 

  IF n_elements(arrmax) EQ 0 THEN arrmax = max(arr)
  IF n_elements(arrmin) EQ 0 THEN arrmin = min(arr)
  a = (max - min)/(arrmax - arrmin)
  b = (arrmax*min - arrmin*max)/(arrmax - arrmin)


  return, a*arr + b

END 
