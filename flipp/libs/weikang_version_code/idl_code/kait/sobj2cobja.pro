pro sobj2cobja,sobjfile,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots,subr=subr,skip=skip,searchrad=searchrad

if n_params() eq 0 then begin
  print,'syntax- sobj2cobj,sobjfile,pixscale=pixscale(in unit of arsec),rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin'
  return
endif

;make image names st
image_name_trans,sobjfile,imagest
;calibrate the sobjlist
print,'Beginning sobjfile '+imagest.sobj

;read in the head from cimage
chdr=headfits(imagest.cimg)
;read in the sobj structure from sobj file
sobj=mrdfits(imagest.sobj,1,/silent)

;try to get kait parameters if not given in the key word
if not keyword_set(keep) then keep=20
if not keyword_set(plots) then plots=0.0
if not keyword_set(iter) then iter=15   ;; this is now a maximum number of iterations
if not keyword_set(nbin) then nbin=1
if not keyword_set(skip) then skip=2
if not keyword_set(searchrad) then searchrad=1.1
if not keyword_set(subr) then subr=[1.0,0.7]
;if not keyword_set(subr) then subr=[1.0,0.7,0.5,0.3]
if n_elements(order) eq 0 then order=1


shdr=chdr
if not keyword_set(pixscale) then begin
  if (sxpar(shdr,'PIXSCALE') ne 0) then begin
    pixscale=sxpar(shdr,'PIXSCALE')
  endif else begin
    pixscale=0.7965   ; this is for kait, FLI MicroLine 512 CCD
  endelse
endif

if not keyword_set(rac) then begin
  racstr=sxpar(shdr,'RA')
  deccstr=sxpar(shdr,'DEC')
  epoch=float(sxpar(shdr,'EPOCH'))
  racepoch=ten(racstr)*15.0
  deccepoch=ten(deccstr)
  precess,racepoch,deccepoch,epoch,2000.0
  rac=racepoch
  decc=deccepoch
endif

;print,rac,decc,pixscale,keep

keepstar=keep
sobj_usno_cala,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=subr,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots,searchrad=searchrad
if fail then begin
  keep=keepstar
  sobj_usno_cala,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=subr,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots, searchrad=searchrad,skip=skip
endif

if (not fail) then begin
  write_cobja, imagest, ustat, ucal, chdr, pixscale=pixscale
  print, 'Sobjfile '+imagest.sobj+' finished.'
  return
endif

;;;------------------------------------------
print, 'Sobjfile '+imagest.sobj+' failed, try using wcs information to calibrate'
f=findfile(imagest.cwcs)
if f[0] eq '' then begin
  print,'No wcs infomration found, quiting ...'
  return
endif
print,'Using : ',f[0]
centX=250.0
centY=250.0
wcsxy2rd,f[0],centX,centY,newra,newdec
rac=newra
decc=newdec

;Now let's try again
keep=keepstar
;print,rac,decc,pixscale,keep

sobj_usno_cala,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=subr,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots,searchrad=searchrad
if fail then begin
  keep=keepstar
  sobj_usno_cala,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=subr,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots, searchrad=searchrad,skip=skip
endif

if (not fail) then begin
  write_cobja, imagest, ustat, ucal, chdr, pixscale=pixscale
  print, 'Sobjfile '+imagest.sobj+' finished.'
  return
endif

;;;------------------------------------------
print, 'Sobjfile '+imagest.sobj+' failed, latst last try using wcs information to calibrate'

rac=newra
decc=newdec
radius=pixscale*centX/3600.0
radius=radius*searchrad
extract_usno_db,rac,decc,radius,ucat,basename='usno18'
wcsrd2xy,f[0],ucat.RA,ucat.DEC,x,y
ind=where(x gt 0 and x le centX*2.0 and y gt 0 and y le centY*2.0, nf)
help,ucat,ind
if nf gt 0 then ucat=ucat[ind]
;Now its last try
keep=keepstar
;print,rac,decc,pixscale,keep

sobj_usno_cala,chdr,sobj,ucat,ucal,ustat,fail=fail,subr=subr,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots,searchrad=searchrad
if fail then begin
  keep=keepstar
  sobj_usno_cala,chdr,sobj,ucat,ucal,ustat,fail=fail,subr=subr,pixscale=pixscale,rac=rac,decc=decc,keep=keep,iter=iter,order=order,nbin=nbin,plots=plots, searchrad=searchrad,skip=skip
endif

if (not fail) then begin
  write_cobja, imagest, ustat, ucal, chdr, pixscale=pixscale
  print, 'Sobjfile '+imagest.sobj+' finished.'
  return
endif

end

