function ss_scale_new,new,ref,mask,newscale=newscale

if n_params() eq 0 then begin
    print,'syntax - new=ss_scale_new(new,ref,mask,newscale=newscale)'
    return,''
endif

w_image=(size(ref))[1]
h_image=(size(ref))[2]

;divide into 400x400 subregions
nxbg=floor(w_image/400)
nybg=floor(h_image/400)
bgx=ceil(w_image/nxbg)
bgy=ceil(h_image/nybg)
scales=fltarr(nxbg,nybg)
for nx=0,nxbg-1 do begin
    for ny=0,nybg-1 do begin
        xl=nx*bgx
        xh=(nx*bgx+bgx-1)<(w_image-1)
        yl=ny*bgy
        yh=(ny*bgy+bgy-1)<(h_image-1)
        tmask=total(mask[xl:xh,yl:yh])
        while tmask lt 250 do begin
            xl=(xl-50)>0
            xh=(xh+50)<(w_image-1)
            yl=(yl-50)>0
            yh=(yh+50)<(h_image-1)
            tmask=total(mask[xl:xh,yl:yh])
        endwhile
        sky,new[xl:xh,yl:yh],sky1,err1,/silent
        sky,ref[xl:xh,yl:yh],sky2,err2,/silent
        ;err1=iqd(new[xl:xh,yl:yh],/std_dev)
        ;err2=iqd(ref[xl:xh,yl:yh],/std_dev)
        bgmask=mask[xl:xh,yl:yh]
        bg=where(new[xl:xh,yl:yh] lt sky1+err1*4. and ref[xl:xh,yl:yh] lt sky2+err2*4., nbg)
        if nbg gt 0 then bgmask(bg)=0
        scales[nx,ny]=total(ref[xl:xh,yl:yh]*bgmask)/total(new[xl:xh,yl:yh]*bgmask)
        ;scales[nx,ny]=total(ref[xl:xh,yl:yh]*mask[xl:xh,yl:yh])/total(new[xl:xh,yl:yh]*mask[xl:xh,yl:yh])
    endfor
endfor

if nxbg gt 1 or nybg gt 1 then begin
    x1a=lindgen(nxbg)*bgx+floor(bgx/2)
    x2a=lindgen(nybg)*bgy+floor(bgy/2)
    splie2,x1a,x2a,scales,nxbg,nybg,y2a1
    splin2,x1a,x2a,scales,y2a1,nxbg,nybg,findgen(w_image),findgen(h_image),scalemap
    
    new=temporary(new)*scalemap
endif else begin
    new=temporary(new)*scales[0,0]
endelse

newscale=total(new*mask)/total(ref*mask)

return,new

end
    
