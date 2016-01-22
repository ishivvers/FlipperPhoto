pro apply_relphot, match, stat, map, mode, new
;+
; NAME:	apply_relphot
;
; CALLING SEQUENCE:	apply_relphot, match, stat, map, mode, new
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;		stat: structure of observation information
;
; OUTPUTS:	map: array of offsets for each image
;		mode: whether or not to perform linear interpolation (=1)
;		newmatch: copy of match calibrated to the USNO information
;			  then with relative photometry between observations
;
; PROCEDURE:	Does observation-to-observation photometry of objects
;
; Created: 00-04-11 Bob Kehoe -- based loosely on rel_photo and relphoto_map by Tim McKay
; Updated: 06-05-00 Bob Kehoe -- allow linear interpolation, set photometry flags, other 
;				 modifications
;******************************************************************************
;-

 if N_params() lt 4 then begin
    print,'Syntax - apply_relphot, match, stat, map, mode, newmatch'
    return
 endif

; Initialization

 info=size(match.m)
 nobs = info[1]
 nobj = info[2]
 npix = map.npix
 nxbin = map.nxbin
 nybin = map.nybin
 halfbox = npix/2.0
 mp = fltarr(4)
 wt = fltarr(4)
 new = match

;   Interpolate offset map and apply relative photometry correction.
;   Reference points taken as corners of box around source [x,y].  When 
;   at edge of field, ranges of NX and NY must be limited.

 for i = 0, nobs-1 do begin
    print,'Applying relative photometry to objects in image:  ',new.imagename[i]
    convert2xy, new.ra, new.dec, xc, yc, rac=new.rac[i], decc=new.decc[i]
    kx=reform(new.kx[i,*,*])
    ky=reform(new.ky[i,*,*])
    kmap,xc,yc,x,y,kx,ky
    j = where(x ge 0 and x lt stat[i].naxis1 and y ge 0 and $
	y lt stat[i].naxis2 and new.m[i,*] gt 0.0 and $
	new.m[i,*] lt 30.0, count)
    if (mode eq 0) then begin
       for k = 0L, count-1L do begin
          nx = fix(x[j[k]]-halfbox)/npix < (nxbin-1)
          ny = fix(y[j[k]]-halfbox)/npix < (nybin-1)
          new.m[i,j[k]] = new.m[i,j[k]] + map.offset[i,nx,ny]
	  new.msys[i,j[k]] = byte(200.0*sqrt((new.msys[i,j[k]]/200.0)^2.0 +$
				 map.error[i,nx,ny]^2.0))
  	  if (map.ntmp[i,nx,ny] le map.nthr) then $
		new.rflags[i,j[k]] = set_flags('NOTEMPL', old=new.rflags[i,j[k]], type='RFLAGS')
	  if (map.sdv[i,nx,ny] gt 0.1) then $
		new.rflags[i,j[k]] = set_flags('PHOTSDEV', old=new.rflags[i,j[k]], type='RFLAGS')
       endfor
    endif else begin
       for k = 0L, count-1L do begin
          nx = fix(x[j[k]]-halfbox)/npix < (nxbin-1)
          ny = fix(y[j[k]]-halfbox)/npix < (nybin-1)
          nxbc = fix(x[j[k]]+halfbox)/npix < (nxbin-1)
          nycd = fix(y[j[k]]+halfbox)/npix < (nybin-1)
          mp[0] = map.offset[i,nx,ny]
          mp[1] = map.offset[i,nxbc,ny]
          mp[2] = map.offset[i,nxbc,nycd]
          mp[3] = map.offset[i,nx,nycd]
          dx = x[j[k]] - float(nx*npix+halfbox)
          dy = y[j[k]] - float(ny*npix+halfbox)
          wt[0] = (npix-dx)*(npix-dy)
          wt[1] = dx*(npix-dy)
          wt[2] = dx*dy
          wt[3] = (npix-dx)*dy
          new.m[i,j[k]] = new.m[i,j[k]] + total(mp*wt)/float(npix)^2
	  ix = nx
	  iy = ny
          if (dx gt halfbox) then begin
	     ix = nxbc
	     if (dy gt halfbox) then iy = nycd
	  endif else if (dy gt halfbox) then iy = nycd

	  new.msys[i,j[k]] = byte(200.0*sqrt((new.msys[i,j[k]]/200.0)^2.0 +$
				map.error[i,ix,iy]^2.0))

  	  if (map.ntmp[i,ix,iy] le map.nthr) then begin
		new.rflags[i,j[k]] = set_flags('NOTEMPL', old=new.rflags[i,j[k]], type='RFLAGS')
	  endif
	  if (map.sdv[i,ix,iy] gt 0.1) then $
		new.rflags[i,j[k]] = set_flags('PHOTSDEV', old=new.rflags[i,j[k]], type='RFLAGS')
       endfor
    endelse
 endfor
 new = create_struct(new, 'map', map)


 return
end











