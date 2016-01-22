;*****************************************************************
;*                                                               *
;*      parquet.pro                                              *
;*                                                               *
;*      "parquet.pro" computes the lattice and weights for a     *
;*      Simpson's Rule quadrature over a rectangular area. The   *
;*      area is partitioned into NX x NY unit squares, defining  *
;*      the integration mesh size. The procedure returns the     *
;*      weights and lattice coordinates.                         *
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

PRO PARQUET, NX, NY, W, X, Y
NT = 2*NX*NY + NX +NY +1
IW = LONARR(NT)
IX = LONARR(NT)
IY = LONARR(NT)
IB = [0L,1L,2*NX+1L,2*NX+2L]
IW[IB] = 1
IW[NX+1L:2*NX] = 8
FOR I = 1L, NX-1L DO BEGIN
   IW[I+IB] = IW[I+IB] + 1L
ENDFOR
IB = LINDGEN(2*NX+1L)
IC = LINDGEN(NX+1L)
FOR I = 2L, NY DO BEGIN
   IW[(2*NX+1L)*(I-1L)+IB] = IW[(2*NX+1L)*(I-1L)+IB]+IW[IB]
   IW[(2*NX+1L)*I+IC] = IW[IC]
ENDFOR
IX[NX+1L:2*NX] = 1L + 2*LINDGEN(NX)
IY[NX+1L:2*NX] = 1L
IB = LINDGEN(NX+1L)
FOR I = 0L, NY DO BEGIN
   IX[(2*NX+1L)*I+IB] = 2*IB
   IY[(2*NX+1L)*I+IB] = 2*I
ENDFOR
IB = LINDGEN(NX)
FOR I = 0L, NY-1L DO BEGIN
   IX[(2*NX+1L)*I+IB+NX+1L] = 1L + 2*IB
   IY[(2*NX+1L)*I+IB+NX+1L] = 1L + 2*I
ENDFOR
W = DOUBLE(IW)/DOUBLE(12*NX*NY)
X = DOUBLE(IX)/DOUBLE(2*NX)
Y = DOUBLE(IY)/DOUBLE(2*NY)
RETURN
END

PARQUET, 3L, 2L, IW, IX, IY
PRINT, 'IW', IW
PRINT, 'IX', IX
PRINT, 'IY', IY
PRINT, 'W sum: ', TOTAL(IW)
END