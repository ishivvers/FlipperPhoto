pro rotse_iii_usno_crop,ra,dec,cat,ncat,xcenter=xcenter,ycenter=ycenter,fov=fov

if n_params() eq 0 then begin
    print,'syntax- rotse_iii_usno_crop,ra,dec,cat,ncat,xcenter=xcenter,ycenter=ycenter,fov=fov'
    return
endif

if n_elements(xcenter) eq 0 then xcenter = 0
if n_elements(ycenter) eq 0 then ycenter = 0

ncat = cat

;;astr_struct_new,fov,astr
;;astr.crval=[double(ra),double(dec)]
;;rd2xy,cat.ra,cat.dec,astr,xc,yc

;;inpic=where(xc gt (xcenter - 1050) and xc lt (xcenter + 1050) and $
;;            yc gt (ycenter - 1050) and yc lt (ycenter + 1050),nin)


;;if nin eq 0 then begin
;;    print,'No catlog stars in range!'
;;    ncat = -1
;;    return
;;endif

;;ncat=ncat[inpic]

h=where(ncat.rmag ne 0.1, ngood)
if (ngood lt 1) then begin
    print,'No good catalog objects'
    ncat = -1
    return
endif

ncat=ncat[h]
sort=sort(ncat.rmag)
ncat=ncat[sort]

return
end
