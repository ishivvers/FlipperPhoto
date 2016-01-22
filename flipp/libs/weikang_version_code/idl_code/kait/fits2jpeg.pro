pro fits2jpeg,fitsfilename,quality=quality,sigmaL=sigmaL,sigmaH=sigmaH,nonLinear=nonLinear

if n_params() eq 0 then begin
    print,'fits2jpeg,fitsfilename,quality=quality,sigmaL=sigmaL,sigmaH=sigmaH,nonLinear=nonLinear'
    return
endif

if not keyword_set(quality) then quality=75
if not keyword_set(sigmaL) then sigmaL=-1.0
if not keyword_set(sigmaH) then sigmaH=5.0

image=mrdfits(fitsfilename,/fscale,/silent)

;Figure out the jpeg file name
jpegname=fitsfilename
strreplace,jpegname,'.fits',''
strreplace,jpegname,'.fit',''
strreplace,jpegname,'.fts',''
strreplace,jpegname,'.FITS',''
strreplace,jpegname,'.FIT',''
strreplace,jpegname,'.FTS',''
jpegname=jpegname+'.jpg'
;print,jpegnamebaseo

sky,image,sky,skyerr,/silent
slow=sky+skyerr*sigmaL
shigh=sky+skyerr*sigmaH

cmd="fits2jpeg -fits "+fitsfilename+" -jpeg "+jpegname+" -min "+string(slow) + " -max "+string(shigh)+" -quality "+string(quality)
if keyword_set(nonLinear) then cmd=cmd+' -nonLinear'
;print,cmd
spawn,cmd

;This is another option to get jpeg, also easy
;dim=size(image)
;;plotdim=dim[1:2]*1.2
;plotdim=[1000,1000]
;ss_regions_to_jpeg,image,jpegname=jpegname,quality=70,dim=plotdim

end
