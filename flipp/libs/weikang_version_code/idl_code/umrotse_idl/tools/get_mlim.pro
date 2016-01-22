pro get_mlim,imagenames,m_lim

; Created 00-04-07 Bob Kehoe

if N_params() lt 2 then begin
   print, 'Syntax: get_mlim,imagenames,m_lim'
   return
endif

tmp = size(imagenames)
totobs = tmp[1]
m_lim = fltarr(totobs)
for k = 0,totobs-1 do begin
   tmp = str_sep(imagenames[k], '.')
   nmstr = str_sep(tmp[0], '_')
   calname = nmstr[0] + '_' + nmstr[1] + '_' + nmstr[2] + '_cobj.fit'
   cal = mrdfits(calname, 2, hdr)
   m_lim[k] = cal.m_lim
endfor

end
