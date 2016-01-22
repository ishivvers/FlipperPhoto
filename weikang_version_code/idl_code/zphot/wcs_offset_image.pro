pro wcs_offset_image,refimname,refxy,newim,newimxy

if n_params() eq 0 then begin
  print,'wcs_offset_image,refimname,refxy,newim,newimxy'
  return
endif

offset=refxy-newimxy
newoffset=[mean(offset[0,*]),mean(offset[1,*])]

headref=headfits(refimname)
extast,headref,astr
astr.CRPIX=astr.CRPIX-offset

st=mrdfits(newim,0,headnew,/silent)
putast, headnew, astr

image_name_trans,newim,outimst
writefits,outimst.CIMG,st,headnew

end
