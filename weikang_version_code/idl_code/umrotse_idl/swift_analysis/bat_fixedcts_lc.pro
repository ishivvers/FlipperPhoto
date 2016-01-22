pro bat_fixedcts_lc,lcfile,datfile,outfile,plot=plot,enlo=enlo,enhi=enhi,float_ex=float_ex

if n_params() eq 0 then begin
    print,'syntax- bat_fixedcts_lc,lcfile,datfile,outfile,plot=plot,enlo=enlo,enhi=enhi,float_ex=float_ex'
    return
endif


if n_elements(enlo) eq 0 then enlo = 0.3
if n_elements(enhi) eq 0 then enhi = 10.0
if n_elements(float_ex) eq 0 then begin
    if (enlo eq 0.3 and enhi eq 10.0) then begin
        ex=2.766
    endif else ex=70.8
endif

print,'Using: ',enlo,' to ',enhi,' keV'

xrt_read_datfile,datfile,datstr,fail=fail
if (fail eq 1) then begin
    print,'problem reading datfile'
    return
endif

burstmjd=datstr[0].burstmjd

lc=mrdfits(lcfile,1)
hdr=headfits(lcfile,exten=1)
mjdrefi = sxpar(hdr,'MJDREFI')
utcfinit = sxpar(hdr,'UTCFINIT')

mjd=mjdrefi+(lc.time+utcfinit)/86400.
tstart=(mjd-burstmjd)*86400.
tstop=shift(tstart,-1)
tstop[n_elements(tstop)-1] = tstop[n_elements(tstop)-2]+10.
tmid=(tstop+tstart)/2.
terr=(tstop-tstart)/2.


openw,lun,outfile,/get_lun

for index=0l,n_elements(datstr)-1 do begin
    starttime=datstr[index].tstart
    stoptime=datstr[index].tstop

    print,starttime,stoptime

    if (datstr[index].epeak gt 0.0) then begin
;;        grbm_flux,-1.0*datstr[index].gamma,datstr[index].beta,datstr[index].epeak,datstr[index].norm,datstr[index].normlo,datstr[index].normhi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi
        grbm_flux,datstr[index].alpha,datstr[index].beta,datstr[index].epeak, $
          datstr[index].norm,datstr[index].normlo,datstr[index].normhi, $
          flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi,e_p=datstr[index].e_p

    endif else begin

        if (datstr[index].enlo eq 0.0) then begin
            xrt_unabsorbed_flux,datstr[index].gamma,datstr[index].norm,datstr[index].normlo,datstr[index].normhi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi        
        endif else if (datstr[index].enlo eq datstr[index].enhi) then begin
            ;; not sure what to do here.
            print,'Oi vey!'
            stop
        endif else begin
            ;; standard bat stuff
            if (datstr[index].enlo eq enlo and datstr[index].enhi eq enhi) then begin
                ;; this requires no extrapolation
                flux=datstr[index].norm*1e-12
                fluxlo=datstr[index].normlo*1e-12
                fluxhi=datstr[index].normhi*1e-12
            endif else begin
                ;; extrapolate THIS
                if (datstr[index].xgamma ne 0.0) then begin
                    egamma=(datstr[index].xgamma+datstr[index].gamma)/2.
                endif else begin
                    egamma=datstr[index].gamma
                endelse

                print,'Extrapolating with: ',egamma

                bat_extrapolate_flux,datstr[index].gamma,egamma, $
                  datstr[index].enlo,datstr[index].enhi, $
                  datstr[index].norm,datstr[index].normlo,datstr[index].normhi, $
                  flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi

            endelse
        endelse            
    endelse

    print,'flux = ',flux,fluxlo,fluxhi

    c=flux/datstr[index].ct
    test=sqrt(((flux-fluxlo)/flux)^2. + (datstr[index].cterr/datstr[index].ct)^2.)
    clo=c-test*c
    
    test=sqrt(((fluxhi-flux)/flux)^2. + (datstr[index].cterr/datstr[index].ct)^2.)
    chi=c+test*c

    print,'c = ',c,clo,chi

    gamma=datstr[index].gamma
    gamma_err=(datstr[index].gammahi-datstr[index].gammalo)/2.
    print,'gamma= ',gamma,' +/- ',gamma_err

    use=where(tmid ge starttime and tmid lt stoptime,nuse)
    for i=0l,nuse-1 do begin
        rate=lc[use[i]].rate
        err=lc[use[i]].error

        ;; do limits differently (if it's consistent with 0)
        if (rate - err gt 0) then begin
            flux=rate * c
            temp=sqrt(((flux-rate*clo)/flux)^2. + (err/rate)^2.)
            flux_lo=flux-temp*flux
            temp=sqrt(((rate*chi - flux)/flux)^2. + (err/rate)^2.)
            flux_hi=flux+temp*flux
            
;;            calculate_xray_jansky,flux,(flux_hi-flux_lo)/2.,gamma,gamma_err,enlo,enhi,xfd,xfde
            calculate_xray_jansky2,flux,flux_lo,flux_hi,gamma,gamma_err,enlo,enhi,xfd,xfd_lo,xfd_hi,ex=ex
;;            printf,lun,tmid[use[i]],terr[use[i]],rate,err, $
;;              flux,flux_lo-flux,flux_hi-flux,xfd,xfde,format='(4d,5e)'
            printf,lun,tmid[use[i]],terr[use[i]],rate,err, $
              flux,flux_lo-flux,flux_hi-flux,xfd,xfd_lo-xfd,xfd_hi-xfd,format='(4d,6e)'
        endif else begin
            flux=0.0
            fluxp=2.*err*c
            fluxm=0.0
;;            calculate_xray_jansky,fluxp,0.0,gamma,gamma_err,enlo,enhi,xfd,xfde
            calculate_xray_jansky2,fluxp,fluxp,fluxp,gamma,gamma_err,enlo,enhi,xfd,dummy1,dummy1,ex=ex
            
            fd=0.0
            fdp=xfd
            fdm=0.0

            printf,lun,tmid[use[i]],terr[use[i]],rate,err, $
              flux,fluxm,fluxp,fd,fdm,fdp,format='(4d,6e)'

        endelse

    endfor


endfor


free_lun,lun

if keyword_set(plot) then begin
    readcol,outfile,tmid,terr,rate,raterr,flux,fluxm,fluxp,xfd,xfdm,xfdp,/silent

;;    ploterror,tmid,rate,terr,raterr,psym=1,/nohat
;;    ploterror,tmid,flux,terr,(fluxp-fluxm)/2.,psym=1,/nohat,/ylog
    
    toplot=where(flux gt 0 and (flux-(fluxp-fluxm)/2.) gt 0)
    ploterror,tmid[toplot],flux[toplot],terr[toplot],(fluxp[toplot]-fluxm[toplot])/2.,psym=1,/nohat,/ylog


endif


return
end
