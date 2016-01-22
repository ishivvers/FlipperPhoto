PRO realtime_nocal, ustat, conf

; PROGRAM: REALTIME_NOCAL
;
; SYNTAX: realtime_nocal, ustat, bdir
;
; INPUTS: ustat: the stat structure (from sobj stage) for the pacman
;                subject
;         bdir: the directory where binary files are to be written
;
; PURPOSE: when there is no image that can calibrate during a burst
; response, this creates a jpeg of the non-calibrating image. It also 
; makes a binary file for the burst information table (...btab.html)
; should only be done on exactly frame 010.
;
; follows the methods of realtime_match.pro, write_binary.pro
;
; REVISION HISTORY:
;     Created: Sarah Yost  UM   02/11/05
; ===================================================================


if n_params() eq 0 then begin
    print, 'syntax- realtime_nocal, ustat, bdir'
    return
endif

bdir = conf.bindir
imdir = conf.imgdir

;; do jpg
parts = str_sep(ustat.fname,'_')
nroot=parts[1]+'_'+strmid(parts[2],0,2)
nameroot=nroot+'nocal.jpg'
filename = bdir + '/' + nameroot 


newname = find_rotse3_image(ustat.fname,fail=fail,path=imdir)
if (fail eq 0) then begin
    img = readfits(newname,head)


    zimg = float(img)
    set_plot, 'z'
    !p.multi = 0
    device, set_resolution=[200,200]
    save_ppos = !p.position
    !p.position = [0,0,199,199]
    sky,zimg,mean,sigma,/silent
    rlow = mean-sigma
    rhigh = mean+5*sigma
    tvim2,zimg,/noframe,range=[rlow,rhigh]
    print, 'Writing jpeg ', filename
    xyouts,0.5,0.95,nameroot,charsize=0.8,alignment=0.5,/norm
    write_jpeg, filename, tvrd()

    !p.position = save_ppos

endif else print, "Unable to find image for .jpg" ;

;; do the binary, writing in dummies as needed

fname=bdir+'/'+nroot+'nocal.bin'

emask=28 & rmask=9 & nobj=0l 

astrom_score=0
ntimes=1

openw,lun,fname,/get_lun

if (lun lt 0) then begin
    fail = 1
    return
endif


;;stop

use_tjd = 0
if (tag_exist(ustat,'trig_tjd')) then begin
    if (ustat.trig_tjd gt 10000) then use_tjd = 1
endif

;; now, we have trig_t in seconds of day...
if (use_tjd) then begin
    burst_mjd = double(ustat.trig_tjd) + 40000.0d + ustat.trig_t / (60d * 60d * 24d)
endif else begin
    ;; assume the burst happened the same day as the image
    burst_mjd = double(floor(ustat.mjd)) + ustat.trig_t / (60d * 60d * 24d)
endelse

;; this gets the ecliptic & Galactic long/lat
bstat = burstfield_stats(ustat.trig_ra, ustat.trig_dec, burst_mjd)

writeu,lun,ustat.trig_ra,ustat.trig_dec,float(ustat.trig_err),burst_mjd

writeu,lun,float(bstat.g_long), float(bstat.g_lat), $
       float(bstat.e_long), float(bstat.e_lat), $
       float(bstat.extinction)

writeu,lun,long(ntimes),long(nobj)

off_t=float(ustat.mjd - burst_mjd)

;; new line: 1st image's time.

get_1stburstim_time, ustat.nframe, conf.cimg, conf.imgdir, first_time, resp_delay, error=error

if (abs(error) gt 1e-5) then first_offset = off_t else first_offset = float(first_time - burst_mjd)


writeu,lun,first_offset
writeu,lun,float(resp_delay)

;;dummy field coverage
writeu,lun,-1.0

;; dummy stuff: offset & lim mag
matmlim=0.0

writeu,lun,off_t,matmlim

;; the rest shouldn't be done for nobj=0

free_lun,lun



return
end
