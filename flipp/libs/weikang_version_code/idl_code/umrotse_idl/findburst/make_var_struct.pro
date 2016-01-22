function make_var_struct, nobj, nobs

; Purpose:	To create structure holding summary information on variables.
;
; Inputs:
;	nobj -- number of objects
;	nobs -- number of observations
;
; Return Value:  initialized structure
;
; Created: Bob Kehoe 05-01-00
; Updated: Bob Kehoe 12-07-00 -- added duration parameter

; make observation substructure

   obs = create_struct('state', -1, 'dis', -1.0, 'posangle', -1.0, 'err', -1.0,$
		     'phot', -1.0, 'photerr', -1.0)
   all_obs = replicate(obs, nobs)

; Fill rest of parameters

   var = create_struct('name', " ", 'ptr', 0L,$
		'maxmag', -1.0, 'errmaxmag', -1.0,$
		'minmag', -1.0, 'avgmag', -1.0,$
		'delta', -1.0, 'nmiss', 0,$
		'nobs', 0, 'ngdobs', 0,$
		'sdev', -1.0, 'sdevcl', -1.0,$
		'chisq', -1.0, 'chisqcl', -1.0,$
		'maxsig', -1.0, 'pos_sdv', -1.0,$
		'posrange', -1.0, 'avgdev', -1.0,$
		'skew', -1.0, 'kurt', -1.0, 'duration', -1.0,$
		'mdnerr', -1.0, 'avgdevsig', -1.0,$ 
		'avgdevsigcl', -1.0, 'bestdelta', -1.0,$
		'bestsig', -1.0, 'ival', -1.0, $
		'ival2', -1.0, 'obs', all_obs)
   all_vars = replicate(var, nobj)

   return, all_vars
end
