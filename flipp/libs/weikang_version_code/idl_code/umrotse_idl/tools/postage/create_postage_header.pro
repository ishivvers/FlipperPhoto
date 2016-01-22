pro create_postage_header,im,sc_im,hdr,mjd,mag,mag_err,index,xt=xt

if n_params() eq 0 then begin
    print,'syntax- create_postage_header,im,sc_im,hdr,mjd,mag,mag_err,index,xt=xt'
    return
endif

clip_min = 0.0d
clip_max = 65530.0d


;; Calculate bzero and bscale here
h=where((im gt (clip_min + 1)) and (im lt (clip_max - 1)),count)
if (count gt 0) then begin
    min = double(min(im[h]))
    max = double(max(im[h]))


    bscale = (max - min)/clip_max
    bzero = 0.5*(max + min + bscale)
    

endif else begin
    bzero = 0.0
    bscale = 1.0
endelse

sc_im = fix(round((im - bzero) / bscale) )

h2=where((im lt (clip_min + 1)), count2)
if (count2 gt 0) then begin
    sc_im[h2] = median(sc_im[h])
endif

if keyword_set(xt) then begin
    mkhdr,hdr,sc_im,/image
endif else begin
    mkhdr,hdr,sc_im,/extend
endelse

sxaddpar,hdr,'BITPIX',16
sxaddpar,hdr,'BZERO',bzero
sxaddpar,hdr,'BSCALE',bscale
sxaddpar,hdr,'MJD',mjd
sxaddpar,hdr,'MAG',mag
sxaddpar,hdr,'MAG_ERR',mag_err
sxaddpar,hdr,'INDEX',index




return
end
