function make_map_struct, nobs, npix=npix, imsize=imsize
;+
; NAME:	make_map_struct
;
; CALLING SEQUENCE:	make_map_struct, nobs, npix=npix, imsize=imsize
;
; INPUTS:	nobs: number of observations
;
; Keywords:	npix: size of grid spacing
;		imsize: total size of image
;
; Return Value: map structure
;
; Created: 05-23-00 Bob Kehoe
;*********************************************************

 if N_params() eq 0 then begin
    print,'Syntax - make_map_struct, nobs, npix=npix, imsize=imsize'
    return, -1
 endif

   if not keyword_set(npix) then npix = 100
   if not keyword_set(imsize) then imsize = 2050
   nxbin = imsize/npix + (imsize mod npix < 1)
   nybin = imsize/npix + (imsize mod npix < 1)
   nxbin = fix(nxbin)
   nybin = fix(nybin)
   off = make_array(nobs,nxbin,nybin, /FLOAT, value = 0.0)
   err = make_array(nobs,nxbin,nybin, /FLOAT, value = 0.0)
   num = make_array(nobs,nxbin,nybin, /LONG, value = 0)
   sdv = make_array(nobs,nxbin,nybin, /FLOAT, value = 0.0)
   map = create_struct('npix', npix, 'nxbin', nxbin, 'nybin', nybin, 'nthr', -1, $
		'noise', -1.0, 'offset', off, 'error', err, 'ntmp', num, 'sdv',sdv)

   return, map
end