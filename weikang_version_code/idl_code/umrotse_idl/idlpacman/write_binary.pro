pro write_binary, mat, stats, obj_arr, usno_dist, usno_mag, $
                  var_flags, var_score, fname, fail=fail,rmask=rmask,emask=emask,notjd=notjd, astrom_score=astrom_score, first_time=first_time, resp_delay=resp_delay, fieldcovfrac=fieldcovfrac

;; updating to include the ability to send in the delay
;; packet-response and the time of the 1st burst image

;; also the field coverage fraction

if n_params() lt 4 then begin
    print,'syntax- write_binary, mat, stats, obj_arr, usno_dist, usno_mag, var_flags, var_score, fname,fail=fail,rmask=rmask,emask=emask,notjd=notjd,astrom_score=astrom_score, first_time=first_time, resp_delay=resp_delay, fieldcovfrac=fieldcovfrac'
    return
endif



fail=0
nobj = n_elements(obj_arr)

if (n_elements(emask) eq 0) then begin
    emask = 28
endif
if (n_elements(rmask) eq 0) then begin
    rmask = 9
endif

if (nobj gt 0) then begin
    if (obj_arr[0] eq -1) then nobj = 0l
endif

if (n_elements(astrom_score) eq 0) and (nobj gt 0) then begin
    astrom_score = fltarr(nobj)
endif

if tag_exist(mat,'nobs') then begin
    allobs = lindgen(mat.nobs)
    allobj = lindgen(mat.nobj)
    ntimes = mat.nobs
endif else begin
    allobs = lindgen(n_elements(mat.jd))
    allobj = lindgen(n_elements(mat.ra))
    ntimes = n_elements(mat.jd)
endelse


openw,lun,fname,/get_lun

if (lun lt 0) then begin
    fail = 1
    return
endif

use_tjd = 0
if (tag_exist(stats[0],'trig_tjd') and (not keyword_set(notjd))) then begin
    if (stats[0].trig_tjd gt 10000) then use_tjd = 1
endif

;; now, we have trig_t in seconds of day...
if (use_tjd) then begin
    burst_mjd = double(stats[0].trig_tjd) + 40000.0d + stats[0].trig_t / (60d * 60d * 24d)
    pkt_mjd = double(stats[0].trig_tjd) + 40000.0d + stats[0].pkt_t / (60d * 60d * 24d)
endif else begin
    ;; assume the burst happened the same day as the image
    burst_mjd = double(floor(stats[0].mjd)) + stats[0].trig_t / (60d * 60d * 24d)
    pkt_mjd = double(floor(stats[0].mjd)) + stats[0].pkt_t / (60d * 60d * 24d)
endelse

bstat = burstfield_stats(stats[0].trig_ra, stats[0].trig_dec, burst_mjd)

writeu,lun,stats[0].trig_ra,stats[0].trig_dec,float(stats[0].trig_err),burst_mjd
writeu,lun,float(bstat.g_long), float(bstat.g_lat), $
       float(bstat.e_long), float(bstat.e_lat), $
       float(bstat.extinction)

writeu,lun,long(ntimes),long(nobj)

;; insert first image's offset here


if n_elements(first_time) eq 0 then first_time = -1
if (first_time lt 0) then first_time = mat.jd[0]

first_offset = float(first_time - burst_mjd)

if n_elements(resp_delay) eq 0 then begin
    resp_delay = (first_time - pkt_mjd) * 86400.0
endif
if (resp_delay) lt 0 then resp_delay = -99.99



writeu,lun,float(first_offset)
writeu,lun,float(resp_delay)

;; and the field coverage, before getting to the variable-sizing

if not(keyword_set(fieldcovfrac)) then fieldcovfrac=-1.0

writeu,lun,float(fieldcovfrac)

for i=0l,ntimes-1 do begin
    off_t = float(mat.jd[i] - burst_mjd)
    writeu,lun,off_t,float(mat.m_lim[i])
endfor

for i=0l,nobj-1 do begin
    index = long(obj_arr[i])

    dra = float(mat.ra[index] - stats[0].trig_ra)
    ddec = float(mat.dec[index] - stats[0].trig_dec)
    
    ;;usno_flag = byte(usno_flags[i])
    usno_d = fix(usno_dist[i]*100.)
    usno_m = fix(usno_mag[i]*1000.)

    var_flag = byte(var_flags[i])
    var_s = fix(var_score[i]*10.)

    astrom_s = fix(astrom_score[i]*10.)

    extra_flags = byte(0)
    ;; check if any of the observations have the deblend flag set
    h=where(mat.m[*,index] gt 0,nfound)   ;; only use real observations
    if (nfound ne 0) then begin
        add_flag = max(check_flags3('BLENDED',mat.flags[h,index],type='EFLAGS') ne 0)
        if (add_flag) then extra_flags = extra_flags + 1b
        ;; and the saturated
        add_flag = max(check_flags3('SATURATED',mat.flags[h,index],type='EFLAGS') ne 0)
        if (add_flag) then extra_flags = extra_flags + 2b
    endif else begin
        print,'Wierd: no observations???'
    endelse

    writeu,lun,index,dra,ddec,usno_d,usno_m,var_flag,var_s,astrom_s,extra_flags

    for j=0l,ntimes-1 do begin
        if (((emask and mat.flags[j,index]) gt 0) or $
            ((rmask and mat.rflags[j,index]) gt 0)) then begin
            mtemp = fix(-1000)
            merrtemp = fix(-1000)
        endif else begin
            mtemp = fix(mat.m[j,index] * 1000.)
            merrtemp = fix(mat.merr[j,index]*1000.)
        endelse

        writeu,lun,mtemp,merrtemp
    endfor
    

endfor


free_lun,lun



return
end
