function fakeflare, nobj, seed
;+
; NAME: FAKEFLARE
;
; PURPOSE:
;	Generate a set of fake flare star lightcurves with power-law fading.
;
; CALLING SEQUENCE:
;       pars = fakeflare(nobj, seed)
;
; INPUTS:
;	nobj:  		# of objects to generate
;	seed:		starting seed for random number generation
;
; RETURN VALUE: 
;	pars:  		structure containing amplitudes, power-law indices, and baselines
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	11/30/00
;-
 On_error,2              ;Return to caller

 if N_params() lt 2 then begin
    print, 'Syntax:  pars = fakeflare(nobj, seed)'
    return, -1
 endif

 user_settings, indices=index, baseline=base, ampl1=delta
 pars = make_lcpar_struct(nobj)
 pars.index = index[0] + (index[1]-index[0])*randomu(seed,nobj)
 pars.baseline = base[0] + (base[1]-base[0])*randomu(seed,nobj)
 pars.ampl1 = delta[0] + (delta[1]-delta[0])*randomu(seed,nobj)

 return, pars
end


