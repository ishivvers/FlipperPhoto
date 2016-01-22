function define_flags, name

;+
; NAME: define_flags
;
; CALLING SEQUENCE:     define_flags,name
;
; INPUTS:       name: type of flags to output (ie. 'EFLAGS' or 'RFLAGS'
;
; Return Value: list of flag names
;
; Created:  5-26-00  Bob Kehoe
;******************************************************************************

if N_params() lt 1 then begin
   print, 'Syntax define_flags, name'
   return, -1
endif

if (strpos(name, 'EFLAGS') ne -1) then begin
   flags = ['NEIGHBORS', 'BLENDED', 'SATURATED', 'ATEDGE', 'APINCOMPL', $
	 'ISINCOMPL', 'DBMEMOVR', 'EXMEMOVR']
endif else if (strpos(name, 'RFLAGS') ne -1) then begin
   flags = ['HOTPIX', 'NOISYPIX', 'STRANGEPIX', 'BADPOS', 'NOTEMPL', $
	  'PHOTSDEV','BADIMAGE']
endif else begin
   print, 'Unknown name.'
   return, -1
endelse

return, flags
end