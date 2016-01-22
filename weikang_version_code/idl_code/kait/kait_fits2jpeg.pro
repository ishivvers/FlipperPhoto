pro kait_fits2jpeg,fitsfilename,jpegname=jpegname,quality=quality,sigmaL=sigmaL,sigmaH=sigmaH,nonLinear=nonLinear,dim=dim,title=title,uttitle=uttitle

if n_params() eq 0 then begin
    print,'kait_fits2jpeg,fitsfilename,jpegname=jpegname,quality=quality,sigmaL=sigmaL,sigmaH=sigmaH,nonLinear=nonLinear,dim=dim,title=title,uttitle=uttitle'
    return
endif

if not keyword_set(quality) then quality=75
if not keyword_set(sigmaL) then sigmaL=-1.0
if not keyword_set(sigmaH) then sigmaH=5.0

image=mrdfits(fitsfilename,0,hdr,/fscale,/silent)

;Figure out the jpeg file name if not given
if not keyword_set(jpegname) then begin
  jpegname=fitsfilename
  strreplace,jpegname,'.fits',''
  strreplace,jpegname,'.fit',''
  strreplace,jpegname,'.fts',''
  strreplace,jpegname,'.FITS',''
  strreplace,jpegname,'.FIT',''
  strreplace,jpegname,'.FTS',''
  jpegname=jpegname+'.jpg'
  ;print,jpegnamebaseo
endif

sky,image,sky,skyerr,/silent
slow=sky+skyerr*sigmaL
shigh=sky+skyerr*sigmaH

;cmd="fits2jpeg -fits "+fitsfilename+" -jpeg "+jpegname+" -min "+string(slow) + " -max "+string(shigh)+" -quality "+string(quality)
;if keyword_set(nonLinear) then cmd=cmd+' -nonLinear'
;;print,cmd
;spawn,cmd

;This is another option to get jpeg, also easy
if not keyword_set(dim) then begin
  dim=size(image)
  plotdim=dim[1:2]
  ;plotdim=[1000,1000]
endif

;Add UT time or not
titlename=''
if keyword_set(title) then titlename=title
if keyword_set(uttitle) then begin
  date=sxpar(hdr,'DATE-OBS')
  uttime=sxpar(hdr,'UT')
  day=strmid(date,0,2)
  month=strmid(date,3,2)
  year=strmid(date,6,4)
  hour=strmid(uttime,0,2)
  minute=strmid(uttime,3,2)
  second=strmid(uttime,6,2)
  titlename=titlename+' '+year+'-'+month+'-'+day+' '+hour+':'+minute+':'+second
endif

ss_regions_to_jpeg,image,jpegname=jpegname,quality=quality,dim=plotdim,title=titlename

end
