PRO add_arrval, newval, array, front=front

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    ADD_ARRVAL
;       
; PURPOSE:
;    Add an element to an array "array". If input array is undefined, 
;    set it equal to the new value.
;
; CALLING SEQUENCE:
;    add_arrval, newval, array, front=front
;
; INPUTS: 
;    newval: the new value to be added
;
; KEYWORD PARAMETERS:
;    /front: If set then put the new value at the front of the array, else
;       put at end.
;
; SIDE EFFECTS: 
;    array is created or augmented.       
;
; 
; PROCEDURE: 
;    
;	
;
; REVISION HISTORY:
;    14-NOV-2000 Erin Scott Sheldon UofMich
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  IF n_params() EQ 0 THEN BEGIN 
      print,'Syntax: add_arrval, newval, array [, front=front]'
      print,''
      print,'/front to add new element at front of array'
      print,'Use doc_library,"add_arrval"  for more help.'  
      return
  ENDIF 

  IF n_elements(newval) EQ 0 THEN BEGIN
      print,'Must enter a value to add to array'
      print,'Syntax: add_arrval, newval, array [, front=front]'
      return
  ENDIF 

  IF n_elements(array) EQ 0 THEN array = newval ELSE BEGIN
      IF NOT keyword_set(front) THEN array=[temporary(array), newval] $
      ELSE array=[newval, temporary(array)]
  ENDELSE 

  return

END
