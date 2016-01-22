pro sobj2cobj,sobjfile,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin

if n_params() eq 0 then begin
  print,'syntax- sobj2cobj,sobjfile,pixscale=pixscale(in unit of arsec),rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin'
  return
endif

;if not keyword_set(pixscale) then pixscale=1.85*3600.0/2048.0 ;; in unit of arsec, 3.25195 for rotse3
;if not keyword_set(rac) then rac=0
;if not keyword_set(decc) then decc=0

image_name_trans,sobjfile,imagest
;calibrate the sobjlist
print,'Beginning sobjfile '+imagest.sobj
chdr=headfits(imagest.cimg)
sobj=mrdfits(imagest.sobj,1,/silent)
sobj_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[1.0,0.7,0.5,0.3],pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin
if fail then sobj_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[1.0,0.7,0.5,0.3],pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,skip=1

if (not fail) then begin
  write_cobj, imagest, ustat, ucal, chdr
  print, 'Sobjfile '+imagest.sobj+' finished.'
endif else begin
  print, 'Sobjfile '+imagest.sobj+' failed.'
endelse

end

