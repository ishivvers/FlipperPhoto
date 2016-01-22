function generate_rotse3_fname,date,tla,ra,dec,telescope,frame=frame

if n_params() eq 0 then begin
    print,'syntax- generate_rotse3_fname,date,tla,ra,dec,telescope,frame=frame'
    return,''
endif

if n_elements(frame) eq 0 then frame = 1

tp = size(date,/type)

if (tp eq 7) then begin
    fname = date
endif else begin
    fname = string(long(date),format='(i6.6)')
endelse

fname = fname + '_' + tla

ras=sixty(ra/15.0)
fname = fname + string(fix(ras[0]),format='(i2.2)') + string(fix(ras[1]),format='(i2.2)')

sign = '+'
if (dec lt 0) then sign = '-'
decs=sixty(abs(dec))
fname = fname + sign + string(fix(decs[0]),format='(i2.2)') + string(fix(decs[1]),format='(i2.2)')

fname = fname + '_3' + telescope + string(fix(frame),format='(i3.3)')


return,fname
end
