FUNCTION matchfieldcov, match, stat, mingood, box=box, fail=fail, nsig=nsig, template=template

;; field coverage (rough) from a match structure, with "mingood"
;; observations perobject. has to compromise on what the ZPoffset,
;; FWHM are. returns "template", the artificial gaussians in the zone,
;; if desired.

fail=0

deg2pix = 1107.03
pix2deg = 9.0332e-4

if n_params() lt 3 then begin
    print, 'syntax - result = matchfieldcov(match, stat, mingood, box=box, fail=fail, nsig=nsig)'
    return, 0
endif

if mingood LT 1 then mingood=1

;; sort out which are good enough - also removes the ngood=0 blank spaceholders
obj = where(match.ngood GE mingood)
notobj = where(match.ngood LT mingood)

;; have to check for saturated ones, use stat.sat_mag

tmpmax = ((size(match.flags, /dim))[0]-1) < 9
bestearly = where(match.m_lim[0:tmpmax] eq max(match.m_lim[0:tmpmax]))
tmpflags = reform(match.flags[bestearly,*])

satobj = where((tmpflags[notobj] GT 0) AND ((tmpflags[notobj] AND 4) GT 0))
if (min(satobj) GE 0) then obj = [obj,notobj[satobj]]

satval = min(stat.sat_mag)

if (min(obj) LT 0) then begin
    print, 'no objects match the ngood criterion'
    fail=1
    return, -1
endif

;; default is to look for 1-sigma
if n_elements(nsig) EQ 0 then nsig = 1.0
if nsig lt 0 then nsig = 0


pixrad = deg2pix*stat[0].trig_err

if not keyword_set(box) then circle=1 else circle=0

;; find list of stars near box: search radius + 3*FWHM

ww=where((stat.fwhm LT 6.) and (stat.fwhm gt 0.),nww)
if (nww eq 0) then pixfwhm=6. else pixfwhm = median([stat[ww].fwhm])

use_fwhm = pixfwhm*pix2deg

if (circle) then begin

    set = where( ( (match.ra[obj]-stat[0].trig_ra)^2 + (match.dec[obj]-stat[0].trig_dec)^2 ) LE (stat[0].trig_err+3.0*use_fwhm)^2 )

endif else begin

    set = where( (match.ra[obj] GE stat[0].trig_ra-stat[0].trig_err-3.0*use_fwhm) AND $
   (match.ra[obj] LE stat[0].trig_ra+stat[0].trig_err+3.0*use_fwhm) AND $
   (match.dec[obj] GE stat[0].trig_dec-stat[0].trig_err-3.0*use_fwhm) AND $
   (match.dec[obj] LE stat[0].trig_dec+stat[0].trig_err+3.0*use_fwhm) )

endelse

;print, set

if min(set) lt 0 then begin
    print, "no objects in the zone"
    return, 0.0
endif

;; start with a blank field, add obj[set]

;; convert ra, dec to x,y
kx=reform(match.kx[0,*,*]) & ky=reform(match.ky[0,*,*])

astr_struct_new,1.85,astr
astr.crval=[double(match.rac[0]),double(match.decc[0])]
rd2xy,stat.trig_ra,stat.trig_dec,astr,xc,yc
kmap,xc,yc,xa,ya, kx, ky
x=xa[0]
y=ya[0] ;; center, as on 1st match struc frame

if ((x lt 0) or (x gt 2048) or (y lt 0) or (y gt 2048)) then begin
    print, "probably no GRB trigger in match structure: trig is off the frame"
    fail=1
    return, -1
endif

;; now for the set of stars


rd2xy, match.ra[obj[set]], match.dec[obj[set]], astr, xc, yc
kmap,xc,yc,xstar,ystar, kx, ky

mag = match.mavg[obj[set]]
wtmp = where(mag LT 0)
if (min(wtmp) GT -1) then mag[wtmp] = satval

subsize = fix(2*pixrad)+1
template = fltarr(subsize,subsize)

;; note that the offsets are xstar-pixrad, ystar-pixrad to fit this

halfgaus = fix( (2.5*pixfwhm > 5) < 15. )
gaussize = 2*halfgaus+1
;print, cal.fwhm, gaussize

;; loop:

;; find a zeropt offset to use - median will eventually be "high", but
;;                               will be more of an average early on
;;                               5->20->60sec

zpoff = median(stat.zp_offset)
 
for ii=0, n_elements(xstar)-1 do begin

;; get a normalized Gaussian with the FWHM, centroided

    xpt = xstar[ii]-x
    ypt = ystar[ii]-y

    tmpgauss = psf_gaussian(fwhm=pixfwhm, centroid=[float(xpt+halfgaus-fix(xpt)),float(ypt+halfgaus-fix(ypt))], npixel=[gaussize,gaussize], /normalize, /double)

;; convert using mag = -2.5log(ADU) + ZP + ZPoffset

    totflux = 10.0^(-0.4*(mag[ii] - 23.0 - zpoff))

;; add it to the field

    tmpgauss = tmpgauss*totflux

;    template = template + tmpgauss*totflux
    for jj=0, gaussize-1 do begin &$
        for kk=0, gaussize-1 do begin &$
            dx = xpt + halfgaus - jj &$
            dy = ypt + halfgaus - kk &$
            if (abs(dx) lt pixrad) and (abs(dy) lt pixrad) then $
              template[pixrad+dx,pixrad+dy] = template[pixrad+dx,pixrad+dy]+$
              tmpgauss[jj,kk] &$
      endfor &$
    endfor

endfor

;; now find how many pixels in the field match the < radius criterion
;; find how many of these are < the threshold

thresh = nsig*median(stat.sexbkdev)

if (circle) then begin

    xstripe = intarr(subsize,subsize) 
    for jj=0, subsize-1 do xstripe[jj,*]=jj
    ystripe = intarr(subsize,subsize) 
    for jj=0, subsize-1 do ystripe[*,jj]=jj

    short = template[where( ((xstripe-pixrad)^2 + (ystripe-pixrad)^2) LE pixrad^2 )]

    npixtot = n_elements(short)
    npixhi = n_elements(where(short GE thresh))

endif else begin

;;    short = template[(x-pixrad):(x+pixrad), (y-pixrad):(y+pixrad)]
    short = template

    npixtot = n_elements(short)
    npixhi = n_elements(where(short GE thresh))

endelse

cov = float(npixhi)/npixtot


return, cov

end


