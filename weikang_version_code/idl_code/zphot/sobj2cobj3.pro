pro sobj2cobj3,sobjfile,rac=rac,decc=decc,keep=keep

if n_params() eq 0 then begin
  print,'syntax- sobj2cobj3,sobjfile,rac=rac,decc=decc'
  return
endif

image_name_trans,sobjfile,imagest
;calibrate the sobjlist
print,'Beginning sobjfile '+imagest.sobj
chdr=headfits(imagest.cimg)
sobj=mrdfits(imagest.sobj,1,/silent)
rotse_iii_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0],rac=rac,decc=decc,keep=keep
if fail then rotse_iii_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0],rac=rac,decc=decc,keep=keep,skip=1

if (not fail) then begin
  write_cobj, imagest, ustat, ucal, chdr
  print, 'Sobjfile '+imagest.sobj+' finished.'
endif else begin
  print, 'Sobjfile '+imagest.sobj+' failed.'
endelse

end

