function calc_vignetting, x, y
;+
; NAME: Calculate Vignetting
;
; PURPOSE:
;	Determine the vignetting at given CCD points
;
; CALLING SEQUENCE:
;       delta = calc_vignetting(x,y)
;
; INPUTS:
;	x:		x-coordinates
;	y:		y-coordinates
;
; RETURN VALUE: 
;	delta:  	sensitivity offset 
; 
; REVISION HISTORY:
;	Bob Kehoe	UM	11/30/00
;-
 On_error,2              ;Return to caller

 if N_params() lt 2 then begin
    print, 'Syntax:         delta = calc_vignetting(x,y)'
    return, -1
 endif

 midx = median(x)
 midy = median(y)
 radius = sqrt((x-midx)^2.0 + (y-midy)^2.0)
 delta = 0.2 - 0.4*(radius/1500.0)^2.0

 return, delta
end


