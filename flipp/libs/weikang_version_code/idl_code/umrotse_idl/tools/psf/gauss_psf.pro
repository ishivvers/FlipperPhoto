;*****************************************************************
;*                                                               *
;*      gauss_psf.pro                                            *
;*                                                               *
;*      GAUSS_PSF is a procedure that can be called via CURVEFIT *
;*      to fit a Gaussian point spread function to a two         *
;*      dimensional binned data array. The WXYZ parameter        *
;*      transmits the weights, pixel coordinates and amplitudes. *
;*      PARAMS contains the current values of the centroid and   *
;*      width. The results are returned in F and DF.             *
;*                                                               *
;*      Carl W. Akerlof                                          *
;*      Randall Laboratory of Physics                            *
;*      500 East University                                      *
;*      University of Michigan                                   *
;*      Ann Arbor, Michigan 48109                                *
;*                                                               *
;*      July 2, 2001                                             *
;*                                                               *
;*****************************************************************

PRO GAUSS_PSF, WXYZ, PARAMS, F, DF

if n_params() eq 0 then begin
    print,'syntax- GAUSS_PSF, WXYZ, PARAMS, F, DF'
    return
endif

W = WXYZ[*,0]
XY = WXYZ[*,1:2]
Z = WXYZ[*,3]
U = GAUSS_DERIV(XY, PARAMS)
M00 = TOTAL(W, /DOUBLE)
M01 = TOTAL(W*U[*,0], /DOUBLE)
M11 = TOTAL(W*U[*,0]^2, /DOUBLE)
DET = M00*M11 - M01^2
Q0 = TOTAL(W*Z, /DOUBLE)
Q1 = TOTAL(W*U[*,0]*Z, /DOUBLE)
P0 = (+M11*Q0 - M01*Q1)/DET
P1 = (-M01*Q0 + M00*Q1)/DET
F = P0 + P1*U[*,0]
DF = P1*U[*,1:3]
FOR I = 0, 2 DO BEGIN
   D_M01 = TOTAL(W*U[*,I+1], /DOUBLE)
   D_M11 = TOTAL(2.0D0*W*U[*,0]*U[*,I+1])
   D_Q1 = TOTAL(W*Z*U[*,I+1], /DOUBLE)
   D_DET = M00*D_M11 - 2.0D0*M01*D_M01
   D_P0 = (+D_M11*Q0 - D_M01*Q1 - M01*D_Q1)/DET - P0*D_DET/DET
   D_P1 = (-D_M01*Q0 + M00*D_Q1)/DET - P1*D_DET/DET
   DF[*,I] = DF[*,I] + D_P0 + D_P1*U[*,0]
ENDFOR
RETURN
END
