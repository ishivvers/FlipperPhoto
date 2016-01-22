pro realtime_auto_counterpart,mt,st

if n_params() eq 0 then begin
    print,'syntax- realtime_auto_counterpart,mt,st'
    return
endif

print,''
print,'=====BEGINNING AUTO COUNTERPART SEARCH======'

;; this program is a separate auto-counterpart checker.  It will send out
;; e-mail to register a GCN circular

;;fname_path='~/'
fname_path='/rotse/data/pipeline/'


;; set cuts
min_ecliptic_lat = 5.0
min_galactic_lat = 20.0
max_delay_time = 300.0  ;; must be a response in < 300s from trigger
min_delta_mag_peak = 0.3 ;; hmmm...
max_bright_mag = 16.0 ;; must be brighter than (16th) mag
max_cam_temp = -17.0
max_error_box = 0.07
max_pos_sigma = 0.35  ;; position sigma cut for 5-s images
max_dmoon = 20.0      ;; if the moon is up and close, that's bad
min_elev = 20.0       ;; minimum elevation for detection

;; check observations
if (mt.nobs eq 2) then begin
    nobs = 2
    minobs = 2
endif else if (mt.nobs eq 10) then begin
    nobs = 10
    minobs = 5
endif else begin
    print,'Wrong number of frames for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endelse

;; check the camera temp (warm camera = extra stars)

test=where(st.camtemp gt max_cam_temp,ntest)
if (ntest gt 0) then begin
    print,'Camera temperature too warm for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

;; get the ra/dec/time
ra=st[0].trig_ra
dec=st[0].trig_dec
err=st[0].trig_err
trig_t=st[0].trig_t
obstime=st[0].obstime
trignum=st[0].trig_num
pos_sigmas = st.pos_sigma
dmoon=st[0].dmoon
lphase=st[0].lphase
elev=st[0].elev

;; check obstime
delta_t=obstime-trig_t
if (delta_t gt max_delay_time or delta_t lt 0.0 or trig_t eq 0.0) then begin
    print,'Delay too large for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

;; check error box
if (err gt max_error_box) then begin
    print,'Error box too large for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

;; check pos sigmas
test=where(pos_sigmas gt max_pos_sigma,ntest)
if (ntest gt 0) then begin
    print,'Bad position sigma detected in auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
end

;; check the moon
if (lphase gt 0.0 and dmoon lt max_dmoon) then begin
    print,'Too close to moon for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
end

;; check the elevation
if (elev lt min_elev) then begin
    print,'Elevation too low for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
end

;; check the coordinates
euler,ra,dec,gl,gb,1
euler,ra,dec,el,eb,3

if (abs(gb) lt min_galactic_lat) then begin
    print,'Galactic latitude too low for auto counterpart:',gb
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

if (abs(eb) lt min_ecliptic_lat) then begin
    print,'Ecliptic latitude too low for auto counterpart:',eb
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

;; are there any saturated stars around?
sat=where((mt.flags and 4) gt 0 and mt.flags gt 0,nsat)
if (nsat gt 0) then begin
    print,'Saturated star detected in error box'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif
  


;; use usnoA2.0 (for now)

usnoread2,ra,dec,1.1*err/cos(!dpi*dec/180.),ucat

;; all the objects that are in (2) or (5) observations

use1=where(mt.ngood ge minobs,nuse1)

if (nuse1 eq 0) then begin
    print,'No objects with enough good observations for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

;; only want objects within the error box
gcirc,1,ra/15d,dec,mt.ra[use1]/15d,mt.dec[use1],dis

use2=where(dis lt err*3600.0,nuse2)

if (nuse2 eq 0) then begin
    print,'No objects in the error box for auto counterpart'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

use=use1[use2]

;; match to usno -- patch to make sure the 0-index bug can't bite us

close_match_radec,[-1.0,mt.ra[use]],[-1.0,mt.dec[use]],ucat.ra,ucat.dec,m1,m2,0.0009d*3d,1,miss,/silent

;; note: we can allow matches if something is much much brighter than the USNO
;; star, so we can't kick out of the miss section

;; check misses
cand=-1
delta_mag = 0.0
bright_mag = 0.0
if n_elements(miss) eq 2 then begin
    ;; note we have one that is the placeholder.  If there is more than one
    ;; real miss, then something might be wrong, and we don't want to send out
    ;; an auto-notice


    cand=use[miss[1]-1]

    print,'Found a candidate counterpart at:'
    print,mt.ra[cand],mt.dec[cand]

    ;; check to make sure it's bright enough (where it was detected)
    det=where(mt.m[*,cand] gt 0.0 and mt.flags[*,cand] lt 4,ndet)

    if (ndet lt minobs) then begin
        print,'Bug: candidate object with no good observations'
        cand=-1
    endif 

    if (cand ne -1) then begin
        staruse=where(mt.ngood eq mt.nobs)
        bright_mag=min(mt.m[det,cand],ind)
        
        delta_mag=mt.m_lim[det[ind]]-mt.m[det[ind],cand]

        if (bright_mag gt max_bright_mag) then begin
            print,'Brightest magnitude not bright enough for auto counterpart:',bright_mag
            cand=-1
        endif
        
        if (delta_mag lt min_delta_mag_peak) then begin
            print,'Brightest magnitude not bright enough relative to mlim for auto counterpart:',delta_mag
            cand=-1
        endif
    endif
endif else if (n_elements(miss) gt 2) then begin
    print,'More than one miss: something wrong?  No auto counterpart detection performed.'
    print,'=====END AUTO COUNTERPART SEARCH===='
    return
endif

;; and the USNO matches...this is a bit more contraversial, so I'll leave it
;; off for now (will we want to write this?)

if (cand ne -1) then begin
    print,'Auto-counterpart detector found a new bright object at:'
    print,mt.ra[cand],mt.dec[cand]
    
    ;; recalculate just in case
    det=where(mt.m[*,cand] gt 0.0 and mt.flags[*,cand] lt 4,ndet)
    bright_mag=min(mt.m[det,cand],ind)
    merr=sqrt(mt.merr[det[ind],cand]^2.+0.02^2.)
    
    print,'mag:',mt.m[det[ind],cand],'+/-',merr

    ;; make the filename
    fname=fname_path+'auto_'+strtrim(string(st[0].trig_num,format='(i)'),2)+'.txt'
    
    test=findfile(fname,count=ct)
    if (ct gt 0) then begin
        print,'Notice already sent for this burst!'
        print,'=====END AUTO COUNTERPART SEARCH===='
        return
    endif

    ;; calculate the confidence
    if (delta_mag gt 1.0 and bright_mag lt 15.0) then begin
        confidence = 90.
        print,'High confidence counterpart: ',confidence
    endif else begin
        confidence=70.
        print,'Lower confidence counterpart: ',confidence
    endelse

    ;; make the text to send
    format_gcn_counterpart,fname,st[det[ind]].mjd,mt.ra[cand],mt.dec[cand],$
      mt.m[det[ind],cand],merr,trignum,confidence,test=test

    ;; now we'll need a program to send it...for the moment we'll just cat it
    cmd='mail -s "GRB_COUNTERPART_SUBMISSION" "vxw@capella.gsfc.nasa.gov,rotse_prompt@umich.edu" < ' + fname
;;    cmd='mail -s "GRB_COUNTERPART_SUBMISSION" "yuanfang@umich.edu" < ' + fname
    print,cmd

    if (test eq 0) then begin
        spawn,cmd
        print,'cmd sent'
    endif else begin
        print,'Cmd not sent: only a test'
    endelse


    print,'Output of text sent:'
    cmd='cat '+fname
    spawn,cmd


endif else begin
    print,'Auto-counterpart detector did not find a counterpart candidate'
endelse

print,'=====END AUTO COUNTERPART SEARCH===='



return
end
