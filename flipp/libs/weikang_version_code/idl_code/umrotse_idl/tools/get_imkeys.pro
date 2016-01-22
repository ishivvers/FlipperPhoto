pro get_imkeys,imagenames,imkeys

; Purpose: parse image names to obtain list of epoch-specific keys
;
; Created 00-04-07 Bob Kehoe

if N_params() lt 2 then begin
   print, 'Syntax: get_imkeys,imagenames,imkeys'
   return
endif

tmp = size(imagenames)
totobs = tmp[1]
imkeys = strarr(totobs)
for k = 0,totobs-1 do begin
   tmp = str_sep(imagenames[k], '.')
   nmstr = str_sep(tmp[0], '_')
   imkeys[k] = strmid(nmstr[1], 0, 3) + strmid(nmstr[2], 2)
endfor

end