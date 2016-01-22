PRO get_1stburstim_time, nframe, confcimg, confimgdir, imtime, resp_delay, error=error, delayerr=delayerr

;; program to find the first image in a series from a burst
;; response. ideally, it will look for image 001, read it, find its
;; start time. otherwise it will keep looking up to (MAX?)

;; it then looks for the time of it (imtime), and the delay of imtime
;; resp_delay relative to the trigger time (if trigger time is not set, it
;; returns as -99)

;; intended for the html burst info table (top of page of
;; burst_response/./) gets used by realtime_nocal (which can only be
;; called once, on 010) and by write_binary in realtime_burst when the
;; match structure has exactly 2 elements 

dirparts = strsplit(confcimg,'/',/extract)
base = confdir + '/' + dirparts[n_elements(dirparts)-1]

framemax = nframe

parts = strsplit(base,'_',/extract)
root = parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,2)

noframefound=1
error = 0
delayerr = 0
resp_delay = -99.9
mjd = -99.9


for i=1, framemax do begin
    if (noframefound) then begin
        file = root + string(i,format='(i3.3)')+'_c.fit'
        hdr = headfits(file,errmsg=errmsg)
        if (errmsg eq '') then begin
            noframefound = 0
            mjd = sxpar(hdr,'MJD')
            obstime = sxpar(hdr,'OBSTIME')
            pkt_t = sxpar(hdr,'PKT_T')
            trig_tjd = sxpar(hdr,'TRIG_TJD')

            if (pkt_t gt 0) and (obs_t gt 0) then begin
                if (trig_tjd gt 0) then begin
                    pkt_mjd = double(trig_tjd) + 40000.0d + pkt_t / (60d * 60d * 24d)
                endif else begin
                    pkt_mjd = double(floor(mjd)) + pkt_t / (60d * 60d *24d)
                endelse

                resp_delay = float((mjd - pkt_mjd) * 86400.0)
                if (resp_delay lt 0) then resp_delay = -99.9
            endif else begin
                resp_delay = -99.9
            endelse
        endif
    endif
endfor

if (mjd le 0) then error = -1
if (resp_delay lt 0) then delayerr = -1

return
end

