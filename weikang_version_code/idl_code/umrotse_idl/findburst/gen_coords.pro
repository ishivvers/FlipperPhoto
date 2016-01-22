pro gen_coords, st, seed, ra, dec, x, y
;+
; NAME: Generate Coordinates
;
; PURPOSE:
;	Generate a set of sky and CCD coordinates.
;
; CALLING SEQUENCE:
;       gen_coords, stat, seed, ra, dec, x, y
;
; Inputs and Outputs:
;	st:		stats structure for updating of coordinates
;	seed:		seed for random number generation
;
; Outputs:
;	ra:		source right ascension
;	dec:		dec
;	x:  		x-coordinate on CCD
;	y:		y-coordinate
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	11/29/00
;-
 On_error,2              ;Return to caller

 if N_params() lt 6 then begin
    print, 'Syntax:  gen_coords, st, seed, ra, dec, x, y'
    return
 endif

 nobj = (size(ra))[1]
 user_settings, rac=rac, decc=decc, fov=fov, naxis1=naxis1, naxis2=naxis2
 st.rac = rac
 st.decc = decc
 st.fov = fov
 st.naxis1 = naxis1
 st.naxis2 = naxis2
 x = float(naxis1)*randomu(seed,nobj)
 y = float(naxis2)*randomu(seed,nobj)
 deg2rad = 3.1415927/180.0
 dec = decc + (fov*y/float(naxis2))-(fov/2.0)
 ra = rac + ((fov*x/float(naxis1))-(fov/2.0))/cos(dec*deg2rad)

 return
end


