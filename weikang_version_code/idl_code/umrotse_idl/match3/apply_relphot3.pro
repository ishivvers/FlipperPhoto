PRO apply_relphot3, match, stat, map, mode, new
;+
; NAME:	APPLY_RELPHOT3
;
; CALLING SEQUENCE:	apply_relphot3, match, stat, map, mode, new
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;		stat: structure of observation information
;
; OUTPUTS:	map: array of offsets for each image
;		mode: whether or not to perform linear interpolation (=1)
;		new: copy of match calibrated to the USNO information
;			  then with relative photometry between observations
;
; PROCEDURE:	Does observation-to-observation photometry of objects
;                Adapted from APPLY_RELPHOT  
;
; REVISION HISTORY:
;       Created:        Don Smith         UM          10/31/01
;                       Eli Rykoff  02/23/04 -- works with new/old match strs
;******************************************************************************
;-

if n_params() lt 4 then begin
    print,'syntax - apply_relphot3, match, stat, map, mode, new'
    return
endif else begin

 ;;IF N_params() LT 4 THEN doc_library, 'apply_relphot3' ELSE BEGIN 

; Initialization

   ;;  info=size(match.m)
   ;;  nobs = info[1]
   ;;  nobj = info[2]
    if tag_exist(match,'nobs') then begin
        allobs = lindgen(match.nobs)
        allobj = lindgen(match.nobj)
        nobs = match.nobs
        nobj = match.nobj
    endif else begin
        allobs = lindgen(n_elements(match.jd))
        allobj = lindgen(n_elements(match.ra))
        nobs = n_elements(match.jd)
        nobj = n_elements(match.ra)
    endelse

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

     FOR i = 0, nobs-1 DO BEGIN
         print,'Applying relative photometry to objects in image:  ',new.imagename[i]
         astr_struct_new,1.85,astr
         astr.crval=[double(new.rac[i]),double(new.decc[i])]
;;         rd2xy,new.ra,new.dec,astr,xc,yc
         rd2xy,new.ra[allobj],new.dec[allobj],astr,xc,yc
         kx=reform(new.kx[i,*,*])
         ky=reform(new.ky[i,*,*])
         kmap,xc,yc,x,y,kx,ky
         j = where(x GE 0 AND x LT stat[i].naxis1 AND y GE 0 AND $
               ;;    y LT stat[i].naxis2 AND new.m[i,*] GT 0.0 AND $
               ;;    new.m[i,*] LT 30.0, count)
                   y lt stat[i].naxis2 and new.m[i,allobj] gt 0.0 and $
                   new.m[i,allobj] lt 30.0, count)
         IF (mode EQ 0) THEN BEGIN
             FOR k = 0L, count-1L DO BEGIN
                 nx = fix(x[j[k]]-halfbox)/npix < (nxbin-1)
                 ny = fix(y[j[k]]-halfbox)/npix < (nybin-1)
                 new.m[i,j[k]] = new.m[i,j[k]] + map.offset[i,nx,ny]
                 IF (map.ntmp[i,nx,ny] LE map.nthr) THEN $
                   new.rflags[i,j[k]] = set_flags3('NOTEMPL', old=new.rflags[i,j[k]], type='RFLAGS') $
                 ELSE $
                   new.msys[i,j[k]] = byte(200.0*sqrt((new.msys[i,j[k]]/200.0)^2.0 +$
                                                    map.error[i,nx,ny]^2.0))
                 IF (map.sdv[i,nx,ny] GT 0.1) THEN $
                   new.rflags[i,j[k]] = set_flags3('PHOTSDEV', old=new.rflags[i,j[k]], type='RFLAGS')
             ENDFOR
         ENDIF ELSE BEGIN
             FOR k = 0L, count-1L DO BEGIN
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
                 IF (dx GT halfbox) THEN BEGIN
                     ix = nxbc
                     IF (dy GT halfbox) THEN iy = nycd
                 ENDIF ELSE IF (dy GT halfbox) THEN iy = nycd

                 IF (map.ntmp[i,ix,iy] LE map.nthr) THEN $
                   new.rflags[i,j[k]] = set_flags3('NOTEMPL', old=new.rflags[i,j[k]], type='RFLAGS') $
                 ELSE $
                   new.msys[i,j[k]] = byte(200.0*sqrt((new.msys[i,j[k]]/200.0)^2.0 +$
                                                    map.error[i,ix,iy]^2.0))

                 IF (map.sdv[i,ix,iy] GT 0.1) THEN $
                   new.rflags[i,j[k]] = set_flags3('PHOTSDEV', old=new.rflags[i,j[k]], type='RFLAGS')
             ENDFOR
         ENDELSE
     ENDFOR
 ENDELSE 
END

