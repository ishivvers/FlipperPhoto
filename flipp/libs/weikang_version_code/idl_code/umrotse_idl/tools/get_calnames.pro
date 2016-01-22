pro get_calnames, imagenames, calnames
;+
; NAME:	get_calnames
;
; CALLING SEQUENCE:	get_calnames, imagenames, calnames
;
; INPUTS:	imagenames: list of images to parse to get calnames
;
; OUTPUTS:	calnames: list of cal or cobj filenames
;
; Created: 00-04-14  Bob Kehoe
;******************************************************************************

if N_params() lt 2 then begin
   print, 'Syntax get_calnames, imagenames, calnames'
   return
endif

; Obtain observation summary information, perform relative photometry
; corrections.

totobs = n_elements(imagenames)
calnames = strarr(totobs)
for k = 0,totobs-1 do begin    
   tmp = str_sep(imagenames[k], '.')
   nmstr = str_sep(tmp[0], '_')
   calnames[k] = nmstr[0] + '_' + nmstr[1] + '_' + nmstr[2] + '_cobj.fit'
endfor

end





