;*****************************************************************
;*                                                               *
;*      gauss_deriv.pro                                          *
;*                                                               *
;*      GAUSS_DERIV computes the derivatives of a Gaussian point *
;*      spread function for the coordinates, XY, and the         *
;*      centroid and width parameters specified by PARAMS.       *
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

FUNCTION GAUSS_DERIV, XY, PARAMS

if n_params() eq 0 then begin
    print,'syntax- GAUSS_DERIV, XY, PARAMS'
    return,-1
endif

N = N_ELEMENTS(XY)/2
U = DBLARR(N, 4)
PARQUET, 8L, 8L, WP, XP, YP
FOR I = 0L, N-1 DO BEGIN
   XQ = XP + XY[I,0] - PARAMS[0]
   YQ = YP + XY[I,1] - PARAMS[1]
   RQ = XQ^2 + YQ^2
   SQ = EXP(-PARAMS[2]*RQ)
   U[I,0] = TOTAL(WP*SQ, /DOUBLE)
   U[I,1] = TOTAL(2.0D0*PARAMS[2]*WP*XQ*SQ, /DOUBLE)
   U[I,2] = TOTAL(2.0D0*PARAMS[2]*WP*YQ*SQ, /DOUBLE)
   U[I,3] = TOTAL(-WP*RQ*SQ, /DOUBLE)
ENDFOR

return,U

END
