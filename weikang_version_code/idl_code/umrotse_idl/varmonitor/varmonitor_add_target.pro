pro varmonitor_add_target,vmfile,name,ra,dec,type

if n_params() eq 0 then begin
    print,'syntax- varmonitor_add_target,vmfile,name,ra,dec,type'
    return
endif

vm=mrdfits(vmfile,1)

newvm=replicate(vm[0],n_elements(vm)+1)
newvm[0:n_elements(vm)-1] = vm[0:n_elements(vm)-1]

lastelt=n_elements(newvm)-1

newvm[lastelt].name = name
newvm[lastelt].rad = ra
newvm[lastelt].decd = dec
newvm[lastelt].type = type
newvm[lastelt].mag_range = ''
newvm[lastelt].othername = ''

rabits=sixty(ra/15.)
decbits=sixty(abs(dec))

rastr=string(fix(rabits[0]),format='(i2.2)') + ':' + $
  string(fix(rabits[1]),format='(i2.2)') + ':' + $
  string(fix(rabits[2]),format='(i2.2)') + '.' + $
  string(fix((rabits[2] - fix(rabits[2]))*100),format='(i2.2)')

if (dec lt 0) then sign = '-' else sign = '+'
decstr = sign + string(fix(decbits[0]),format='(i2.2)') + ':' + $
  string(fix(decbits[1]),format='(i2.2)') + ':' + $
  string(fix(decbits[2]),format='(i2.2)') + '.' + $
  string(fix((decbits[2] - fix(decbits[2]))*100),format='(i2.2)')

newvm[lastelt].ra = rastr
newvm[lastelt].dec = decstr

newvm[lastelt].filename = type + '-' + $
  string(fix(rabits[0]),format='(i2.2)') + $
  string(fix(rabits[1]),format='(i2.2)') + $
  sign + string(fix(decbits[0]),format='(i2.2)') + $
  string(fix(decbits[1]),format='(i2.2)')

;; and write it out

mwrfits,newvm,vmfile,/create
  




return
end
