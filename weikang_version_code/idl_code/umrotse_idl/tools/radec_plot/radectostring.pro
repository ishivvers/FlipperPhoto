function radectostring,radec,sign=sign

if n_params() eq 0 then begin
    print,'syntax- radectostring,radec,sign=sign  (if /sign is set, sign is added)'
    return,''
endif

vals = sixty(abs(radec))

if keyword_set(sign) then begin
    if (radec lt 0) then retval = '-' else retval = '+'
  ;  radec = abs(radec)
endif else retval = ''

secs = fix(vals[2])
fracsecs = round((vals[2] - secs)*10.)
if (fracsecs eq 10) then begin
    secs = secs + 1
    fracsecs = 0
    if (secs eq 60) then begin
        vals[1] = vals[1] + 1.
        secs = 0
        if (vals[1] eq 60.0) then begin
            vals[0] = vals[0] + 1
        endif
    endif
endif

retval = retval + string(fix(vals[0]),format='(i2.2)') + ':' + $
  string(fix(vals[1]),format='(i2.2)')+':' + $
  string(secs,format='(i2.2)') + '.' + string(fracsecs,format='(i1.1)')

return,retval

end
