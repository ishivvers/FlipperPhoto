pro find_rotse_focus_streak,filearr,outfname,pngname=pngname,imagedir=imagedir

if n_params() eq 0 then begin
    print,'syntax- find_rotse_focus_streak,filearr,outfname,pngname=pngname,imagedir=imagedir'
    return
endif

if n_elements(imagedir) eq 0 then imagedir = 'image/'

nfile=n_elements(filearr)

focs=fltarr(nfile)
fwhms=fltarr(nfile)
fwhm_errs=fltarr(nfile)
fnames=strarr(nfile)

for i=0l,nfile-1 do begin
    fnames[i] = imagedir + '/' + filearr[i] 

    hdr=headfits(fnames[i])
    focs[i] = sxpar(hdr,'FOCUS')
    
    find_fwhm_streak,fnames[i],fwhm,fwhm_err,percentile=0.2
    fwhms[i] = fwhm
    fwhm_errs[i] = fwhm_err
endfor

plot=0
if n_elements(pngname) eq 1 then begin
    set_plot,'z'
    device,set_resolution=[400,200]
    plot=1
endif


find_focus_streak,focs,fwhms,fwhm_errs,bestfoc,err,chisq,fail=fail,plot=plot

;; output the file...
openw,lun,outfname,/get_lun
hdr=headfits(fnames[0])

line=string(sxpar(hdr,'MJD'),format='(f13.7)') + ' ' + $
  string(bestfoc,format='(f6.3)') + ' ' + $
  string(err,format='(f6.3)') + ' ' + $
  string(chisq,format='(f6.3)') + ' ' + $
  string(sxpar(hdr,'AZIMUTH'),format='(f7.3)') + ' '+ $
  string(sxpar(hdr,'ELEV'),format='(f7.3)') + ' ' + $
  string(sxpar(hdr,'TEMPOUT'),format='(f7.3)') + ' ' + $
  string(sxpar(hdr,'WINDSPD'),format='(f5.1)')


printf,lun,line

for i=0l,nfile-1 do begin
    line=fnames[i] + ' ' + $
      string(focs[i],format='(f7.3)') + ' ' + $
      string(fwhms[i],format='(f7.3)') + ' ' + $
      string(fwhm_errs[i],format='(f7.3)')
    printf,lun,line
endfor


free_lun,lun

;; and do the png
if n_elements(pngname) gt 0 then begin

    line='Best focus = '+string(bestfoc,format='(f6.3)') + ' +/- ' + $
      string(err,format='(f6.3)') + ' chi^2=' + string(chisq,format='(f5.1)')
    xyouts,30,185,line,/device

    xyouts,30,10,pngname,/device

    write_png,pngname,tvrd()
    set_plot,'x'
endif


return
end
