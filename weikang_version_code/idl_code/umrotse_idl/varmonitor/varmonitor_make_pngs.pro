pro varmonitor_make_pngs,basedir,root,varstr

if n_params() eq 0 then begin
    print,'syntax- varmonitor_make_pngs,basedir,root,varstr'
    return
endif

;; we will create a png for the whole time and recently

;; right now we won't do flag filtering, but this will probably want to be
;; added at some point, when we see how it works

mjd = systime(/julian)-2400000.5d
datestr=systime()

;; do the whole lightcurve

full_fname=basedir + '/' + 'vm_' + root + '_flc.png'

times=varstr.jd - mjd
mags=varstr.m
magerrs=varstr.merr
xtitle='Days from '+datestr

h=where(magerrs lt 0,nlim)
if (nlim gt 0) then mags[h] = varstr.m_lim[h]

;;Run program to find significant change in brightness
varmonitor_make_bright,varstr,brightindex,dimindex


simple_lc_png,full_fname,times,mags,magerrs,dim=[600,300],xtitle=xtitle,colorindex1=brightindex,colorindex2=dimindex

;; do the past week lightcurve

lweek_fname=basedir + '/' + 'vm_' + root + '_wlc.png'

lweek=where(times gt -7,nlweek)

if (nlweek gt 0) then begin
    ;; this should always be true...

if (brightindex[0] ge 0) then begin
    brtarr=bytarr(n_elements(times))
    brtarr[brightindex] = 1
    brightindex = where(brtarr[lweek] eq 1, nwb)
endif else begin
    brightindex = -1
endelse
if (dimindex[0] ge 0) then begin
    dimarr=bytarr(n_elements(times))
    dimarr[dimindex] = 1
    dimindex=where(dimarr[lweek] eq 1, nwd)
endif else begin
    dimindex = -1
endelse

    simple_lc_png,lweek_fname,times[lweek],mags[lweek],magerrs[lweek],dim=[600,300],xtitle=xtitle,xrange=[-7.5,0.5],colorindex1=brightindex,colorindex2=dimindex
endif




return
end
