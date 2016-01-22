;; ********************************************************************************
pro rphot_do_photometry,data
COMPILE_OPT IDL2

;; Gets the circular aperture and DAOPHOT PSF-fit counts for
;; everything.
;;
;; indices key:
;; [0,*] = fixed radius aperture
;; [1,*] = PSF-fit values
;; [2:*,*] = const * image specific PSF sigma aperture

;; procedure:
;;   - get local psf
;;   - get flux scaling relative to refim
;;   - subtract out any substars
;;   - do aper photometry
;;   - do PSF photometry

starttime=systime(1)

;; ***
;; *** first set up some constants/variables
;; ***

;; define the pixel radius over which the PSF is assumed to be constant
CONSTANT_PSF_RAD=250

refims=(*(*data).images)[(*data).refi]
ims=(*(*data).images)[(*data).current_image]

;;debug=1
if keyword_set(debug) then rphot_get_fitrad,data,ims,fitrad,psfrad

psfrad=1.5*ims.fwhm
fitrad=ims.fwhm
radtol=0.75*fitrad
imname=strmid(ims.imname,strpos(ims.imname,'/',/reverse_search)+1)
nphot=(*data).nphot

;; reset ref/obj counts
nref=n_elements((*refims.refx)[0,*])
*ims.refcounts=dblarr(nphot,nref)+!values.d_nan
*ims.refecounts=dblarr(nphot,nref)+!values.d_nan
nobj=n_elements(*refims.objx)
*ims.objcounts=dblarr(nphot,nobj)+!values.d_nan
*ims.objecounts=dblarr(nphot,nobj)+!values.d_nan


;; ***
;; *** get local psf
;; ***

;; get all the good objects with in the constant PSF radius of the target
dist=sqrt( (*ims.objx-ims.x[0])^2.0 + (*ims.objy-ims.y[0])^2.0 )
w=where(dist lt CONSTANT_PSF_RAD,nw)
if nw eq 0 then begin
    print,'*****************************'
    print,'No objects found near target!?!?!?'
    print,'*****************************'
    return
endif 
xs=(*ims.objx)[w]
ys=(*ims.objy)[w]
flags=(*ims.flags)[w]

;; recentroid objects
w=where(xs gt ims.fwhm and ys gt ims.fwhm $
        and xs lt ims.nx-ims.fwhm-1 and ys lt ims.ny-ims.fwhm-1 $
        and flags eq 0)
gcntrd,*ims.image,xs[w],ys[w],xcen,ycen,ims.fwhm,maxgood=ims.satcounts
w=where(xcen ne -1.0 and ycen ne -1.0,nw)
if nw eq 0 then begin
    print,'*****************************'
    print,'No good objects found near target!?!?!?'
    print,'*****************************'
    return
endif 
xs=xcen[w]
ys=ycen[w]

;; do aper photometry on everything
rphot_get_aper_counts,data,xs,ys,flux,eflux,skys=skys
w=where(flux/eflux gt 3.0,nw)
if nw eq 0 then begin
    print,'*****************************'
    print,'No good objects found near target!?!?!?'
    print,'*****************************'
    return
endif 
psfstarx=xs[w]
psfstary=ys[w]
psfstarcounts=flux[w]
psfstarmags=-2.5*alog10(psfstarcounts)+25
psfstarskys=skys[w]
ids=lindgen(nw)

;; Calculate the local PSF (actually, the residuals from a gaussian)
getpsf_rphot,*ims.image,psfstarx,psfstary,psfstarmags,psfstarskys $
  ,ims.ronoise,ims.gain,gauss,psf,ids,psfrad,fitrad,'',psfmag=psfmag,/quiet

ims.gauss=gauss
ims.psfmag=psfmag
ims.fitrad=fitrad
ims.psfrad=psfrad
*ims.psf=psf


;; ***
;; *** get flux scaling relative to refim
;; ***

;; locate all objects within the range of the refstars
xmin=min((*ims.refx)[0,*])-psfrad-fitrad
xmax=max((*ims.refx)[0,*])+psfrad+fitrad
ymin=min((*ims.refy)[0,*])-psfrad-fitrad
ymax=max((*ims.refy)[0,*])+psfrad+fitrad
xs=*ims.objx
ys=*ims.objy
w=where(xs gt xmin and xs lt xmax and ys gt ymin and ys lt ymax,nw)
if nw eq 0 then begin
    print,'*****************************'
    print,'RPHOT: cant find any objects on '+imname
    print,'*****************************'
    return
endif
imxs=xs[w]
imys=ys[w]
xs=[ims.x[0],imxs]
ys=[ims.y[0],imys]

;; transform refimage objx,y to this image
refimxs=*refims.objx
refimys=*refims.objy
kmap,refimxs,refimys,refimxs_mapped,refimys_mapped,*ims.kx,*ims.ky

;; add missing objects (from refim) near the target/refstars
close_match,refimxs_mapped,refimys_mapped,xs,ys,m1,m2,radtol,1,missed1
if missed1[0] ne -1 then begin
    xmiss=refimxs_mapped[missed1]
    ymiss=refimys_mapped[missed1]
    nmiss=n_elements(xmiss)
    keep=intarr(nmiss)
    for i=0,nmiss-1 do begin
        dist=sqrt( (xs-xmiss[i])^2.0 + (ys-ymiss[i])^2.0 )
        if min(dist) lt 2.0*ims.fwhm then keep[i]=1
    endfor

    w=where(keep eq 1,nw)
    if nw gt 0 then begin
        print,'Adding ',strtrim(nw,2),' missing objects from the refim'
        xs=[xs,xmiss[w]]
        ys=[ys,ymiss[w]]
    endif
endif

;; do aper photometry on everything
rphot_get_aper_counts,data,xs,ys,flux,eflux,skys=skys

;; recentroid everything
catch, error_status
if (error_status ne 0) then begin
    print,'*****************************'
    print,'RPHOT: had a problme with gcntrd'
    print,'*****************************'
    xcen=xs
    ycen=ys
endif else begin
    gcntrd,*ims.image,xs,ys,xcen,ycen,ims.fwhm,maxgood=ims.satcounts
endelse
catch,/cancel
w=where(xcen ne -1.0 and ycen ne -1.0 $
        and sqrt( (xs-xcen)^2.0 + (ys-ycen)^2.0 ) lt radtol $
        and flux gt 0,nw)
if nw eq 0 then begin
    print,'*****************************'
    print,'Not one object on '+imname+' has an aper flux above zero and a good centroid. Sorry.'
    print,'*****************************'
    return
endif
xs=xcen[w]
ys=ycen[w]
flux=flux[w]
eflux=eflux[w]
skys=skys[w]
inds=lindgen(nw)
mags=-2.5*alog10(flux)+25
w=where(finite(mags) eq 0,nw)
if nw gt 0 then mags[w]=99.9

;; group the stars together
group,xs,ys,psfrad+fitrad,ngroup

;; nstar does the actual psf fitting
nstar_rphot,*ims.image,inds,xs,ys,mags,skys,ngroup,ims.gain,ims.ronoise,'',magerr $
  ,usepsf=psf,gauss=gauss,psfmag=psfmag,psfrad=psfrad,fitrad=fitrad,/silent

;; find the refstars
close_match,(*ims.refx)[0,*],(*ims.refy)[0,*],xs,ys,m1,m2,radtol,1
if m1[0] eq -1 then begin
    print,'*********************************'
    print,'Could not fit PSF to any refstars on '+imname+'...sorry'
    print,'*********************************'
endif else begin
    (*ims.refx)[1,m1]=xs[m2]
    (*ims.refy)[1,m1]=ys[m2]
    (*ims.refcounts)[1,m1]=10.0^(-0.4*(mags[m2]-25))
    blah=10.0^(-0.4*(mags[m2]-psfmag))
    eblah=alog(10.0)/2.5*blah*magerr[m2]
    (*ims.refecounts)[1,m1]=10.0^(-0.4*(psfmag-25))*eblah

    ;; get the ratio ref/new of PSF-fit counts
    if (*data).current_image ne (*data).refi then begin
        ratios=(*ims.refcounts)[1,*]/(*refims.refcounts)[1,*]
        eratios=sqrt( ((*ims.refecounts)[1,*]/(*refims.refcounts)[1,*])^2.0 + ((*refims.refecounts)[1,*]*(*ims.refcounts)[1,*]/(*refims.refcounts)[1,*]^2.0)^2.0 )
        w=where((*ims.refcounts)[1,*] ne 0 and (*refims.refcounts)[1,*] ne 0,nw)
        if nw ne 0 then begin
            ratio=wtaverage(ratios[w],eratios[w])
            ims.ratio[1]=ratio[0]
            ims.eratio[1]=ratio[1]
        endif else begin
            print,'*********************************'
            print,'Could not calculate PSF-fit ratio '+imname+'...sorry'
            print,'*********************************'
        endelse
    endif
endelse


;; ***
;; *** subtract out any substars
;; ***

if (*data).nsubstars gt 0 and ims.ratio[1] gt 0 then begin
    substars=*(*data).substars
    kmap,substars.x,substars.y,subx,suby,*ims.kx,*ims.ky
    counts=substars.counts*ims.ratio[1]
    submags=-2.5*alog10(counts)+25.0
    image=*ims.image
    rphot_substar,image,subx,suby,submags $
      ,usepsf=psf,gauss=gauss,psfmag=psfmag,psfrad=psfrad,fitrad=fitrad 
endif else image=*ims.image


;; ***
;; *** do aper photometry
;; ***

;; do fixed aperture photometry on target
rphot_get_aper_counts,data,ims.x[0],ims.y[0],flux,eflux,lsky=lsky,skynoise=skynoise,image=image
ims.counts[0]=flux
ims.ecounts[0]=eflux
ims.sky=lsky
ims.skynoise=skynoise

;; do fixed aperture photometry on refstars
rphot_get_aper_counts,data,(*ims.refx)[0,*],(*ims.refy)[0,*],flux,eflux,image=image
(*ims.refcounts)[0,*]=flux
(*ims.refecounts)[0,*]=eflux

;; match objects to the refimage
close_match,refimxs_mapped,refimys_mapped,xs,ys,m1,m2,radtol,1,missed1

;; use same centroid ([0,*])
for i=2,nphot-1 do begin
    if (*data).radscale[i] lt 0 then radius=abs((*data).radscale[i]) $
    else radius=ims.fwhm*(*data).radscale[i]

    ;; target
    rphot_get_aper_counts,data,ims.x[0],ims.y[0],flux,eflux,radius=radius,image=image
    ims.counts[i]=flux
    ims.ecounts[i]=eflux

    ;; refstars
    rphot_get_aper_counts,data,(*ims.refx)[0,*],(*ims.refy)[0,*],flux,eflux,radius=radius,image=image
    (*ims.refcounts)[i,*]=flux
    (*ims.refecounts)[i,*]=eflux

    ;; ref/new ratio
    if (*data).current_image eq (*data).refi then ratio=[1.0,0.0] $
    else begin
        ratios=flux/(*refims.refcounts)[i,*]
        eratios=sqrt( (eflux/(*refims.refcounts)[i,*])^2.0 + ((*refims.refecounts)[i,*]*flux/(*refims.refcounts)[i,*]^2.0)^2.0 )
        ratio=wtaverage(ratios,eratios)
    endelse
    ims.ratio[i]=ratio[0]
    ims.eratio[i]=ratio[1]

    ;; all objects
    ;; (##### this could be much faster if we re-use sky values #####)
    rphot_get_aper_counts,data,xs,ys,flux,eflux,radius=radius,image=image

    ;; match objects to the refimage
    ;;close_match,refimxs_mapped,refimys_mapped,xs,ys,m1,m2,radtol,1,missed1
    if m1[0] ne -1 then begin
        (*ims.objcounts)[i,m1]=flux[m2]
        (*ims.objecounts)[i,m1]=eflux[m2]
    endif
endfor


;; ***
;; *** do PSF photometry (+ fixed aper obj)
;; ***

if (*data).nsubstars gt 0 and ims.ratio[1] gt 0 then begin
    ;; redo PSF-fitting if stars were removed 
    print,'Re-running PSF-fitting on subtracted image'
    nstar_rphot,image,inds,xs,ys,mags,skys,ngroup,ims.gain,ims.ronoise,'',magerr $
      ,usepsf=psf,gauss=gauss,psfmag=psfmag,psfrad=psfrad,fitrad=fitrad,/silent
endif

;; find the target
close_match,ims.x[0],ims.y[0],xs,ys,m1,m2,radtol,1
if m1[0] eq -1 then begin
    print,'*********************************'
    print,'Could not fit PSF to target on '+imname+'...sorry'
    print,'*********************************'
endif else begin
    ims.x[1]=xs[m2[0]]
    ims.y[1]=ys[m2[0]]
    ims.counts[1]=10.0^(-0.4*(mags[m2[0]]-25))
    blah=10.0^(-0.4*(mags[m2[0]]-psfmag))
    eblah=alog(10.0)/2.5*blah*magerr[m2[0]]
    ims.ecounts[1]=10.0^(-0.4*(psfmag-25))*eblah
endelse

;; find all the objects from the refimage
close_match,refimxs_mapped,refimys_mapped,xs,ys,m1,m2,radtol,1,missed1
if m1[0] eq -1 then begin
    print,'*********************************'
    print,'Could not fit PSF to any refimage objects on '+imname+'...sorry'
    print,'*********************************'
endif else begin
    ;; *** fixed aper ***
    (*ims.objcounts)[0,m1]=flux[inds[m2]]
    (*ims.objecounts)[0,m1]=eflux[inds[m2]]

    ;; psf
    (*ims.objcounts)[1,m1]=10.0^(-0.4*(mags[m2]-25))
    blah=10.0^(-0.4*(mags[m2]-psfmag))
    eblah=alog(10.0)/2.5*blah*magerr[m2]
    (*ims.objecounts)[1,m1]=10.0^(-0.4*(psfmag-25))*eblah
endelse



;; record
(*(*data).images)[(*data).current_image]=ims

print,systime(1)-starttime,format='("photometry took ",f5.2," seconds")'
end
