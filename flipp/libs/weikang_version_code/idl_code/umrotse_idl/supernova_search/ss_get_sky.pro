function ss_get_sky,im,mashsize=mashsize,satmask=satmask

;get the background array of the input image

size=size(im)
width=size[1]
height=size[2]
sky=dblarr(width,height)

if n_elements(mashsize) eq 0 then mashsize=32
nmashx=ceil(width/32)
nmashy=ceil(height/32)
skyvec=dblarr(nmashx,nmashy)

;filter the image with a 3*3 median filter
filt_im=median(im,3)

for mashx=0,nmashx-1 do begin
    xrange1=((mashx+1)*mashsize-1)<(width-1)
    xrange0=xrange1-mashsize+1

    for mashy=0,nmashy-1 do begin
        yrange1=((mashy+1)*mashsize-1)<(height-1)
        yrange0=yrange1-mashsize+1

        input=filt_im[xrange0:xrange1,yrange0:yrange1]

        if n_elements(satmask) gt 0 then begin
            submask=satmask[xrange0:xrange1,yrange0:yrange1]
            while total(submask) lt mashsize^2*2d0/3d0 do begin
                ;print,'extending area for sky estimate...',mashx,mashy
                xrange1=(xrange1+mashsize/4)<(width-1)
                xrange0=(xrange0-mashsize/4)>0
                yrange1=(yrange1+mashsize/4)<(height-1)
                yrange0=(yrange0-mashsize/4)>0
                submask=satmask[xrange0:xrange1,yrange0:yrange1]
            endwhile
            input=filt_im[xrange0:xrange1,yrange0:yrange1]
            input=input(where(submask eq 1b))
        endif

;print,'median before cliping:',median
        nout=1
        ct=0
        crowd=0
        sig=0
        while nout gt 0 do begin
            ninput=n_elements(input)
            median=median(input)
            sig1=stddev(input)
            if ct gt 0 then if abs(sig-sig1)/sig gt 0.2 then crowd=1
            sig=sig1
            keep=where(abs(input-median) le 3d0*sig,nkeep)
            nout=ninput-nkeep 
            input=input(keep)
            ct=ct+1
;print,ct,' median:',median
        endwhile
        
        mean=mean(input)
        if crowd eq 1 then skyvec[mashx,mashy]=2.5*median-1.5*mean $
        else skyvec[mashx,mashy]=mean
                
    endfor
endfor

;interpolate the vector to full image size
;x1a=lindgen(nmashx)*mashsize+mashsize/2
;x2a=lindgen(nmashy)*mashsize+mashsize/2
;splie2,x1a,x2a,skyvec,nmashx,nmashy,y2a
;splin2,x1a,x2a,skyvec,y2a,nmashx,nmashy,findgen(width),findgen(height),sky

x1a=rebin(2.0*findgen(width)/mashsize,width,height)
x2a=transpose(rebin(2.0*findgen(height)/mashsize,height,width))
if nmashx gt 1 or nmashy gt 1 then begin
    sky=bilinear(ss_extend_grid(skyvec),x1a,x2a)
endif else begin
    sky=replicate(skyvec[0,0],width,height)
endelse

return,sky

end






