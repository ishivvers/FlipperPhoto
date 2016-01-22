pro add_stars_to_image,im,cobj,cal,sobj,shdr,ras,decs,mags,im_new

if n_params() eq 0 then begin
    print,'syntax- add_stars_to_image,im,cobj,cal,sobj,shdr,ras,decs,mags,im_new'
    return
endif

aprad = 2.5

magzp = sxpar(shdr,'SEXMGZPT')

im_new = im

for i=0l,n_elements(ras)-1 do begin
    ra = ras[i]
    dec = decs[i]
    mag = mags[i]

    ;; find where it is
    astr_struct_new,1.85,astr
    astr.crval=[double(cal.rac),double(cal.decc)]
    rd2xy,ra,dec,astr,xc,yc
    kmap,xc,yc,xx,yy,cal.kx,cal.ky


    close_match_radec,ra,dec,cobj.ra,cobj.dec,m1,m2,0.0009d*50.,100,/silent

    if (m1[0] eq -1) then begin
        print,'no neighbors!'
    endif else begin
    
        close_match,cobj[m2].x,cobj[m2].y,sobj.x_image-1,sobj.y_image-1,mm1,mm2,0.1,1,/silent

        h=where((cobj[m2].flags and 4) eq 0,nnosat)

        if (nnosat lt 5) then begin
            print,'too few unsaturated objects: not adding this image'
        endif else begin
            
            fwhm=median(sobj[mm2[h]].fwhm_image)
            
            npixel = 10
            if (fwhm gt 5) then begin
                print,'psf very large...is this typical: ', fwhm
                npixel = 20
            endif
            
            xstart = floor(xx[0])-npixel/2
            xcent = xx[0] - xstart
            ystart = floor(yy[0])-npixel/2
            ycent = yy[0] - ystart
            
            temp = npixel
            psf=psf_gaussian(fwhm=fwhm,npixel=temp,centroid=[xcent,ycent])
            
            aper,psf,xcent,ycent,flux,errap,sky,skyerr,3.0,aprad, $
                 [aprad,npixel/2.],[-32765,32767],/flux,/silent
            
            full_flux = 10.^((magzp - (mag - cal.zp_offset))/2.5)
            
            ;; scale the psf
            psf = psf * (full_flux / flux[0])

            ;; now add it in

            if ((xstart lt 0) or (xstart + npixel - 1 ge n_elements(im_new[*,0])) or $
                (ystart lt 0) or (ystart + npixel - 1 ge n_elements(im_new[0,*]))) then begin
                print,'psf over boundary: not adding'
            endif else begin

                im_new[xstart:xstart+npixel-1,ystart:ystart+npixel-1] = $
                  im_new[xstart:xstart+npixel-1,ystart:ystart+npixel-1] + psf
            endelse
        endelse
    endelse
endfor

return
end
