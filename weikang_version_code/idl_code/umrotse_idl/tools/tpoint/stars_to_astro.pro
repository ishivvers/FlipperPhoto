pro stars_to_astro,inname,outname,max_sun = max_sun, times=times, interval=interval

if n_params() eq 0 then begin
    print,'syntax -  stars_to_astro,inname,outname,max_sun = max_sun, times=times, interval=interval'
    return
endif


if n_elements(max_sun) eq 0 then begin
    max_sun = -18.0
endif

if n_elements(times) eq 0 then begin
    times = 2
endif

if n_elements(interval) eq 0 then begin
    interval = 180
endif

readcol,inname,num,ra_hr,ra_min,ra_sec,dec_deg,dec_min,dec_sec,junk1,junk2,epoch, $
  format = '(L,I,I,F,I,I,F,F,F,F)'

numstars = n_elements(num)

ra_vals = tenv(ra_hr,ra_min,ra_sec)*15.0
dec_vals = tenv(dec_deg,dec_min,dec_sec)

offset_r = (25./60.)*randomu(seed,numstars)
offset_theta = (2*!pi)*randomu(seed,numstars)

new_ra = ra_vals + offset_r * cos(offset_theta)
new_dec = dec_vals + offset_r * sin(offset_theta)



openw,lun,outname,/get_lun

for i=0l,numstars-1 do begin
    line=''

    ra_bits = sixty(new_ra[i]/15.0)
    new_ra_hr = ra_bits[0]
    new_ra_min = ten(ra_bits[1],ra_bits[2])
    dec_bits = sixty(new_dec[i])
    new_dec_deg = dec_bits[0]
    new_dec_min = ten(dec_bits[1],dec_bits[2])


    ra_str=string(new_ra_hr,format='(i2)')+','+ string(new_ra_min,format='(f6.3)')
    ra_str=strcompress(ra_str,/remove_all)

    dec_str=string(new_dec_deg,format='(i3)')+','+string(new_dec_min,format='(f6.3)')
    dec_str=strcompress(dec_str,/remove_all)
    
    epoch_str = string(epoch[i],format='(f6.1)')

    the_rest_str = ' -u '+string(max_sun,format='(f5.1)')+' -t '+string(times,'(i2)')+ $
      ' -i '+string(interval,'(i3)')

    line = 'sched pointing  "-r '+ra_str+' -d '+dec_str+' -e '+epoch_str+the_rest_str+'"'

    printf,lun,line

endfor


free_lun,lun





return
end


