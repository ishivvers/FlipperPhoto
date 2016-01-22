FUNCTION  lumdist, z, h=h, omegamat=omegamat, verbose=verbose, plot=plot,oplot=oplot

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    LUMDIST
;       
; PURPOSE:
;    calculate luminosity distance
;    Currently only works for lambda = 0 universe.  See angdist_lambda.
;	
;
; CALLING SEQUENCE: 
;    result = lumdist(z, h=h, omegamat=omegamat, verbose=verbose, $
;                   plot=plot,oplot=oplot)
;      
; INPUTS:  
;    z: redshift
;
; OPTIONAL INPUTS: 
;    h: hubble parameter      default .7
;    omegamat:  omega matter  default 1.
;       
; OUTPUTS: 
;   dist in Mpc.
;
; REVISION HISTORY: Erin Scott Sheldon 2/24/99
;	
;       
;                                      
;-                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if N_params() eq 0 then begin
	print,'Syntax: result = lumdist(z [, h=h, omegamat=omegamat, verbose=verbose])'
	print,'Returns luminosity distance in Mpc'
        print,'Use doc_library, "lumdist" for more help.'
	return, 0.
  endif
;;;;;;;;;;;;;;;;;;  check keywords  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (not keyword_set(h)) then h=0.7

if (not keyword_set(omegamat)) then omegamat=1.0

;;;;;;;; some parameters  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

c = 2.9979e5                      ;;  speed of light in km/s
q0 = omegamat/2.0                 ;;  deceleration parameter 
H0 = 100.0*h                      ;;  hubbles constant in km/s/Mpc

;;;;;;;; calculate distances  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dlum = c*(q0*z + (q0 -1)*( sqrt(1 + 2*q0*z) - 1) )/H0/q0^2

IF keyword_set(verbose) THEN BEGIN 
  print,'-----------------------------------'
  print,'Using h = ',ntostr(h),'  omega matter = ',ntostr(omegamat)
  print,'Luminosity distance: ',ntostr(dlum),' Mpc'
  print,'-----------------------------------'
ENDIF 


IF keyword_set(plot) THEN BEGIN
  xtitle='Z'
  ytitle='Luminosity Distance (Mpc)'
  plot, z, dlum,xtitle=xtitle,ytitle=ytitle
  return, dlum
ENDIF 

IF keyword_set(oplot) THEN oplot,z,dlum

return, dlum
end
	
















