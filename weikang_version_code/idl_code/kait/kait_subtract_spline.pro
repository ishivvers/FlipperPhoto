pro kait_subtract,imagecobj, refcobj, pixscale=pixscale

if n_params() eq 0 then begin
  print,'syntax - kait_subtract,imagecobj, refcobj, pixscale=pixscale'
  return
endif

;;set pixel scale for KAIT images
if n_elements(pixscale) eq 0 then pixscale=0.7965/3600.0

;;set subimage size for subtraction
subsize=245

;;set subimage size for sky difference evaluation
skysize=499

;;set the size of the convolution kernel to 9 by 9
n_convolve=5L

;;set weight for the noise term
const_weight=1.

image_name_trans,imagecobj,imnamest
image_name_trans,refcobj,refnamest

;;read in the image files
;;for ref and new: image, header, objlist, stat
reffiles=[refnamest.cimg, refnamest.cobj]
newfiles=[imnamest.cimg,imnamest.cobj]

refim=readfits(reffiles[0],refhdr,/silent)
refcobjst=mrdfits(reffiles[1],1,/silent)
refstat=mrdfits(reffiles[1],2,/silent)
newim=readfits(newfiles[0],newhdr,/silent)
newcobj=mrdfits(newfiles[1],1,/silent)
newstat=mrdfits(newfiles[1],2,/silent)

;;may add bad pixel removal and background removal at this point

;;warp the new image accroding to the ref coordinates
;newim=xconvolve_warp_image(newim,refcobjst,newcobj,kx=kx,ky=ky,fail=warpfail,pixscale=pixscale)
;newim=xconvolve_warp_image(newim,refcobjst,newcobj,fail=warpfail,pixscale=pixscale)
;Using another procedure to warp the image
kait_warp_tf_ref, imagecobj, refcobj, pixscale=pixscale, /save, newim=newim

print,'Here 1'

;;get saturation levels from image headers
;satcnts1=sxpar(refhdr,'SATCNTS')
;satcnts2=sxpar(newhdr,'SATCNTS')
satcnts1=65530.0
satcnts2=65530.0

;;get typical fhwms, magnitude zero points from stat structrures
fwhm1=refstat.fwhm
fwhm2=newstat.fwhm
zeropoint1=23.+refstat.zp_offset
zeropoint2=23.+newstat.zp_offset
print,fwhm1,fwhm2
print,zeropoint1,zeropoint2

;;set minimum and maximum magnitude for ref objects to be compared with new in the fitting
minmag=15.
maxmag=19.

;;make mask
;;scale the new image to the flux level of the ref according to the counts measured
mask=xconvolve_make_mask(refim, newim, satcnts1, satcnts2, refcobjst, newcobj,   $
       fwhm1, fwhm2, zeropoint1, zeropoint2, n_convolve=n_convolve, /match,    $
       minmag=minmag, maxmag=maxmag, satmask=satmask, /scalenew,               $
       subsize=subsize, pixscale=pixscale)
print,'Here 2'

;;remove the low frequency variation between the ref and new
diff=newim-refim
diff=xconvolve_get_sky(diff,subsize=skysize,mask=satmask)
newim=newim-diff
print,'Here 3'

;;subtract with cross convolve
subimage=xconvolve_subtract_images(newim, refim, mask, n_convolve=n_convolve,  $
           ref_conv=ref_conv, /convolve_ref, const_weight=const_weight,        $
           newimage2=newref, sopath='/home/zwk/idl.lib/subtract', subsize=subsize)

print,'Here 4'
;;save the difference image to test.fit
;subhdr=newhdr
;refparts=strsplit(reffiles[0],'/',/extract)
;refimname=refparts[n_elements(refparts)-1]
;sxaddpar,subhdr,'refim',refimname
;writefits,'test.fit',subimage,subhdr

print,'Here 5'
;save convolved image
convhdr=refhdr
sxdelpar,convhdr,['refconv']
sxaddpar,convhdr,'refconv',refnamest.cobj,' reference file for convolution'
writefits,imnamest.conv,newref,convhdr

;save subtracted image
subhdr=refhdr
sxdelpar,subhdr,['refsub'] 
sxaddpar,subhdr,'refsub',refnamest.cobj,' reference file for subtraction'
writefits,imnamest.sub,subimage,subhdr

end


