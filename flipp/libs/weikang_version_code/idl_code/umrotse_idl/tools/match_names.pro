function match_names, stnames, matchnames
;+
; NAME: match_names
;
; CALLING SEQUENCE:     match_names, stnames, matchnames
;
; INPUTS:       stnames: list of file names from stats struct.
;
; OUTPUTS:      matchnames: list of file names from match struct
;
; Return Value: indices of identified names
;
; Created:  5-30-00  Bob Kehoe
;******************************************************************************
;-

if N_params() eq 0 then begin
   print, 'Syntax result = match_names(stnames,matchnames)'
   return,-1
endif

   nobs = (size(stnames))[1]
   if ((size(stnames))[0] eq 0) then nobs = 1
   new_stnames = strarr(nobs)
   for k = 0,nobs-1 do begin
      if (strpos(stnames[k], '_c.fit') eq -1) then begin
         result = str_sep(stnames[k],'.')
         new_stnames[k] = result[0]
      endif else begin
         result = str_sep(stnames[k],'_c.fit')
         new_stnames[k] = result[0]
      endelse
   endfor
   mobs = (size(matchnames))[1]
   if ((size(matchnames))[0] eq 0) then mobs = 1
   new_matchnames = strarr(mobs)
   for k = 0,mobs-1 do begin
      if (strpos(matchnames[k], '_c.fit') eq -1) then begin
         result = str_sep(matchnames[k],'.')
         new_matchnames[k] = result[0]
      endif else begin
         result = str_sep(matchnames[k],'_c.fit')
         new_matchnames[k] = result[0]
      endelse
   endfor
   index = make_array(mobs, /INT, value=-1)
   l = 0
   for k = 0,nobs-1 do begin
      tmp = where(strpos(new_matchnames,new_stnames[k]) ne -1, count)
      if (count ne 0) then begin
         index[l] = tmp
         l = l + 1
      endif
   endfor
   m = where(index gt -1, count)
   if (count ne 0) then begin
      val = index[m]
   endif else val = -1

   return, val
end
