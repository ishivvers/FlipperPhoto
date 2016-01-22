;*******************************************************************************
;                                                                              *
; NAME:                                                                        *
;   EXTEND_GRID                                                                *
;                                                                              *
; PURPOSE:                                                                     *
;   Expand an n x m array to (2n + 1) x (2m +1) dimensions so that the larger  *
;   array can be interpolated by the IDL BILINEAR routine.                     *
;                                                                              *
; CALLING SEQUENCE:                                                            *
;   Result = EXTEND_GRID(C)                                                    *
;                                                                              *
; INPUT:                                                                       *
;   C:  A two-dimensional array.                                               *
;                                                                              *
; OUTPUT:                                                                      *
;   A two-dimensional array which extends the area over which the input array, *
;   C, can be interpolated via BILINEAR. The numerical type of the result is   *
;   set to be the same as the input.                                           *
;                                                                              *
;       Carl W. Akerlof                                                        *
;       Randall Laboratory of Physics                                          *
;       University of Michigan                                                 *
;       450 Church Street                                                      *
;                                                                              *
;       August 12, 2007                                                        *
;                                                                              *
;*******************************************************************************

FUNCTION SS_EXTEND_GRID, C
S=SIZE(C)
IF (S[0] NE 2) THEN BEGIN
   STOP, 'EXTEND_GRID error, inappropriate dimension: ', S[0]
ENDIF
T=S[S[0]+1]
I=WHERE(T EQ [1,2,3,4,5,6,9], NI)
IF (NI EQ 0) THEN BEGIN
   STOP, 'EXTEND_GRID error, inappropriate data type: ', T
ENDIF
ND=S[S[0]-1:S[0]]
NX=LINDGEN(ND[0]*ND[1]) MOD ND[0]
NY=LINDGEN(ND[0]*ND[1])/ND[0]
MXC=LINDGEN((ND[0]-1)*(ND[1]-1)) MOD (ND[0]-1)
MYC=LINDGEN((ND[0]-1)*(ND[1]-1))/(ND[0]-1)
MXX=LINDGEN(ND[0]*(ND[1]-1)) MOD ND[0]
MYX=LINDGEN(ND[0]*(ND[1]-1))/ND[0]
MXY=LINDGEN((ND[0]-1)*ND[1]) MOD (ND[0]-1)
MYY=LINDGEN((ND[0]-1)*ND[1])/(ND[0]-1)
LX=LINDGEN(2*ND[0]-1)+1
LY=LINDGEN(2*ND[1]-1)+1
KX=2*ND[0]
KY=2*ND[1]
JX=[0L,KX,0,KX]
JY=[0L,0L,KY,KY]
JXD=[+1,-1,+1,-1]
JYD=[+1,+1,-1,-1]
JX1=JX+JXD
JY1=JY+JYD
JX2=JX1+JXD
JY2=JY1+JYD
C_EXT=MAKE_ARRAY(2L*ND+1, TYPE=T)
C_EXT[2*NX+1,2*NY+1]=C[NX,NY]
C_EXT[2*MXC+2,2*MYC+2]=(C[MXC,MYC]+C[MXC+1,MYC]+C[MXC,MYC+1]+C[MXC+1,MYC+1])/4L
C_EXT[2*MXX+1,2*MYX+2]=(C[MXX,MYX]+C[MXX,MYX+1])/2L
C_EXT[2*MXY+2,2*MYY+1]=(C[MXY,MYY]+C[MXY+1,MYY])/2L
C_EXT[0,LY]=C_EXT[1,LY]+C_EXT[1,LY]-C_EXT[2,LY]
C_EXT[LX,0]=C_EXT[LX,1]+C_EXT[LX,1]-C_EXT[LX,2]
C_EXT[KX,LY]=C_EXT[KX-1,LY]+C_EXT[KX-1,LY]-C_EXT[KX-2,LY]
C_EXT[LX,KY]=C_EXT[LX,KY-1]+C_EXT[LX,KY-1]-C_EXT[LX,KY-2]
C_EXT[JX,JY]=4L*C_EXT[JX1,JY1]-2L*(C_EXT[JX1,JY2]+C_EXT[JX2,JY1])+C_EXT[JX2,JY2]
RETURN, C_EXT
END
