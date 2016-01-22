pro make_sflag_struct, flag_struct
;+
; NAME:
;       MAKE_SFLAG_STRUCT
; PURPOSE:
;	Set up a parameter structure for sdss flag selection
;
; CALLING SEQUENCE:
;      make_sflag_struct, flag_struct 
;
; INPUTS:
;       
; OUTPUTS:
;	flag_struct: the structure used for rotse object selection....
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
; 
; PROCEDURE: This sets up the structure for flag selection of rotse objects
;	
;
; REVISION HISTORY:
;	Tim McKay	UM	3/1/99
;-

 if N_params() ne 1 then begin
        print,'Syntax - make_sflag_struct, flag_struct'
        return
 endif

 flag_struct = { $
	NEIGHBORS: 'D', $
	BLEND: 'D', $
	SATURATED: 'D', $
	TRUNCATED: 'D', $
 	BAD_AP: 'D', $
	BAD_ISO: 'D', $
	DEBLEND_OVERFLOW: 'D', $
	EXTRACT_OVERFLOW: 'D'}

  return 
  end



