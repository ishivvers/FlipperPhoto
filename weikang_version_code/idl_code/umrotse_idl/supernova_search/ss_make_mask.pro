function ss_make_mask,image1,image2,satcnts1,satcnts2,cobj1,cobj2,fwhm1,fwhm2,zeropoint1,zeropoint2,index1,index2,n_convolve=n_convolve,match=match,minmag=minmag,maxmag=maxmag,scalenew=scalenew,subsize=subsize,satmask=satmask,nobright=nobright,brightmag=brightmag

if n_params() eq 0 then begin
    print,'syntax - mask=ss_make_mask(image1,image2,satcnts1,satcnts2,cobj1,cobj2,fwhm1,fwhm2,zeropoint1,zeropoint2,n_convolve=n_convolve,match=match,minmag=minmag,maxmag=maxmag,pixscale=pixscale,scalenew=scalenew,subsize=subsize,satmask=satmask,nobright=nobright,brightmag=brightmag)'
    return,''
endif

if n_elements(n_convolve) eq 0 then n_convolve=9l
nch=n_convolve/2

w_image=(size(image1))[1]
h_image=(size(image1))[2]

;make mask
mask=replicate(1b,w_image,h_image)
mask[0:nch-1,0:h_image-1]=0B
mask[w_image-nch:w_image-1,0:h_image-1]=0B
mask[0:w_image-1,0:nch-1]=0B
mask[0:w_image-1,h_image-nch:h_image-1]=0B

;mask out the satuated pixels
tst=((image1 ge satcnts1) or (image2 ge satcnts2)) and mask
if (max(tst)) then begin
    indx=where(tst,ni)
    print,'number of saturated pixels',ni
    for i=0,ni-1 do begin
        ix=indx[i] mod w_image
        iy=indx[i]/w_image
        ixl=(ix-nch*2-1)>0
        ixh=(ix+nch*2+1)<(w_image-1)
        iyl=(iy-nch*2-1)>0
        iyh=(iy+nch*2+1)<(h_image-1)
        mask[ixl:ixh,iyl:iyh]=0b
    endfor
endif else begin
    print,'no saturated pixles.'
endelse

satmask=mask

;mask the matched area
if keyword_set(match) or keyword_set(scale_new) then begin
    nxbg=(floor(w_image/subsize))>1
    nybg=(floor(h_image/subsize))>1
    bgx=ceil(w_image/nxbg)
    bgy=ceil(h_image/nybg)
    nsub=nxbg*nybg
 
    if n_elements(index1) eq 0 or n_elements(index2) eq 0 then begin
        gd1=where(cobj1.flags le 2 and cobj1.m ge minmag and cobj1.m le maxmag,ngd1)    
        if (ngd1 lt nsub*3) then begin
            print,'WARNING: Not enough good ref stars.  Using them all.',ngd1
            gd1=lindgen(n_elements(cobj1))
        endif
        gd2=where(cobj2.flags le 2 and cobj2.m ge minmag and cobj2.m le maxmag,ngd2)    
        if (ngd2 lt nsub*3) then begin
            print,'WARNING: Not enough good new stars.  Using them all.',ngd2
            gd2=lindgen(n_elements(cobj2))
        endif
        close_match_radec,cobj1[gd1].ra,cobj1[gd1].dec,cobj2[gd2].ra,cobj2[gd2].dec,match1,match2,pixscale,1
        nmatch=n_elements(match1)
        if nmatch gt 0 then begin
            index1=gd1[match1]
            index2=gd2[match2]
        endif
    endif else nmatch=n_elements(index1)
    
    if nmatch gt 0 then begin
        if keyword_set(match) then matchmask=replicate(0b,w_image,h_image)
        if keyword_set(scalenew) then scales=fltarr(nxbg,nybg)

        gdcobj1=cobj1[index1]
        gdcobj2=cobj2[index2]
        
        for nx=0,nxbg-1 do begin
            for ny=0,nybg-1 do begin
                xl=nx*bgx
                xh=(nx*bgx+bgx-1)<(w_image-1)
                yl=ny*bgy
                yh=(ny*bgy+bgy-1)<(h_image-1)
                ind=where(gdcobj1.x ge xl and gdcobj1.x le xh and gdcobj1.y ge yl and gdcobj1.y le yh,nmatch)
                while nmatch lt 5 and (xl gt 0. or xh lt w_image-1 or yl gt 0. or yh lt h_image-1) do begin
                    xl=(xl-subsize/8.)>0
                    xh=(xh+subsize/8.)<(w_image-1)
                    yl=(yl-subsize/8.)>0
                    yh=(yh+subsize/8.)<(h_image-1)
                    ind=where(gdcobj1.x ge xl and gdcobj1.x le xh and gdcobj1.y ge yl and gdcobj1.y le yh,nmatch)
                endwhile
                
                if keyword_set(match) then begin 
                    if nmatch gt 8 then begin
;                    print,'use the first 8 objects out of :',nmatch
                        ind=ind[0:7]
                        nmatch=8
                    endif
                    for indm=0,nmatch-1 do begin
                        fwhm=ceil(fwhm1<fwhm2)>3.
                        xl=(floor(gdcobj1[ind[indm]].x-fwhm*1.5))>0 
                        xh=(ceil(gdcobj1[ind[indm]].x+fwhm*1.5))<(w_image-1)
                        yl=(floor(gdcobj1[ind[indm]].y-fwhm*1.5))>0 
                        yh=(ceil(gdcobj1[ind[indm]].y+fwhm*1.5))<(h_image-1) 
                        matchmask[xl:xh,yl:yh]=1b
                    endfor
                endif
                if keyword_set(scalenew) then begin
                    refflux=10^((zeropoint1-gdcobj1[ind].m)/2.5)
                    newflux=10^((zeropoint2-gdcobj2[ind].m)/2.5)
                    scales[nx,ny]=median(refflux/newflux,/even)  
                endif
            endfor
        endfor
        
        if keyword_set(match) then begin 
            mask=mask and matchmask
        endif
        if keyword_set(scalenew) then begin
            if nxbg gt 1 or nybg gt 1 then begin
                x1a=lindgen(nxbg)*bgx+floor(bgx/2)
                x2a=lindgen(nybg)*bgy+floor(bgy/2)
                splie2,x1a,x2a,scales,nxbg,nybg,y2a1
                splin2,x1a,x2a,scales,y2a1,nxbg,nybg,findgen(w_image),findgen(h_image),scalemap            
                image2=temporary(image2)*scalemap
            endif else begin
                image2=temporary(image2)*scales[0,0]
            endelse
        endif
    endif else begin
        print,'no match'
    endelse
    
endif else begin
;mask out the bright stars
    if keyword_set(nobright) then begin
        if n_elements(brightmag) eq 0 then brightmag=12.
        bright=where(cobj1.m le brightmag,nbright)
        if nbright gt 0 then begin
            for nb=0,nbright-1 do begin
                bfwhm=(cobj1[bright[nb]].fwhm*((fwhm2/fwhm1)>1))<50.
                ixl=(cobj1[bright[nb]].x-bfwhm*3.d0-nch-1)>0
                ixh=(cobj1[bright[nb]].x+bfwhm*3.d0+nch+1)<(w_image-1)
                iyl=(cobj1[bright[nb]].y-bfwhm*3.d0-nch-10)>0
                iyh=(cobj1[bright[nb]].y+bfwhm*3.d0+nch+1)<(h_image-1)
                mask[ixl:ixh,iyl:iyh]=0b
            endfor
        endif
    endif
endelse    

return,mask

end

