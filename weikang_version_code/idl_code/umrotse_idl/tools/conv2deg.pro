function conv2deg,arcsec
;+
; NAME: conv2deg
;
; CALLING SEQUENCE:     conv2deg,byteword
;
; INPUTS:       byteword: byte variable which contains the arcseconds level delta 
;			scaled to the plate scale.
;
; Return Value: value in degrees.
;
; Created:  5-31-00  Bob Kehoe
;******************************************************************************

if N_params() lt 1 then begin
   print, 'Syntax conv2deg,byteword'
   return, -1
endif

  pixscale = 14.4
  renorm = 2.0*pixscale/255.0
  val = renorm*float(arcsec) - pixscale
  val = val/3600.0

  return,val
end