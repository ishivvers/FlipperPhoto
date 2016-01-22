FUNCTION angdist, zmax, zmin, h=h, omegamat=omegamat, verbose=verbose, $
                  plot=plot, oplot=oplot

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    ANGDIST
;       
; PURPOSE: 
;    calculate angular diameter distance between zmin and zmax
;    Currently only works for lambda = 0 universe.
;	
;
; CALLING SEQUENCE: 
;    result = angdist(z1, z2, h=h, omegamat=omegamat, $
;                     silent=silent, plot=plot, oplot=oplot )
;      
; INPUTS:  
;    zmax: max redshift 
;
; OPTIONAL INPUTS:
;    zmin:  Zmin is optional, the default is 0.0
;
; OPTIONAL KEYWORDS: 
;    h: hubble parameter in units of H100 default is .7
;    omegamat:  omega matter default is 1.
;
; OUTPUTS: 
;    dist in MPC
;
; REVISION HISTORY: 
;    Author: Erin Scott Sheldon 2/24/99
;	   
;                                      
;-                                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if N_params() eq 0 then begin
	print,'-Syntax: result = angdist(zmax [, zmin, h=h, omegamat=omegamat, silent=silent, plot=plot, oplot=oplot] )'
	print,'   Returns Angular diameter Distance in Mpc from zmin to zmax'
        print,'   for a matter only universe.'
	return,0.
  endif

IF n_elements(zmin) EQ 0 THEN zmin = 0.
IF NOT keyword_set(h) THEN h=0.7
IF NOT keyword_set(omegamat) THEN omegamat=1.0

;;;;;;;; some parameters  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

c = 2.9979e5                  ;;  speed of light in km/s
H0 = 100.0*h                  ;;  hubbles constant in km/s/Mpc

fac = 2.*c/H0
dang = sqrt(1.+omegamat*zmin)*( 2.-omegamat*(1.-zmax) ) - $
                               sqrt(1.+omegamat*zmax)*( 2.-omegamat*(1.-zmin) )
dang = dang*fac/( omegamat^2*(1.+zmax)^2*(1.+zmin) )

IF keyword_set(verbose) THEN BEGIN
  print,'-----------------------------------'
  print,'Using h = ',ntostr(h),'  omega matter = ',ntostr(omegamat)
  print,'Ang Diameter Dist between z='+ntostr(zmin)+ $
    ' and z='+ntostr(zmax)+': ',ntostr(dang),' Mpc'
  print,'-----------------------------------'
ENDIF

IF keyword_set(plot) THEN BEGIN
  xtitle='Z'
  ytitle='dang (Mpc)'
  plot, zmax, dang,xtitle=xtitle,ytitle=ytitle
  return,dang
ENDIF 

IF keyword_set(oplot) THEN oplot, zmax, dang

return,dang
END

