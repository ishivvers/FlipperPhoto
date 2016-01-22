pro kait_warp_tf_ref, imagecobj, refcobj, pixscale=pixscale, save=save, newim=newim,ref2image=ref2image,from=from
;+
;PURPOSE:
;    Interpolate the input image according to the reference.
;
;EXPLANATION:
;    Use IDL precedure poly_warp to find the transformation between
;    images. Operation fails when less than 30% of objects in image2
;    are matched to objects in reference (cobj1). Half of the matched
;    objects are used in poly_warp fit.
;
;
;INPUTS:
;    image2 - a two-dimension image array to be warped
;    cobj1 - an object list for the reference. Must an array of
;            structures with the following tags defined: ra, dec, x,
;            y (physical coordinates in the image), flags. Objects
;            with 'flags' less or equal than 2 are considered good
;            detections.
;    cobj2 - an object list for image2, the image to be warped. An
;            array of structres with the same tags defined as cobj1.
;
;OPTIONAL INPUTS:
;    pixscale - scale of the pixel size in unit of degree. This is
;               used to match the detections between image2 and the
;               reference. The default value if 0.0009d for ROTSE-III.
;
;OUTPUTS:
;    result - the warped image2 array.
;
;OPTIONAL OUTPUTS:
;    kx - the array of coefficients for cobj2.x as a polynomial
;         function of cobj1.x,cobj1.y.
;    ky - the array of coefficients for cobj2.y.
;    fail - 1 if too few matching objects are found and warping fails.
;           0 if the operation is succesful.
;
;-

if n_params() eq 0 then begin
  print,'syntax - kait_warp_tf_ref, imagecobj, refcobj, pixscale=pixscale, save=save, newim=newim, from=from'
  return
endif

if n_elements(pixscale) eq 0 then pixscale=0.7965/3600.0

image_name_trans,imagecobj,imnamest
image_name_trans,refcobj,refnamest

cobj1=mrdfits(refnamest.cobj,1,head1,/silent)
cobj2=mrdfits(imnamest.cobj,1,head2,/silent)
image1=mrdfits(refnamest.cimg,0,/fscale,/silent)
image2=mrdfits(imnamest.cimg,0,/fscale,/silent)

;gdref=where(cobj1.flags le 2,ngdref)
;gdnew=where(cobj2.flags le 2,ngdnew)
gdref=where(cobj1.flags ge 0,ngdref)
gdnew=where(cobj2.flags ge 0,ngdnew)

close_match_radec,cobj1[gdref].ra,cobj1[gdref].dec, $
  cobj2[gdnew].ra,cobj2[gdnew].dec,m1,m2,pixscale*4.0,1.0,miss1
nobj = n_elements(m1)

;;for nickel data(tested), the constatnt can be as low as 0.05
;;for kait data probably the same (not tested)
;if (nobj lt (0.15 * ngdnew)) then begin
;;OK, decide to use > 15 for kait images since 150416
if (nobj le 8) then begin
  ;print,'Not enough stars matched:',n_elements(m1),' < ',0.15*ngdnew
  print,'Not enough stars matched:',n_elements(m1),' < 8 '
  return
endif

;Now start warp

nl = fix(nobj*0.05)
nh = fix(nobj*0.95)

if keyword_set(from) then begin
  polywarp, cobj1[gdref[[m1[nl:nh]]]].x,cobj1[gdref[[m1[nl:nh]]]].y, $
    cobj2[gdnew[[m2[nl:nh]]]].x,cobj2[gdnew[[m2[nl:nh]]]].y, 1, kx, ky
  newim = poly_2d(image1, kx, ky, 1, missing=0.0, cubic=-0.5)
endif else begin
  polywarp,cobj2[gdnew[[m2[nl:nh]]]].x,cobj2[gdnew[[m2[nl:nh]]]].y, $
    cobj1[gdref[[m1[nl:nh]]]].x,cobj1[gdref[[m1[nl:nh]]]].y, 1, kx, ky
  newim = poly_2d(image2, kx, ky, 1, missing=0.0, cubic=-0.5)
endelse

if keyword_set(save) then begin
  if keyword_set(from) then begin
    head1=headfits(imnamest.cimg)
    ;writefits will not use BZERO and BSCALE if data is flot or double
    sxdelpar,head1,['BZERO']
    sxdelpar,head1,['BSCALE']
    sxaddpar,head1,'BZERO',0.0
    sxaddpar,head1,'BSCALE',1.0
    sxdelpar,head1,['refwarp']
    sxaddpar,head1,'refwarp',refnamest.cobj,' reference file for warp'
    writefits,imnamest.cfwp,newim,head1
  endif else begin
    head2=headfits(refnamest.cimg)
    ;writefits will not use BZERO and BSCALE if data is flot or double
    sxdelpar,head2,['BZERO']
    sxdelpar,head2,['BSCALE']
    sxaddpar,head1,'BZERO',0.0
    sxaddpar,head1,'BSCALE',1.0
    sxdelpar,head2,['refwarp']
    sxaddpar,head2,'refwarp',refnamest.cobj,' reference file for warp'
    writefits,imnamest.ctwp,newim,head2
  endelse
endif

end
