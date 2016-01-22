FUNCTION mfact, array

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME: 
;    mfact
;
; PURPOSE: 
;    find the factorial of each element in an array.
;
; CALLING SEQUENCE:
;    result = mfact(array)
;
; INPUTS: 
;    array (of numbers)
;
; OUTPUTS: 
;    farray: the array of factorials.
;
; REVISION HISTORY:
;   Author: Erin Scott Sheldon UofM  5/??/98
;
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF n_params() EQ 0 THEN BEGIN
    print,'Syntax: farray = mfact(array)'
    print,''
    print,'Use doc_library,"mfact" for more help'
    return,0.
  ENDIF 

  n=n_elements(array)
  farray = dblarr(n)

  for i=0, n-1 do begin
      
      farray[i] = factorial( array[i] )

  endfor

  return, farray
end
