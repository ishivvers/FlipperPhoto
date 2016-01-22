function fakebursts, nobj, seed
;+
; NAME: FAKEBURSTS
;
; PURPOSE:
;	Generate a set of fake burst lightcurves with power-law fading.
;
; CALLING SEQUENCE:
;       pars = fakebursts(nobj, seed)
;
; INPUTS:
;	nobj:  		# of objects to generate
;	seed:		starting seed for random number generation
;
; RETURN VALUE: 
;	pars:  		structure containing peak magnitudes and power-law indices
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	9/19/00
;	Bob Kehoe	UM	12/1/00 -- reworked to just generate burst parameters
;-
 On_error,2              ;Return to caller

 if N_params() lt 2 then begin
    print, 'Syntax:  pars = fakebursts(nobj, seed)'
    return, -1
 endif

 user_settings, peak=mags, indices=indices
 print, 'Generating lightcurves for peak magnitudes in range:   ', mags
 print, '  		    and for power law indices in range: ', indices
 pars = make_lcpar_struct(nobj)
 pars.index = indices[0] + (indices[1]-indices[0])*randomu(seed,nobj)
 pars.peak = mags[0] + (mags[1]-mags[0])*randomu(seed,nobj)

 return, pars
end


