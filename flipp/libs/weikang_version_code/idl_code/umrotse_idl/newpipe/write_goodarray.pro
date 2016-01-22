pro write_goodarray,good,filename
;+
; NAME:	WRITE_GOODARRAY
;
; CALLING SEQUENCE: 
;
; INPUTS:	good: array of selected indices in the subtracted struct...
;		filename to write
;
; OUTPUTS:	
;	
; INPUT KEYWORDS:
;			
; PROCEDURE:	
;
; REVISION HISTORY:  
;	Tim McKay		UM	12/15/98
;

 if N_params() eq 0 then begin
        print,'Syntax - write_goodarray,good,filename '
	return
 endif

 get_lun,f
 openw,f,filename
 printf,f,format='(I5)',good
 close,f

 return
 end