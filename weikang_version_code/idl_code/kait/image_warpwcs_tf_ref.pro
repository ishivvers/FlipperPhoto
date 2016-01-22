pro image_warpwcs_tf_ref, cimage, cref, newim=newim,from=from

if n_params() eq 0 then begin
  print,'syntax - image_warpwcs_tf_ref, cimage, cref, newim=newim,from=from'
  return
endif

image_name_trans,cimage,imnamest
image_name_trans,cref,refnamest

image1=mrdfits(refnamest.cimg,0,head1,/fscale,/silent)
image2=mrdfits(imnamest.cimg,0,head2,/fscale,/silent)

if keyword_set(from) then begin
  ;writefits will not use BZERO and BSCALE if data is flot or double
  ;hastrom,oldim,oldhd,newim,newhd,refhd
  hastrom,image1,head1,newim,newhd,head2
  sxdelpar,head1,['BZERO']
  sxdelpar,head1,['BSCALE']
  sxaddpar,head1,'BZERO',0.0
  sxaddpar,head1,'BSCALE',1.0
  sxdelpar,head1,['refwarp']
  sxaddpar,head1,'refwarp',refnamest.cobj,' reference file for warp'
  writefits,imnamest.cfwp,newim,head1
endif else begin
  ;writefits will not use BZERO and BSCALE if data is flot or double
  hastrom,image2,head2,newim,newhd,head1
  sxdelpar,head2,['BZERO']
  sxdelpar,head2,['BSCALE']
  sxaddpar,head1,'BZERO',0.0
  sxaddpar,head1,'BSCALE',1.0
  sxdelpar,head2,['refwarp']
  sxaddpar,head2,'refwarp',refnamest.cobj,' reference file for warp'
  writefits,imnamest.ctwp,newim,head2
endelse

end
