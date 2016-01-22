FUNCTION aeta_lambda, z, omegamat

  s3 = (1.-float(omegamat))/omegamat
  s = s3^(1./3.)
  s2 = s^2
  s4 = s^4
  a = 1./(1.+float(z))

  c0 = 1.
  c1 = -.1540
  c2 = .4304
  c3 = .19097
  c4 = .066941
  
  ex = -1./8.

  return, 2.*sqrt(s3+1.)*( c0/a^4 + c1*s/a^3 + $
                           c2*s2/a^2 + c3*s3/a +c4*s4)^ex
END 

FUNCTION angdist_lambda, z, h=h, omegamat=omegamat, verbose=verbose, $
                  plot=plot, oplot=oplot, dlum=dlum

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    ANGDIST_LAMBDA
;       
; PURPOSE: 
;    calculate angular diameter from 0 to z in lambda universe
;    Uses approximation.  for z between 0.2 and 1.0 the error
;    is about .4%
;	
;
; CALLING SEQUENCE: 
;    result = angdist(z1, z2, h=h, omegamat=omegamat, verbose=verbose, 
;                     plot=plot, oplot=oplot )
;      
; INPUTS:  
;    z: redshift
;
; OPTIONAL INPUTS: 
;    h: hubble parameter       default is .7
;    omegamat:  omega matter   default is .3
;
; OPTIONAL KEYWORDS: 
;    /verbose:  print distances.
;    /plot:     make a plot
;    /oplot:    overplot
;       
; OUTPUTS: distance in megaparsecs.
;
; REVISION HISTORY: 
;    Author: Erin Scott Sheldon 2/24/99
;	
;       
;                                      
;-                                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if N_params() eq 0 then begin
	print,'-Syntax: result = angdist(z [, h=h, omegamat=omegamat, verbose=verbose, plot=plot, oplot=oplot, dlum=dlum] )'
	print,'   Returns Angular diameter Distance in Mpc from 0 to z'
        print,'   in a flat lambda cosmology.'
        print,'   (assumes omega = 1 = omegamat + omegalambda)'
        print,'   default is omegamat=.3   h=.7'
	return,0.
  endif

IF NOT keyword_set(h) THEN h=0.7
IF NOT keyword_set(omegamat) THEN omegamat=.3

;;;;;;;; some parameters  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

c = 2.9979e5                  ;;  speed of light in km/s
H0 = 100.0*h                  ;;  hubbles constant in km/s/Mpc

fac = c/H0*(1.+z)

dlum = fac*( aeta_lambda(0., omegamat) - aeta_lambda(z, omegamat) )
dang = dlum/(1.+z)^2


IF keyword_set(verbose) THEN BEGIN
  print,'-----------------------------------'
  print,'Using h = ',ntostr(h),'  omega matter = ',ntostr(omegamat)
  print,'Ang Diameter Dist to z='+ntostr(z)+'= '+ntostr(dang),' Mpc'
  print,'-----------------------------------'
ENDIF

IF keyword_set(plot) THEN BEGIN
  xtitle='Z'
  ytitle='dang (Mpc)'
  plot, z, dang,xtitle=xtitle,ytitle=ytitle
  return,dang
ENDIF 

IF keyword_set(oplot) THEN oplot, z, dang

return,dang
END

