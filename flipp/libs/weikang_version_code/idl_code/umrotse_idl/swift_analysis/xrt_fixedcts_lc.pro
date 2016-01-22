pro xrt_fixedcts_lc,srcevts,datfile,outfile,starttime=starttime,stoptime=stoptime,gtifile=gtifile,plot=plot,norb=norb,ctsperbin=ctsperbin,use_avg_bk=use_avg_bk,enlo=enlo,enhi=enhi,no_background=no_background,float_ex=float_ex

if n_params() eq 0 then begin
    print,'syntax-  xrt_fixedcts_lc,srcevts,datfile,outfile,starttime=starttime,stoptime=stoptime,gtifile=gtifile,plot=plot,norb=norb,enlo=enlo,enhi=enhi,ctsperbin=ctsperbin,use_avg_bk=use_avg_bk,no_background=no_background,float_ex=float_ex'
;;    print,'  use bkevt for wt mode...'
    return
endif

if n_elements(enlo) eq 0 then enlo = 0.3
if n_elements(enhi) eq 0 then enhi = 10.0
if n_elements(norb) eq 0 then norb = 4
if n_elements(ctsperbin) eq 0 then ctsperbin = 50
if keyword_set(no_background) then use_avg_bk = 1  ;; average of 0
if n_elements(float_ex) eq 0 then ex=2.766
;;if n_elements(float_ex) eq 0 then ex=1.0 

print,'Using: ',enlo,' to ',enhi,' keV'

xrt_read_evts,srcevts,evt,gti,orbgti,mode,tstart,tstop,gtifile=gtifile


xrt_read_datfile,datfile,datstr,fail=fail
if (fail eq 1) then begin
    print,'problem reading datfile'
    return
endif

xrt_get_data_index,datstr,srcevts,mode,tstart,tstop,index,fail=fail
if (fail eq 1) then begin
    print,'Could not get info from datfile: time mismatch?'
    return
endif

burstmjd=datstr[index].burstmjd
starttime=datstr[index].tstart
stoptime=datstr[index].tstop

if (datstr[index].epeak gt 0.0) then begin
    ;; we have a grbm

    grbm_flux,datstr[index].alpha,datstr[index].beta,datstr[index].epeak, $
      datstr[index].norm,datstr[index].normlo,datstr[index].normhi, $
      flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi,e_p=datstr[index].e_p

    ;; approximate
    
    gamma=-1.0*datstr[index].alpha
    gamma_err=(datstr[index].alphahi-datstr[index].alphalo)/2.


endif else begin
    ;; standard powerlaw


    if (datstr[index].enlo eq 0.0) then begin
        ;; this is the regular integration

        xrt_unabsorbed_flux,datstr[index].gamma,datstr[index].norm,datstr[index].normlo,datstr[index].normhi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi

    endif else begin
        if (datstr[index].enlo eq enlo and datstr[index].enhi eq enhi) then begin
            ;; no extrapolation necessary
            flux=datstr[index].norm*1e-12
            fluxlo=datstr[index].normlo*1e-12
            fluxhi=datstr[index].normhi*1e-12
        endif else begin
            bat_extrapolate_flux,datstr[index].gamma,datstr[index].gamma, $
              datstr[index].enlo,datstr[index].enhi, $
              datstr[index].norm,datstr[index].normlo,datstr[index].normhi,$
              flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi
        endelse
    endelse

    
    gamma=datstr[index].gamma
    gamma_err=(datstr[index].gammahi-datstr[index].gammalo)/2.


endelse


print,'flux = ',flux,fluxlo,fluxhi

c=flux/datstr[index].ct
test=sqrt(((flux-fluxlo)/flux)^2. + (datstr[index].cterr/datstr[index].ct)^2.)
clo=c-test*c

test=sqrt(((fluxhi-flux)/flux)^2. + (datstr[index].cterr/datstr[index].ct)^2.)
chi=c+test*c

print,'c = ',c,clo,chi

print,'gamma= ',gamma,' +/- ',gamma_err

;; get the time conversion information
hdr=headfits(srcevts[0],exten=1)
mjdrefi = sxpar(hdr,'MJDREFI')
utcfinit = sxpar(hdr,'UTCFINIT')
timedel = sxpar(hdr,'TIMEDEL')

;; if we aren't using the average background, then we can assume we only have
;; one source evtfile

if (not keyword_set(use_avg_bk)) then begin
    aparts=strsplit(srcevts[0],'\.evt',/extract,/regex)
    parts=strsplit(aparts[0],'-',/extract)
    bkevtfile=parts[0]+'-bkg-'+parts[2]+'-'+parts[3]+'-'+parts[4]+'.evt'
    print,'Using background evtfile: ',bkevtfile
    bkevt=mrdfits(bkevtfile,1)
    bhdr=headfits(bkevtfile,exten=1)
    
    bkareascale=sxpar(hdr,'NPIXSOU')/sxpar(bhdr,'NPIXSOU')
endif


if (n_elements(starttime) ne 0) then begin
    starttime_sc = starttime + (burstmjd - mjdrefi)*86400d - utcfinit
endif else begin
    starttime_sc = 0d
endelse
if (n_elements(stoptime) ne 0) then begin
    stoptime_sc = stoptime + (burstmjd - mjdrefi)*86400d - utcfinit
endif else begin
    stoptime_sc = 1d50
endelse

;; if we have multiple evtfiles, we must deal with them here
if not keyword_set(no_background) then begin
    if (keyword_set(use_avg_bk)) then begin
        xrt_avg_background,srcevts,bkrate,bkerr,scstart=starttime_sc,scstop=stoptime_sc
    endif
endif else begin
    bkrate = 0.0
    bkerr = 0.0
endelse

if n_elements(orbgti) gt 1 then begin
    ;; check if we have out-of-order crazy gti
    starts=orbgti.start-orbgti[0].start
    stops=orbgti.stop-orbgti[0].start
;;    shiftstarts=shift(starts,-1)
    shiftstops=shift(stops,1)
    shiftstops[0]=starts[0]
    delta=starts-shiftstops
    good=where(delta ge 0.0,ngood)
    if (ngood eq 0) then begin
        print,'Problem with orbital gti!'
        return
    endif
    orbgti=orbgti[good]
endif



;; if (n_elements(gtifile) eq 0 an then begin
if n_elements(orbgti) eq 0 then begin
    orbgti=create_struct('start', gti[0].start, $
                         'stop',max(evt.time))
;;    norb=1
    if (starttime_sc gt orbgti.start) then orbgti.start = starttime_sc
    if (stoptime_sc lt orbgti.stop) then orbgti.stop = stoptime_sc
endif else if (norb eq 0) then begin
    tempgti=orbgti
;;    tempgti=mrdfits(gtifile,1)
    orbgti=create_struct('start',tempgti[0].start, $
                         'stop',tempgti[n_elements(tempgti)-1].stop)
    if (starttime_sc gt orbgti.start) then orbgti.start = starttime_sc
    if (stoptime_sc lt orbgti.stop) then orbgti.stop = stoptime_sc

endif else begin
;;    tempgti=mrdfits(gtifile,1)
    tempgti=orbgti

    if (n_elements(tempgti) ge norb) then begin
        orbgti = tempgti[0:norb-1]
        orbgti[norb-1].stop = tempgti[n_elements(tempgti)-1].stop
    endif else begin
        orbgti = tempgti
    endelse

    ;; this might have problems on certain bursts, but ok for now--- or not
    if (starttime_sc gt orbgti[0].start) then orbgti[0].start = starttime_sc
    if (stoptime_sc lt orbgti[n_elements(orbgti)-1].stop) then $
      orbgti[n_elements(orbgti)-1].stop = stoptime_sc

endelse

;; get the file ready
openw,lun,outfile,/get_lun

;; write the gamma and gamma-err for flux density calculations; or we can just
;; add that to the end of the lightcurve file.  Nah for now.
;;printf,lun,gamma,gamma_err


;; our starting time is the first time in the gti file...

;;if (n_elements(starttime) eq 0) then tstart=gti[0].start
;;if (n_elements(stoptime) eq 0) then lasttime=max(evt.time)

;;all_used = 0
;;while (not all_used) do begin

for j=0l,n_elements(orbgti)-1 do begin
    tstart = orbgti[j].start
    orbstop=orbgti[j].stop

    print,(mjdrefi + (orbgti[j].start + utcfinit)/86400. - burstmjd)*86400.,(mjdrefi + (orbgti[j].stop + utcfinit)/86400. - burstmjd)*86400.

    all_used = 0
    while (not all_used) do begin


;;        if (tstart gt 1.5870419e+08 and tstart lt 1.5870421e+08) then stop

;;    h=where(evt.time ge tstart, nposs)
        h=where(evt.time ge tstart and evt.time le orbstop, nposs)

        if (nposs le 2*ctsperbin) then begin
            ;; put the last one into the same bin as the previous one
            tstop=orbstop
            use=h
            nct=nposs
            all_used=1
        endif else begin
            tstop=evt[h[ctsperbin-1]].time+timedel
            use=where(evt.time ge tstart and evt.time le tstop, nct)
        endelse

        if (nposs gt 0) then begin
;;            print,(mjdrefi + (evt[use[0]].time + utcfinit)/86400. - burstmjd)*86400.
;;            print,(mjdrefi + (evt[use[n_elements(use)-1]].time + utcfinit)/86400. - burstmjd)*86400.
            
            ;; calculate the binsize [and modify tstart, tstop]
            binsize=0.0
            binstart=-1001.0
            binstop=binstart
            i=0
            done = 0
            while (i lt n_elements(gti) and not done) do begin
                ;; record intersect gtis?
                use_this_gti = 0
                ;; follow comments in (extractor) times.f
                if (gti[i].start le tstart and $
                    gti[i].stop ge tstart and $
                    gti[i].stop le tstop) then begin
                    use_this_gti = 1
                    binsize = binsize + gti[i].stop - tstart
                endif else if (gti[i].stop le tstart) then begin
                    use_this_gti = 0
                endif else if (tstop le gti[i].start) then begin
                    use_this_gti = 0
                    done = 1
                endif else if (gti[i].start ge tstart and $
                               gti[i].start le tstop and $
                               gti[i].stop ge tstop) then begin
                    use_this_gti = 1
                    binsize = binsize + tstop - gti[i].start
                endif else if (gti[i].start ge tstart and $
                               gti[i].start le tstop and $
                               gti[i].stop ge tstart and $
                               gti[i].stop le tstop) then begin
                    use_this_gti = 1
                    binsize = binsize + gti[i].stop - gti[i].start
                endif else if (gti[i].start le tstart and $
                               gti[i].stop ge tstop) then begin
                    use_this_gti = 1
                    binsize = binsize + tstop - tstart
                endif else begin
                    print,'ERROR: check programming.'
                endelse
                if (i eq n_elements(gti)-1) then begin
                    done = 1
                endif
                
;;                if (use_this_gti) then begin
;;                    print,gti[i].start-gti[0].start,gti[i].stop-gti[0].start,tstart-gti[0].start,tstop-gti[0].start
;;                endif

                if (use_this_gti and binstart lt -1000) then begin
                    ;; set the real start time
                    if (gti[i].start ge binstart) then binstart = gti[i].start
                    if (tstart ge binstart) then binstart = tstart
                endif
                if (done) then begin
                    ;; set the real stop time
                    if (i eq n_elements(gti)-1) then begin
                        if (tstop le gti[i].stop) then begin
                            binstop = tstop
                        endif else begin
                            binstop = gti[i].stop
                        endelse
                    endif else if (tstop ge gti[i-1].stop) then begin
                        binstop = gti[i-1].stop
                    endif else begin
                        binstop = tstop
                    endelse
                    



                endif
                i=i+1
            endwhile
    

            if (not keyword_set(use_avg_bk)) then begin
                if (n_elements(bkevt) eq 1) then begin
                    nbk = 0.0
                endif else begin
                    bkcnts=where(bkevt.time ge tstart and bkevt.time le tstop,nbk)
                endelse
                bkrate = (nbk / binsize)*bkareascale
                bkerr = (sqrt(nbk)/binsize)*bkareascale
;;                print,'background: ',bkrate,bkerr
            endif

            ;; calculate and output the values
            ;; the following will only work with pc mode; change later.
            rate = (nct / binsize) - bkrate
            err = sqrt((sqrt(nct)/binsize)^2. + bkerr^2.)
            tstart_burst = (mjdrefi + (binstart + utcfinit)/86400. - burstmjd)*86400.
            tstop_burst = (mjdrefi + (binstop + utcfinit)/86400. - burstmjd)*86400.
            tmid_burst = (tstop_burst+tstart_burst)/2.
            terr_burst = (tstop_burst-tstart_burst)/2.
            
            flux = rate*c
            temp=sqrt(((flux - rate*clo)/flux)^2. + (err/rate)^2.)
            flux_lo = flux - temp*flux
            temp=sqrt(((rate*chi - flux)/flux)^2. + (err/rate)^2.)
            flux_hi = flux + temp*flux

            if (gamma ne 0.0) then begin
;;                calculate_xray_jansky,flux,(flux_hi-flux_lo)/2.,gamma,gamma_err,enlo,enhi,xfd,xfde
                calculate_xray_jansky2,flux,flux_lo,flux_hi,gamma,gamma_err,enlo,enhi,xfd,xfd_lo,xfd_hi,ex=ex
            endif else begin
                xfd = 0.0
                xfd_lo = 0.0
                xfd_hi = 0.0
            endelse

            if (terr_burst) lt 0 then stop
;;            printf,lun,tmid_burst,terr_burst,rate,err,flux,flux_lo-flux,flux_hi-flux,xfd,xfde,format='(4d,5e)'
            printf,lun,tmid_burst,terr_burst,rate,err,flux,flux_lo-flux,flux_hi-flux,xfd,xfd_lo-xfd,xfd_hi-xfd,format='(4d,6e)'

        endif
    
        tstart = tstop

    endwhile

;;    if (all_used) then j = n_elements(orbgti) + 1

;;endwhile
endfor


free_lun,lun

if keyword_set(plot) then begin
    readcol,outfile,tmid,terr,rate,raterr,format='f,f,f,f',/silent
    yrange=[0.5*min(rate),max(rate)*2]
    if yrange[0] lt 0.0001 then yrange[0]=0.0001
    
    ploterror,tmid,rate,terr,raterr,psym=1,/xlog,/ylog,yrange=yrange,/nohat
endif



return
end
