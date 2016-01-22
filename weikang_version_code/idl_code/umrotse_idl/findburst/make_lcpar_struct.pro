function make_lcpar_struct, nobj
;+
; NAME: Make Lightcurve Parameters Structure
;
; PURPOSE:
;	create a structure to hold lightcurve parameters
;
; CALLING SEQUENCE:
;       pars = make_lcpars_struct(nobj)
;
; INPUTS:
;	nobj:  		# of objects to generate
;
; RETURN VALUE: 
;	pars:  		initialized structure
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	11/30/00
;-
 On_error,2              ;Return to caller

 if N_params() lt 1 then begin
    print, 'Syntax:  pars = make_lcpars_struct(nobj)'
    return, -1
 endif

 v = create_struct('index', 0.0, 'peak', 0.0, 'baseline', 0.0, 'per1', 0.0, 'ampl1', 0.0)
 pars = replicate(v, nobj)

 return, pars
end


