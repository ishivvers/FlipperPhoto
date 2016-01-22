pro xrt_avg_background,evtfiles,bkrate,bkerr,scstart=scstart,scstop=scstop,fail=fail,channels=channels

if n_params() eq 0 then begin
    print,'syntax- xrt_avg_background,evtfiles,bkrate,bkerr,scstart=scstart,scstop=scstop,fail=fail,channels=channels'
    return
endif

if n_elements(channels) ne 2 then channels=[0,1000]

bkgevtfiles=strarr(n_elements(evtfiles))
srcevtfiles=bkgevtfiles

for i=0l,n_elements(evtfiles)-1 do begin
    if (strpos(evtfiles[i],'-c') ge 0) then begin
        aparts=strsplit(evtfiles[i],'\.evt',/extract,/regex)
        parts=strsplit(aparts[0],'-',/extract)
        bkgevtfiles[i]=parts[0]+'-bkg-'+parts[2]+'-'+parts[3]+'-'+parts[4]+'.evt'
        srcevtfiles[i]=parts[0]+'-src-'+parts[2]+'-'+parts[3]+'-'+parts[4]+'-'+parts[5]+'.evt'
        
    endif else begin
        parts=strsplit(evtfiles[i],'-',/extract)
        bkgevtfiles[i]=parts[0]+'-bkg-'+parts[2]+'-'+parts[3]+'-'+parts[4]
        srcevtfiles[i]=parts[0]+'-src-'+parts[2]+'-'+parts[3]+'-'+parts[4]
    endelse

    if (i eq 0) then begin
        shdr=headfits(srcevtfiles[i],exten=1)
        sarea=sxpar(shdr,'NPIXSOU')
        bhdr=headfits(bkgevtfiles[i],exten=1)
        barea=sxpar(bhdr,'NPIXSOU')
        
        ratio=sarea/barea
    endif
endfor

fail=0
xrt_read_evts,bkgevtfiles,evt,gti,orbgti,parts[0],tstart,tstop,fail=fail
if (fail) then begin
    print,'Could not read background evtfiles'
    fail=1
    return
endif

;;evt=mrdfits(bkgevtfile,1)
;;gti=mrdfits(bkgevtfile,2)

;; use whole time range if not specified
if n_elements(scstart) eq 0 then scstart=gti[0].start
if n_elements(scstop) eq 0 then scstop=gti[n_elements(gti)-1].stop

tstart=scstart
tstop=scstop

i=0
done=0
binsize=0.0
binstart=-1001.0
binstop=binstart
while (i lt n_elements(gti) and not done) do begin
    use_this_gti = 0
    ;; follow comments in (extractor) times.f (also in xrt_fixedcts_lc)
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

cts=where(evt.time ge tstart and evt.time le tstop and $
          evt.pi ge channels[0] and evt.pi le channels[1],nct)

bkrate=(nct/binsize)*ratio
bkerr=(sqrt(nct)/binsize)*ratio

return
end
