pro find_fwhm_streak,imname,fwhm,fwhm_err,minpix=minpix,percentile=percentile,maxamp=maxamp,ratcut=ratcut

if n_params() eq 0 then begin
    print,'syntax-find_fwhm_streak,imname,fwhm,fwhm_err,minpix=minpix,percentile=percentile,maxamp=maxamp,ratcut=ratcut'
    return
endif

if n_elements(minpix) eq 0 then minpix = 5000l    
if n_elements(percentile) eq 0 then percentile = 0.2
if n_elements(maxamp) eq 0 then maxamp = 20.0
if n_elements(ratcut) eq 0 then ratcut = 2.0      ;; hmm

im=readfits(imname,hdr)

xc=n_elements(im[*,0])/2
yc=n_elements(im[0,*])/2

imsub=float(im[xc-149:xc+150,yc-149:yc+150])

sky,imsub,skyval,skysig
imsum=imsub-skyval

rb=fltarr(150,150)
for i=0l,150-1 do begin
    for j=0l,150-1 do begin
        rb[i,j] = total(imsub[i*2:i*2+1,j*2:j*2+1])
    endfor
endfor

mx=max(rb,ind)

if (mx lt minpix) then begin
    print,'No star bright enough in subregion: ',mx
    fwhm = -1.0
    fwhm_err=-1.0
    return
endif

ncol=n_elements(rb[*,0])
xstar = xc-149 + 2*(ind mod ncol)
ystar = yc-149 + 2*(ind / ncol)

nrow = n_elements(im[0,*])-ystar-100-20

fwhms=fltarr(nrow)
xcs=fltarr(nrow)

ctrdcut = 1.0
fwhmdcut = 2.0


st=0
en=nrow-1

for i=0l,nrow-1 do begin
    yval = i + ystar + 20
    
    line=im[xstar-10:xstar+10,yval]
    xvals=findgen(n_elements(line))

    if (i eq 0) then pkval = max(line)

    res=gaussfit(xvals,line,a,nterms=4)

    xcs[i] = a[1]
    fwhms[i] = a[2]*2.35

    if (i gt 10) then begin
        testctr=max(abs(xcs[i] - (xcs[i-10:i-1])))
        testfwhm=max(abs(fwhms[i] - (fwhms[i-10:i-1])))
        if (((testctr gt ctrdcut) and (testfwhm gt fwhmdcut)) or $
            (max(line) gt ratcut * pkval)) then begin
            en = i - 10
            i=nrow
        endif
    endif

endfor


if (en lt 200) then begin
    print,'Not enough good rows before a discontinuity:', en
    fwhm=-1.0
    fwhm_err=-1.0
    return
endif

fwhms=fwhms[st:en]
xcs=xcs[st:en]

if ((max(xcs) - min(xcs)) gt maxamp) then begin
    print,'amplitude too large: ',max(xcs)-min(xcs)
    fwhm=-1.0
    fwhm_err=-1.0
    return
endif
    


sf=fwhms[sort(fwhms)]
fwhm=sf[percentile*n_elements(sf)]
fwhm_err = stddev(fwhms)   ;; temporary!!!

return
end
