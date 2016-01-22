function fakevar, nobj, nobs, seed, type, sensitivity, ntiles=ntiles
;+
; NAME: FAKEVAR
;
; PURPOSE:
;	Generate a set of fake variable lightcurves.
;
; CALLING SEQUENCE:
;       match = fakevar(nobj,nobs,seed,type,ntiles=ntiles,sensitivity=sensitivity)
;
; INPUTS:
;	nobj:		# of objects
;	nobs:  		# of observations
;	seed:		starting seed for random number generation
;	type:		kind of transients to generate:
;				'BURST' = peak + power-law decay
;				'FLARE' = baseline + peak + power-law decay
;				'PULSATE' = regular sinusoidal variation
;				'ECLIPSE' = regular variation with narrow max or min
;	sensitivity:	limiting magnitude to use (default is 15.5)
;
; Keywords:
;	ntiles:		number of fields observed
;
; RETURN VALUE: 
;	match:  structure containing lightcurves of various objects
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	9/19/00
;	Bob Kehoe	UM	10/03/00  -- added sensitivity keyword
;	Bob Kehoe	UM	11/29/00  -- improve way deal with orphans data
;-
 On_error,2              ;Return to caller

 if N_params() lt 5 then begin
    print, 'Syntax:  match = fakevar(nobj,nobs,seed,type,sensitivity,ntiles=ntiles)'
    return, -1
 endif

; Initialization

 if not keyword_set(seed) then seed = 999.0
 stat = make_stat_struct(nobs)

; Set-up epoch sequence

 print, 'Creating exposure sequence for ', nobj, ' variables...'
 setup_epochs, stat, sensitivity, ntiles=ntiles
 match = make_match_struct(nobs, nobj)
 match.exptime = stat.efftime
 match.jd = stat.mjd

; Determine source coordinates and vignetting

 print, 'Generating coordinates and vignetting...'
 ra = match.ra
 dec = match.dec
 gen_coords, stat, seed, ra, dec, x, y
 match.rac = stat.rac
 match.decc = stat.decc
 match.ra = ra
 match.dec = dec
 mlim = match.m
 for k = 0,nobs-1 do mlim[k,*] = stat[k].m_lim + calc_vignetting(x,y)

; Generate variable parameters and lightcurves

 if (type eq 'BURST') then begin
    pars = fakebursts(nobj,seed)
 endif else if (type eq 'FLARE') then begin
    pars = fakeflare(nobj,seed)
 endif else if (type eq 'PULSATE') then begin 
    pars = fakeregvar(nobj,seed)
 endif else if (type eq 'ECLIPSE') then begin
    pars = fakeregvar(nobj,seed)
 endif
 print, 'Filling data structures with lightcurves...'
 fill_lightcurve, pars, mlim, type, seed, match
 match = create_struct(match, 'stat', stat, 'pars', pars)

 return, match
end


