pro ds9_star_psf,fname,x,y

if n_params() lt 2 then begin
    print,'syntax - ds9_star_psf, fname, x, y'
    return
endif

xvals=findgen(10)
yvals=xvals^2.


im=readfits(fname)

sub=im[(x-10):(x+10),(y-10):(y+10)]

star_psf,sub,fwhm,xfit=xfit,yfit=yfit

title = ' "Star at (' + string(x,format='(i4)') + ',' + string(y,format='(i4)') + ') FWHM = ' + string(fwhm,format='(f5.2)') + ' pixels" '
xlab = ' "Radial Distance" '
ylab = ' "Flux" '

print,title,xlab,ylab,2


for i=0l,n_elements(xfit)-1 do begin
    print,xfit[i],yfit[i]
endfor


return
end
