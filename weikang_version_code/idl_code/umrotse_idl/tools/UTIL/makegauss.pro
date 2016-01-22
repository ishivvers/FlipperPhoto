pro makegauss, gauss, siz, sigma, fwhm=fwhm, counts=counts, aratio=aratio, $
               theta=theta, cen=cen

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME: 
;    makegauss
;
; PURPOSE: 
;    make an array with values set to a gaussian
;    Dave J.  My changes E.S.S.
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF n_params() LT 2 THEN BEGIN 
    print,'-Syntax makegauss, gauss, siz, sigma, fwhm=fwhm, counts=counts, aratio=aratio, theta=theta, cen=cen'
    print,'sigma is in wide direction if aratio < 1.0'
    print,'Theta in degrees.'
    return
  ENDIF


  ;; check some parameters

  IF n_elements(fwhm) NE 0 THEN BEGIN
    sigma = 0.42466091*fwhm
  ENDIF ELSE IF n_elements(sigma) EQ 0 THEN BEGIN
    print,'You must specify fwhm or sigma'
    return
  ENDIF

  IF n_elements(counts) EQ 0 THEN counts=1.
  IF n_elements(theta) EQ 0 THEN theta = 0.0

  sx=long(siz(0))
  sy=long(siz(1))
  IF n_elements(cen) EQ 0 THEN cen=[(sx-1.)/2.,(sy-1.)/2.]
  cx=cen(0)
  cy=cen(1)


  gauss=fltarr(sx,sy)
  index=lindgen(sx*sy)

  x=index MOD sx
  y=index/sx
 
  IF n_elements(aratio) EQ 0 THEN BEGIN 
    xp=x-cx   &  yp=y-cy
  ENDIF ELSE BEGIN 
    aratio=aratio > .1
    ct=cos(theta*!Pi/180.)
    st=sin(theta*!Pi/180.)
    xp=(x-cx)*ct + (y-cy)*st
    yp=((cx-x)*st + (y-cy)*ct)/aratio
  ENDELSE 

  rr=(1.0/2.0/sigma^2)*(xp^2+yp^2)
  w=where(rr lt 10.8,cat)      ;watch floating point underflow
                                ;this will allow ~.00002 as smallest number
                                ;in disk
  IF cat GT 0 THEN BEGIN 
    gauss(index(w))=exp(-rr(w)) 
    gauss = counts/total(gauss)*gauss
  ENDIF 


  return 
END





