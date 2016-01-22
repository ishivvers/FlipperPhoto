function relphot_makemap, match, stat, npix
;+
; NAME:	relphot_makemap
;
; CALLING SEQUENCE:	relphot_makemap, match, stat, npix
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;		stat: structure of observation information
;
; OUTPUTS:	npix: size of grid spacing in pixels
;
; Created: 00-04-11 Bob Kehoe -- based loosely on rel_photo and relphoto_map by 
;				 Tim McKay
; Updated: 06-05-00 Bob Kehoe -- improved template selection, sped up mapmaking,
;				 added filling of blank areas, other mods.
; Updated: 06-13-00 Eli Rykoff - template objects must now have a statistical
;				 error < 0.1. # templates in a subregion must be > 5
; Updated: 08-16-00 Bob Kehoe -- ensure that mag > 30 objects rejected as templates
;******************************************************************************
;-

 if N_params() lt 3 then begin
    print,'Syntax - relphot_makemap, match, stat, npix'
    return, -1
 endif

; Generate list of objects to calibrate with.

 print, 'Generating template of good objects...'
 info=size(match.m)
 nobs = info[1]
 nobj = info[2]
 sat = intarr(nobs, nobj)
 bad_eflags = ['ATEDGE', 'SATURATED', 'APINCOMPL']
 merr_cut = 0.1
 template = make_array(nobj, /FLOAT, value = -1.0)
 for k = 0L, nobj-1L do begin
    sat[*,k] = check_flags(bad_eflags,match.flags[*,k],type='EFLAGS')
    goodobs = where(sat[*,k] eq 0 and match.m[*,k] lt 30.0 and match.m[*,k] gt -1.0, $
			count)
    okobs = where(match.m[*,k] gt -2.0, count2)
    if (count gt 0.75*count2) then template[k] = median(match.m[goodobs,k], /EVEN)
 endfor
 goodobj = where(template ne -1.0, count)
 print, 'Number of good template objects = ', count
 if (count eq 0) then return, -1

; Create and fill relative photometry map for each image
 naxis = max(stat.naxis1) > max(stat.naxis2)
 halfbox = npix/2.0
 map = make_map_struct(nobs,npix=npix,imsize=naxis)
 map.nthr = 5
 map.noise = merr_cut	; Maximum statistical error to allow a template object
 for i = 0, nobs-1 do begin
    print,'Mapping photometry for image:    ',match.imagename[i]
    magmax = stat[i].m_lim - map.noise
    convert2xy, match.ra, match.dec, xc, yc, $
		rac=match.rac[i], decc=match.decc[i]
    kx=reform(match.kx[i,*,*])
    ky=reform(match.ky[i,*,*])
    kmap,xc,yc,x,y,kx,ky

;   Find well-measured relative photometry offsets

    print, '  Obtaining well-measured offsets from good subframes'
    for nx = 0, map.nxbin-1 do begin 
       xlow = nx*npix
       xhigh = (nx+1)*npix
       gdobj2 = where(x[goodobj] ge xlow and x[goodobj] lt xhigh and $
		sat[i,goodobj] eq 0 and match.m[i,goodobj] gt -1.0 $
		and match.merr[i,goodobj] lt merr_cut and $
		match.m[i,goodobj] lt 30.0, nobj2)
       if (nobj2 ge 3) then begin
          gdobj2 = goodobj[gdobj2]
          for ny = 0, map.nybin-1 do begin
	     ylow = ny*npix
	     yhigh = (ny+1)*npix
	     k = where(y[gdobj2] ge ylow and y[gdobj2] lt yhigh, nobj)
	     map.ntmp[i,nx,ny] = nobj
       	     if (map.ntmp[i,nx,ny] ge 3) then begin
	        magdiff = template[gdobj2[k]] - match.m[i,gdobj2[k]]
	        map.offset[i,nx,ny] = median(magdiff, /EVEN)
                map.sdv[i,nx,ny] = stddev(magdiff)
                map.error[i,nx,ny] = map.sdv[i,nx,ny] / sqrt(map.ntmp[i,nx,ny])
             endif
          endfor
       endif
    endfor

;   Find offsets in poorly measured subframes

    print, '  Determining offsets for bad subframes with good neighbors'
    for nx = 0, map.nxbin-1 do begin
       minx = 0 > (nx-1)
       maxx = (nx+1) < (map.nxbin-1)
       iy = where(map.ntmp[i,nx,*] le map.nthr, count) 
       for q = 0, count-1 do begin
	  itmp = 0
	  if (map.ntmp[i,nx,iy[q]] ge 3) then itmp = itmp + 1
	  miny = 0 > (iy[q]-1)
	  maxy = (iy[q]+1) < (map.nybin-1)
	  map.error[i,nx,iy[q]] = 0.5
	  map.sdv[i,nx,iy[q]] = 0.0
	  for m = minx, maxx do begin
	     for n = miny, maxy do begin
		if (map.ntmp[i,m,n] gt map.nthr) then begin
		   map.offset[i,nx,iy[q]] = map.offset[i,nx,iy[q]] + map.offset[i,m,n]
		   map.error[i,nx,iy[q]] = map.error[i,nx,iy[q]] > map.error[i,m,n]
		   map.sdv[i,nx,iy[q]] = map.sdv[i,nx,iy[q]] > map.sdv[i,m,n]
		   itmp = itmp + 1
		endif
	     endfor
	  endfor
	  if (itmp ne 0) then map.offset[i,nx,iy[q]] = map.offset[i,nx,iy[q]]/float(itmp)
       endfor
    endfor

;   should try to perform a fit here in the future...

 endfor

 return, map
end











