pro photom_dostars,im,cal,ra,dec,ra_arr,dec_arr,ucat,cind,m,merr

if n_params() eq 0 then begin
    print,'syntax- photom_dostars,im,cal,ra_arr,dec_arr,ucat,cind,m,merr'
    return
endif

astr_struct_new,1.85,astr
astr.crval=[cal.rac,cal.decc]

rd2xy,ucat[cind].ra,ucat[cind].dec,astr,xc,yc
kmap,xc,yc,compx,compy,cal.kx,cal.ky

;;killit
rd2xy,ra_arr,dec_arr,astr,xc,yc
kmap,xc,yc,starx,stary,cal.kx,cal.ky


phpadu = 3.0
aperture = 5.0
skyrad = [10,15]
;;skyrad=[5,10]
badpix = [0,0]

aper,im,compx,compy,mags,errap,sky,skyerr,phpadu,aperture,skyrad,badpix

;;offset=mean(mags) - mean(uucat[compstars].rmag)
offset=median(mags - ucat[cind].rmag,/even)

mags = mags - offset

aper,im,starx,stary,m,merr,ssky,sskyerr,phpadu,aperture,skyrad,badpix

m=m-offset


return
end
