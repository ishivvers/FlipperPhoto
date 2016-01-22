pro write_lightcurve,jd,mag,mag_err,filename=filename,nomean=nomean



if N_params() eq 0 then begin
   print,'Syntax: write_lightcurve,jd,mag,mag_err,filename=filename'
   return
endif


if not keyword_set(filename) then begin
  fname = 'templc.dat'
endif else begin
  fname = filename
endelse

numobs=n_elements(jd)
avg_mag = mean(mag)
offset_jd = jd - jd(0)

if keyword_set(nomean) then begin
    delta_mag = mag
endif else begin
    delta_mag = mag - avg_mag
endelse

openw,lun,fname,/get_lun
printf,lun,"time  delta-mag   delta-mag-err"
printf,lun,""
printf,lun,""


for i=0,numobs-1 do begin
  printf,lun,offset_jd(i),delta_mag(i),mag_err(i)
endfor

free_lun,lun

return

end



