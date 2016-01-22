pro rdis_setup, image, plot_struct
;+
; NAME:
;       RDIS_SETUP
; PURPOSE:
;	Set up a parameter structure for rdis
;
; CALLING SEQUENCE:
;       rdis_setup
;
; INPUTS:
;       
; OUTPUTS:
;	lot_struct: a structure containing all the parameters needed
;		      to run rdis
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
; 
; PROCEDURE: This just creates a little structure useful for image display
;
; REVISION HISTORY:
;	Tim McKay	UM	1/8/98
;	Tim McKay	UM	3/7/98  
;		Added check for environment variables 
;			EXTRACT_CONFIG, and EXTRACT_PAR
;	Tim McKay	UM 	4/27/98
;		Altered from rextract_setup 
;-
 On_error,2              ;Return to caller

 if N_params() ne 2 then begin
        print,'Syntax - rdis_setup, image, plot_struct'
        return
 endif
 r=size(image)
 plot_struct = { $
	XMN: 0, $
	XMX: r(1)-1, $
	YMN: 0, $
	YMX: r(2)-1, $
	LOW: 0, $
	HIGH: 0}

 return

 end



