;******************************************************************************
;*                                                                            *
;*      iqd.pro                                                               *
;*                                                                            *
;*      "iqd" computes the inter-quartile difference for an array. There are  *
;*  three optional parameters: DOUBLE, MEDIAN, and STD_DEV. DOUBLE forces a   *
;*  floating point conversion for the returned result. If the parameter,      *
;*  MEDIAN, is equated to a variable, a value is returned for the median. If  *
;*  the parameter, STD_DEV, is set, the value of the standard deviation as    *
;*  estimated by the inter-quartile difference is returned instead of the     *
;*  IQD, assuming an approximately Gaussian distribution.                     *
;*                                                                            *
;*              Carl W. Akerlof                                               *
;*              Randall Laboratory of Physics                                 *
;*              450 Church Street                                             *
;*              University of Michigan                                        *
;*              Ann Arbor, Michigan  48109                                    *
;*                                                                            *
;*              August 4, 2006                                                *
;*                                                                            *
;******************************************************************************

FUNCTION IQD, X, DOUBLE=D, MEDIAN=Q, STD_DEV=S
N=N_ELEMENTS(X)
IF (N LT 2) THEN BEGIN
   PRINT, 'IQD: insufficient sample size ', N
   RETURN, -1L
ENDIF
IX=SORT(X)
M=N MOD 4
R=N/4
CASE M OF
   0: BEGIN
         DEL=2*(X[IX[N-R-1]]+X[IX[N-R]]-X[IX[R]]-X[IX[R-1]])
      END
   1: BEGIN
         DEL=3*(X[IX[N-R-1]]-X[IX[R]])+(X[IX[N-R]]-X[IX[R-1]])
      END
   2: BEGIN
         DEL=4*(X[IX[N-R-1]]-X[IX[R]])
      END
   3: BEGIN
         DEL=(X[IX[N-R-2]]-X[IX[R+1]])+3*(X[IX[N-R-1]]-X[IX[R]])
      END
ENDCASE
IF (KEYWORD_SET(D) OR KEYWORD_SET(S)) THEN BEGIN
   DEN=4.0D0
ENDIF ELSE BEGIN
   DEN=4
ENDELSE
IF (ARG_PRESENT(Q)) THEN BEGIN
   M=N MOD 2
   R=N/2
   CASE M OF
      0: BEGIN
            Q=2*(X[IX[R-1]]+X[IX[R]])/DEN
         END
      1: BEGIN
            Q=4*X[IX[R]]/DEN
         END
   ENDCASE
ENDIF
IF (KEYWORD_SET(S)) THEN BEGIN
   DEN=4.0D0*(GAUSS_CVF(0.250D0)-GAUSS_CVF(0.750D0))
ENDIF
RETURN, DEL/DEN
END
