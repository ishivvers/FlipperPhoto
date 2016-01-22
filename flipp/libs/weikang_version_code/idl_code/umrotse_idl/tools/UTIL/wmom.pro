PRO wmom, array, sigma, wmean, wsig, wmerr, wsigerr, wmerrerr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;    WMOM
;
; PURPOSE:
;    Find mean and sigma of an array, weighting by the standard
;         deviation of each point
;
; CALLING SEQUENCE: 
;    wmom, array, sigma, wmean, wsig, werr, wvar=wvar
;
; PROCEDURE: 
;    wi      = 1/sig[i]^2
;    wmean   = sum( xi*wi)/sum(wi)
;    wsig^2  = sum( wi*(xi-wmean)^2 )/sum(wi)
;            
;    wmerr^2 = sum( wi^2*(xi - wmean)^2 ) / ( sum(wi) )^2
;
; REVISION HISTORY:
;    Author: Erin Scott Sheldon UofMich  8/99
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


IF n_params() LT 2 THEN BEGIN 
  print,'-Syntax: wmom, array, sigma, wmean, wsig, wmerr'
  return
ENDIF

g=where(sigma GT 0.0, ng)

w = ( 1./sigma[g]^2 )
wtot = total(w)

wmean = total(w*array[g])/wtot

; Weighted variances:
; My formulas

; Uncertainty in the mean.
wmvar = total( w^2*(array[g] - wmean)^2 )/wtot^2
wmerr = sqrt(wmvar)

; Uncertainty in the Uncertainty in the mean
wmvarerr = .5*4.*total( w^4*(array[g] - wmean)^2*sigma[g]^2 )/wtot^4
wmerrvar = wmvarerr/4./wmvar
wmerrerr = sqrt( wmerrvar )


; Variance about the mean.
wvar = total( w*(array[g] - wmean)^2)/wtot
wsig=sqrt(wvar)

; Uncertainty in the variance.  The .5 is to make up for some error
; Because it reduces to sigma/sqrt(N) instead of sigma/sqrt(2N)

wvarvar = .5*4.0*total( w*(array[g] - wmean)^2 )/wtot^2
wsigvar = wvarvar/4./wvar
wsigerr = sqrt(wsigvar)

return
END
