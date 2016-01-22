FUNCTION relphot3_makemap, match, stat, npix
;+
; NAME:	RELPHOT3_MAKEMAP
;
; CALLING SEQUENCE:	relphot3_makemap, match, stat, npix
;
; INPUTS:	match: match structure 
; 		 stat: array of stats structures 
;                npix: size of grid spacing in pixels
;
; OUTPUTS:
;
; REVISION HISTORY: 
;     Created:   Don Smith     UM       10/31/01
;     Modified:  Eli Rykoff             02/23/04 - works with new/old match
;                                                  structures
;******************************************************************************
;-

  map = -1
  nthr_conf = 5

  if n_params() lt 3 then begin
      print,'syntax- relphot3_makemap(match, stat, npix)'
      return,-1
  endif else begin

;;  IF N_params() LT 3 THEN doc_library, 'relphot3_makemap' ELSE BEGIN 
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


    
; Generate list of objects to calibrate with.
      
      print, 'Generating template of good objects...'
;;      info=size(match.m)
;;      nobs = info[1]
;;      nobj = info[2]
      sat = intarr(nobs, nobj)
      bad_eflags = ['ATEDGE', 'SATURATED', 'APINCOMPL']
      merr_cut = 0.2
      template = make_array(nobj, /FLOAT, value = -1.0)
      FOR k = 0L, nobj-1L DO BEGIN
          sat[allobs,k] = check_flags3(bad_eflags, $
                                       match.flags[allobs,k],type='EFLAGS')
          goodobs = where(sat[allobs,k] EQ 0 AND $
                          match.m[allobs,k] LT 30.0 AND $
                          match.m[allobs,k] GT -1.0, count)
          okobs = where(match.m[allobs,k] GT -2.0, count2)
          IF (count GT 0.75*count2 and count ge 3) THEN template[k] = median(match.m[goodobs,k], /EVEN)
      ENDFOR
      goodobj = where(template NE -1.0, count)
      print, 'Number of good template objects = ', count
      IF (count NE 0) THEN BEGIN 
          
; Create and fill relative photometry map for each image
          naxis = max(stat.naxis1) > max(stat.naxis2)
          halfbox = npix/2.0
          map = make_map_struct(nobs,npix=npix,imsize=naxis)
          map.nthr = nthr_conf
          map.noise = merr_cut	; Maximum statistical error to allow a template object
          FOR i = 0, nobs-1 DO BEGIN
              print,'Mapping photometry for image:    ',match.imagename[i]
              magmax = stat[i].m_lim - map.noise
              astr_struct_new,1.85,astr
              astr.crval=[double(match.rac[i]),double(match.decc[i])]
              rd2xy,match.ra,match.dec,astr,xc,yc
              kx=reform(match.kx[i,*,*])
              ky=reform(match.ky[i,*,*])
              kmap,xc,yc,x,y,kx,ky
              
;   Find well-measured relative photometry offsets
              
              print, '  Obtaining well-measured offsets from good subframes'
              FOR nx = 0, map.nxbin-1 DO BEGIN 
                  xlow = nx*npix
                  xhigh = (nx+1)*npix
                  gdobj2 = where(x[goodobj] GE xlow AND x[goodobj] LT xhigh AND $
                                 sat[i,goodobj] EQ 0 AND match.m[i,goodobj] GT -1.0 $
                                 AND match.merr[i,goodobj] LT merr_cut AND $
                                 match.m[i,goodobj] LT 30.0, nobj2)
                  IF (nobj2 GE 3) THEN BEGIN
                      gdobj2 = goodobj[gdobj2]
                      FOR ny = 0, map.nybin-1 DO BEGIN
                          ylow = ny*npix
                          yhigh = (ny+1)*npix
                          k = where(y[gdobj2] GE ylow AND y[gdobj2] LT yhigh, nobj)
                          map.ntmp[i,nx,ny] = nobj
                          IF (map.ntmp[i,nx,ny] GE 3) THEN BEGIN
                              magdiff = template[gdobj2[k]] - match.m[i,gdobj2[k]]
                              map.offset[i,nx,ny] = median(magdiff, /EVEN)
                              map.sdv[i,nx,ny] = stddev(magdiff)
                              map.error[i,nx,ny] = map.sdv[i,nx,ny] / sqrt(map.ntmp[i,nx,ny])
                          ENDIF
                      ENDFOR 
                  ENDIF
              ENDFOR 
              
;   Find offsets in poorly measured subframes
              
              print, '  Determining offsets for bad subframes with good neighbors'
              FOR nx = 0, map.nxbin-1 DO BEGIN
                  minx = 0 > (nx-1)
                  maxx = (nx+1) < (map.nxbin-1)
                  iy = where(map.ntmp[i,nx,*] LE map.nthr, count) 
                  FOR q = 0, count-1 DO BEGIN
                      itmp = 0
                      IF (map.ntmp[i,nx,iy[q]] GE 3) THEN itmp = itmp + 1
                      miny = 0 > (iy[q]-1)
                      maxy = (iy[q]+1) < (map.nybin-1)
                      map.error[i,nx,iy[q]] = 0.5
                      map.sdv[i,nx,iy[q]] = 0.0
                      FOR m = minx, maxx DO $
                        FOR n = miny, maxy DO $
                        IF (map.ntmp[i,m,n] GT map.nthr) THEN BEGIN
                          map.offset[i,nx,iy[q]] = map.offset[i,nx,iy[q]] + map.offset[i,m,n]
                          map.error[i,nx,iy[q]] = map.error[i,nx,iy[q]] > map.error[i,m,n]
                          map.sdv[i,nx,iy[q]] = map.sdv[i,nx,iy[q]] > map.sdv[i,m,n]
                          itmp = itmp + 1
                      ENDIF
                      IF (itmp NE 0) THEN $
                        map.offset[i,nx,iy[q]] = map.offset[i,nx,iy[q]]/float(itmp)
                  ENDFOR
              ENDFOR
          ENDFOR 
      ENDIF
;   should try to perform a fit here in the future...

 ENDELSE 
 return, map
END
