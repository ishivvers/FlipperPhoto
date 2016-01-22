pro convert_rphot_format,datfile,outfile,magoffset=magoffset,toffset=toffset,z=z,a_r=a_r

if n_params() eq 0 then begin
    print,'syntax- convert_rphot_format,datfile,outfile,magoffset=magoffset,toffset=toffset,z=z,a_r=a_r'
    return
endif


if n_elements(toffset) eq 0 then toffset=0.0
if n_elements(magoffset) eq 0 then magoffset = 0.0
if n_elements(a_r) eq 0 then a_r=0.0

readcol,datfile,tmid,terr,mag,memag,pemag,limmag,format='f,f,f,f,f,f',/silent

tmid=tmid+toffset
mag=mag+magoffset

;; R-band definitions
delta_nu=1.1232342e+14
nu_eff=4.6753501e+14
jy=1e-23

obs=where(finite(mag) eq 1,nobs)
lims=where(finite(mag) eq 0,nlims)
fin=finite(mag)

emag=(pemag-memag)/2.   ;; good enough, it's basically how the calculation was done in the first place

if (nlims gt 0) then begin
    ;; for the conversion
    mag[lims] = limmag[lims]
    emag[lims] = 0.0
endif

;; now convert the magnitudes by the absorption if necessary
igm_offset=0.0
if n_elements(z) gt 0 then begin
    rotse_igm_absorption,z,frac,igm_offset

    print,'IGM offset: ',igm_offset

endif


res=mags2jy(mag-a_r+igm_offset)
ofd=res[*,0]
ofderr=(alog(10.)/2.5)*emag*ofd
oflux=ofd*delta_nu*jy
ofluxerr=(alog(10.)/2.5)*emag*oflux

;;stop
;; check for marginal detections
marg=where((oflux-ofluxerr) lt 0,nmarg)
if (nmarg gt 0) then begin
    ;; this will need to be discussed...
    limmag[marg] = mag[marg]-emag[marg]
    oflux[marg] = oflux[marg]+ofluxerr[marg]
    ofd[marg]=ofderr[marg]+ofd[marg]

    fin[marg] = 0  ;; so it will do limits
endif


openw,lun,outfile,/get_lun

printf,lun,'# hard-coded mag offset = ',magoffset
printf,lun,'# The following two are just used in the flux/fnu calculation'
printf,lun,'# Set A_R = ',a_r
printf,lun,'# IGM offset = ',igm_offset

for i=0l,n_elements(tmid)-1 do begin
    if fin[i] eq 1 then begin
        ;; an observation
        printf,lun,tmid[i],terr[i],mag[i],emag[i],oflux[i],-1.0*ofluxerr[i],ofluxerr[i],ofd[i],-1.0*ofderr[i],ofderr[i],format='(4d,6e)'
    endif else begin
        ;; a limit
        printf,lun,tmid[i],terr[i],0.0,limmag[i],0.0,0.0,oflux[i],0.0,0.0,ofd[i],format='(4d,6e)'
    endelse

endfor

free_lun,lun


return
end
