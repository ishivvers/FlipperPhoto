FUNCTION ntostr, num, pos2, pos1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    ntostr
;       
; PURPOSE: 
;    convert a number to a string.  Cuts off white spaces.
;	
;
; CALLING SEQUENCE: 
;    result = ntostr(num, pos2, pos1)
;
; INPUTS: 
;    num:  the number to be converted
;
; OPTIONAL INPUTS:
;   pos2: The number of characters to keep beginning with pos1. Default
;         is to return the whole string.
;   pos1: starting position.  Default is 0, the first position.
;       
; OUTPUTS: 
;   The string.
;
; CALLED ROUTINES:
;                   STRTRIM
;                   STRMID
;
; REVISION HISTORY:
;	Author: Erin Scott Sheldon  UofM 6/1/99
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  IF N_params() EQ 0 THEN BEGIN 
     print,'-Syntax: string = ntostr( num [, pos2, pos1] )'
     print,''
     print,'Use doc_library,"ntostr"  for more help.'  
     return,''
  ENDIF 

IF n_elements(pos1) EQ 0 THEN pos1 = 0

IF n_elements(pos2) EQ 0 THEN BEGIN 
  pos2=1000
  return, strmid( strtrim(string(num), 2), pos1,pos2)
ENDIF ELSE return, strmid(strtrim(string(num), 2), pos1, pos2)

END
