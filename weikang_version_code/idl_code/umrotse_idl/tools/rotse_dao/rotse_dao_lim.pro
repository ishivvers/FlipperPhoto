pro rotse_dao_lim,im,psfname,satcnts,tx,ty,x,y,offset,lim

if n_params() eq 0 then begin
    print,'syntax - rotse_dao_lim,im,psfname,satcnts,tx,ty,x,y,offset,lim'
    return
endif

rdpsf,psf,hpsf,'psftest.fit'
psfx=n_elements(psf[*,0])
psfy=n_elements(psf[0,*])

psfflux=10.^((sxpar(hpsf,'psfmag')-25.)/(-2.5))
psfrad=sxpar(hpsf,'psfrad')
fitrad=sxpar(hpsf,'fitrad')   ;; = fwhm
ronoise=sxpar(hpsf,'ronois')
phpadu=sxpar(hpsf,'phpadu')
psfmag=sxpar(hpsf,'psfmag')

xstart=floor(tx-psfx/2.)
xend=xstart+psfx-1
ystart=floor(ty-psfy/2.)
yend=ystart+psfy-1

foundlim=0

scale=0.00001d   ;; need a good starting point
;; we'll make sure we don't find it on the first iteration
niter=0

while (not foundlim) do begin
    niter=niter+1

    testim=im
    testim[xstart:xend,ystart:yend] = testim[xstart:xend,ystart:yend] + scale*psf

    ;; check centroid...
    gcntrd,testim,tx,ty,xcen,ycen,fitrad,maxgood=satcnts

    if (xcen ne -1. and ycen ne -1.) then begin
        dist=sqrt((xcen-tx)^2.+(ycen-ty)^2.)
        if (dist lt 2.0) then begin
            ;; we can try to fit it
            grad=psfrad+fitrad
            h=where(x gt tx-grad and $
                    x lt tx+grad and $
                    y gt ty-grad and $
                    y lt ty+grad,nclose)
            if (nclose eq 0) then begin
                usex=xcen
                usey=ycen
            endif else begin
                usex=[xcen,x[h]]
                usey=[ycen,y[h]]
            endelse
            
            aper,testim,usex,usey,mag,err,sky,skyerr,phpadu, $
              3.5,[3.5,10],[-100000,satcnts],/silent
            ids=lindgen(n_elements(usex))
            gp=lonarr(n_elements(usex))

            ;; make sure magerr is undefined
            delvarx,magerr
            nstar_rotse,testim,ids,usex,usey,mag,sky,gp,phpadu, $
              ronoise,psfname,magerr,/silent,/flux

            ;; was it found
            if n_elements(magerr) gt 0 then begin
                ;; ...maybe...
                close_match,xcen,ycen,usex[0],usey[0],m1,m2,3.0,1,/silent
                if m2[0] ne -1 then begin
                    ;; yes it was found...
                    ;; was it a 3-sigma detection?
                    if (magerr[m2]/mag[m2] lt 0.33333) then begin
                        if (niter le 1) then begin
                            print,'Found on first iteration...resetting scale'
                            scale=0.1*scale
                        endif else begin                        
                            print,'Significant find after '+ $
                              string(niter,format='(i4)')+' iterations.'
                            lim=psfmag-2.5*alog10(mag)+offset                      
                            foundlim=1
                        endelse
                    endif
                endif
            endif
        endif
    endif


    scale=scale*1.1  ;; hmm

endwhile



return
end
