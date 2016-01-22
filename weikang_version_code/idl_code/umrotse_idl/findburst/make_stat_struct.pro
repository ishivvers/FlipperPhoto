function make_stat_struct, nobs
;+
; NAME: Make Stats Structure
;
; PURPOSE:
;	Create a dummy structure for observation statistics
;
; CALLING SEQUENCE:
;       stat = make_stat_struct(nobs)
;
; INPUTS:
;	nobs:  		# of observations
;
; RETURN VALUE: 
;	stat:  structure containing initialized values of observation statistics
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	11/30/00
;-
 On_error,2              ;Return to caller

 if N_params() lt 1 then begin
    print, 'Syntax:  stat = make_stat_struct(nobs)'
    return, -1
 endif

 st = create_struct('NAXIS1', 0, 'NAXIS2', 0, 'OBSTIME', 0.0D, 'MJD', 0.0D, $
	'NCOADD', 0, 'EXPTIME', 0.0, 'EFFTIME', 0.0, 'FOV', 0.0, 'M_LIM', 0.0, $
	'RAC', 0.0, 'DECC', 0.0)
 stat = replicate(st, nobs)

 return, stat
end


