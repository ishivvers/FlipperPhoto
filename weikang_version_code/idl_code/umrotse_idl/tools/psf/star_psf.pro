pro star_psf,image,fwhm,plot=plot,abc=abc,xfit=xfit,yfit=yfit

if n_params() eq 0 then begin
    print,'syntax- star_psf,imsub,fwhm,plot=plot,abc=abc,xfit=xfit,yfit=yfit'
    return
endif

if n_elements(image[*,0]) ne n_elements(image[0,*]) then begin
    print,'need a square aperture'
    return
endif

if (keyword_set(plot)) then $
  setupplot

n_window = n_elements(image[*,0])



W=1.0D0+DBLARR(N_WINDOW^2)
Z=REFORM(DOUBLE(IMAGE), N_WINDOW^2)
WXYZ=DBLARR(N_WINDOW^2, 4)



WXYZ[*,0]=W
WXYZ[*,1]=0.5D0+DOUBLE(LINDGEN(N_WINDOW^2) MOD N_WINDOW)
WXYZ[*,2]=0.5D0+DOUBLE(LINDGEN(N_WINDOW^2)/N_WINDOW)
WXYZ[*,3]=Z
Z_TOT=TOTAL(Z, /DOUBLE)
PARS=[TOTAL(WXYZ[*,1]*Z, /DOUBLE)/Z_TOT,                         $
      TOTAL(WXYZ[*,2]*Z, /DOUBLE)/Z_TOT,1.0D0]
ZC=CURVEFIT(WXYZ, Z, W, PARS, FUNCTION_NAME='gauss_psf',       $
            ITER=I, TOL=1.0D-4)
SIGMA = 1.0D0/SQRT(2.0D0*PARS[2])
U = GAUSS_DERIV(WXYZ[*,1:2], PARS)
M00 = TOTAL(W, /DOUBLE)
M01 = TOTAL(W*U[*,0], /DOUBLE)
M11 = TOTAL(W*U[*,0]^2, /DOUBLE)
DET = M00*M11 - M01^2
Q0 = TOTAL(W*Z, /DOUBLE)
Q1 = TOTAL(W*U[*,0]*Z, /DOUBLE)
P0 = (+M11*Q0 - M01*Q1)/DET
P1 = (-M01*Q0 + M00*Q1)/DET
FLUX = !DPI*P1/PARS(2)
FWHM = SIGMA*2.0D0*SQRT(2.0D0*ALOG(2.0D0))
FWHM_STR = 'FWHM = ' + STRTRIM(STRING(FWHM, FORMAT='(F10.3)'), 2)
;print,fwhm_str
;print, 'fit parameters:', P0, P1, PARS[0:1], SIGMA, I
;print, 'stellar flux:', FLUX

R2 = (WXYZ[*,1]-PARS[0])^2+(WXYZ[*,2]-PARS[1])^2
R = SQRT(R2)
INDX = SORT(R)
ZC = (ZC - P0)/(2.0D0*!DPI*P1*SIGMA^2)
ZD = (Z - P0)/(Z_TOT - DOUBLE(N_WINDOW^2)*P0)
ZCI = DBLARR(N_WINDOW^2+1)
ZDI = DBLARR(N_WINDOW^2+1)      ;
     

if keyword_set(plot) then begin
 
    FOR I = 1L, N_WINDOW^2 DO BEGIN
        ZCI[I]=ZCI[I-1]+ZC[INDX[I-1]]
        ZDI[I]=ZDI[I-1]+ZD[INDX[I-1]]
    ENDFOR
    ;killit
    if (keyword_set(abc)) then begin
        thetitle='ABC encircled energy distribution'
    endif else begin
        thetitle='ROTSE-III encircled energy distribution'
    endelse

    plot,[0.0],[0.0],/nodata,xrange=[0.0,max(r)],yrange=[0.0,1.0], $
         xtitle='radial distance (pixels)', ytitle='integral flux', $
         title=thetitle

    oplot,r[indx[lindgen(2*n_window^2)/2]], zdi[(lindgen(2*n_window^2)+1)/2], $
          color=!red
    ;;color=255L

    r_grid = (max(r)/100.0d)*dindgen(101)
    z_grid=1.0d - EXP(-0.5d*(r_grid/sigma)^2)
    oplot,r_grid,z_grid,color=!green    ;;color=255L*256L
    oplot,r[indx[lindgen(2*n_window^2)/2]], zci[(lindgen(2*n_window^2)+1)/2], $
          color=!blue
    ;;color=255L*256L*256L
    xs=0.4*!x.crange[0]+0.6*!x.crange[1]
    ys=0.2*!y.crange[0]+0.8*!y.crange[1]
    xyouts,xs,ys,fwhm_str


endif

xfit = (max(r)/100.0d)*dindgen(101)
yfit = 1.0d - exp(-0.5d*(xfit/sigma)^2.)


return
end
