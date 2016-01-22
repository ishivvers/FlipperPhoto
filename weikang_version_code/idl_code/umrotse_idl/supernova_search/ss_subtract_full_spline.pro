function ss_subtract_full_spline,image1,image2,mask,n_convolve=n_convolve,ref_conv=image2_conv,convolve_ref=convolve_ref,subsize=subsize,const_weight=const_weight,newimage1=newimage1,newimage2=newimage2,sopath=sopath

if n_params() eq 0 then begin
    print,'syntax - sub=ss_subtract_full_spline(image1,image2,mask,n_convolve=n_convolve,ref_conv=image2_conv,convolve_ref=convolve_ref,subsize=subsize,const_weight=const_weight,newimage2=newimage2,sopath=sopath)'
    print,'image2 is the reference'
    print,'if convolve_ref keyword is set, convolve image2 to image2_conv'
    print,'if convolve_ref keyword is not set, use image2_conv'
    return,''
endif

if n_elements(n_convolve) eq 0 then n_convolve=9l
nch=n_convolve/2

if n_elements(sopath) eq 0 then sopath="./"

w_image=(size(image1))[1]
h_image=(size(image1))[2]

totalmask=total(mask)
if totalmask ge float(w_image)*float(h_image)/1000. then begin
    
    if n_elements(const_weight) eq 0 then const_weight=1.
    skyerr1=iqd(image1,/std_dev)
    skyerr2=iqd(image2,/std_dev)

;get the kernels
    ikernels=ss_make_spline_kernels_2()
    nk=(size(ikernels))[3]
    
;convolve the images with all the kernels
    image1_conv=fltarr(w_image,h_image,nk)
    
    if keyword_set(convolve_ref) then begin
        image2_conv=fltarr(w_image,h_image,nk)
        for nconv=0,nk-1 do begin
            kernel=ikernels[*,*,nconv]
            image1_conv[*,*,nconv]=convol(image1,kernel,/center)
            image2_conv[*,*,nconv]=convol(image2,kernel,/center)
        endfor
    endif else begin
        for nconv=0,nk-1 do begin
            kernel=ikernels[*,*,nconv]
            image1_conv[*,*,nconv]=convol(image1,kernel,/center)
        endfor
    endelse
    
    totvec=fltarr(nk)
    for itv=0,nk-1 do totvec[itv]=total(ikernels[*,*,itv])

;divide into n_pix x n_pix subregions
    if n_elements(subsize) eq 0 then subsize=300L
    nxsub=(w_image/subsize)>1
    nysub=(h_image/subsize)>1
    subx=ceil(double(w_image)/nxsub)
    suby=ceil(double(h_image)/nysub)
    allcoeff1=fltarr(nxsub,nysub,nk)
    allcoeff2=fltarr(nxsub,nysub,nk)
    for nx=0,nxsub-1 do begin
        for ny=0,nysub-1 do begin
            xl=nx*subx
            xh=(xl+subx-1)<(w_image-1)
            yl=ny*suby
            yh=(yl+suby-1)<(h_image-1)
            tmask=total(mask[xl:xh,yl:yh])
            while (tmask lt 500.) and (tmask lt totalmask) do begin
                xl=(xl-subsize/6.)>0
                xh=(xh+subsize/6.)<(w_image-1)
                yl=(yl-subsize/6.)>0
                yh=(yh+subsize/6.)<(h_image-1)
                tmask=total(mask[xl:xh,yl:yh])
                print,'extending sub region..',nx,ny
            endwhile
            submask=mask[xl:xh,yl:yh]
            r4_weight=const_weight*(skyerr1^2+skyerr2^2)*tmask
            subimage1_conv=image1_conv[xl:xh,yl:yh,*]
            subimage2_conv=image2_conv[xl:xh,yl:yh,*]
            cond=ss_cross_convolve_spline(subimage1_conv,subimage2_conv, $
                                          submask,r4_weight,sopath=sopath, $
                                          n_convolve=n_convolve, $
                                          ikernels=ikernels,coeff1=coeff1, $
                                          coeff2=coeff2)
            allcoeff1[nx,ny,*]=coeff1
            allcoeff2[nx,ny,*]=coeff2
        endfor
    endfor
        
    ;subimage=fltarr(w_image,h_image)
    newimage1=fltarr(w_image,h_image)
    newimage2=fltarr(w_image,h_image)

    x1a=rebin(2.0*findgen(w_image)/subx,w_image,h_image)
    x2a=transpose(rebin(2.0*findgen(h_image)/suby,h_image,w_image))
    for ink=0,nk-1 do begin
        cmap=bilinear(ss_extend_grid(allcoeff1[*,*,ink]),x1a,x2a)
        newimage1=newimage1+image1_conv[*,*,ink]*cmap
        
        cmap=bilinear(ss_extend_grid(allcoeff2[*,*,ink]),x1a,x2a)
        newimage2=newimage2+image2_conv[*,*,ink]*cmap
    endfor
    subimage=newimage1-newimage2

endif else begin
    
    subimage=replicate(0,w_image,h_image)
    newimage1=image1
    newimage2=image2    
endelse

return,subimage

end
