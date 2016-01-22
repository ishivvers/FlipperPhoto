pro makefringe,twiflatn,skyflatn,fringe=fringe,fname=fname

if n_params() lt 2 then begin
    print,'syntax- makefringe,twiflatn,skyflatn,fringe=fringe,fname=fname'
    return
endif


;; now calculate the name so we can save it...
twiparts = str_sep(twiflatn,'_')
twidatestr = twiparts[0]
twicam = strmid(twiparts[2],0,2)
skyparts = str_sep(skyflatn,'_')
skydatestr = skyparts[0]
skycam = strmid(skyparts[2],0,2)

if (twicam ne skycam) then begin
    print,'Cameras do not match!'
    return
endif

if (long(twidatestr) gt long(skydatestr)) then datestr = twidatestr $
  else datestr = skydatestr

if n_elements(fname) eq 0 then begin
    fname = datestr + '_fringe_' + skycam + '.fit'
endif

print,'Calculating fringe file: '+fname

twi = readfits(twiflatn,thdr)
sky = readfits(skyflatn,shdr)


;;fringe = twi - sky
fringe = sky - twi
med = median(fringe)
fringe = fringe - med

writefits,fname,fringe,shdr

return
end
