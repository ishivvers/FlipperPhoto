function fakeregvar, nobj, seed
;+
; NAME: FAKEREGVAR
;
; PURPOSE:
;	Generate a set of fake regular variable lightcurves.
;
; CALLING SEQUENCE:
;       pars = fakeregvar(nobj, seed)
;
; INPUTS:
;	nobj:  		# of objects to generate
;	seed:		starting seed for random number generation
;
; RETURN VALUE: 
;	pars:  		structure containing periods and amplitudes
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	11/30/00
;-
 On_error,2              ;Return to caller

 if N_params() lt 2 then begin
    print, 'Syntax:  pars = fakeregvar(nobj, seed)'
    return, -1
 endif

 user_settings, baseline=base, per1=period, ampl1=delta
 pars = make_lcpar_struct(nobj)
 pars.baseline = base[0] + (base[1]-base[0])*randomu(seed,nobj)
 pars.per1 = period[0] + (period[1]-period[0])*randomu(seed,nobj)
 pars.ampl1 = delta[0] + (delta[1]-delta[0])*randomu(seed,nobj)

 return, pars
end


