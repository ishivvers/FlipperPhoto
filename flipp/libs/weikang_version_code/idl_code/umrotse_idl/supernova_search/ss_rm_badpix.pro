;*******************************************************************************
;*                                                                             *
;*      IMAGE_SUTURE.PRO                                                       *
;*                                                                             *
;*      "image_suture" replaces the IMAGE pixels listed in BADPIX_LIST with    *
;*  local averages obtained on 3 x 3 neighborhood. The pixels are computed     *
;*  from the boundaries of the BADPIX_LIST pixel clusters, working inwards     *
;*  until all values are determined.                                           *
;*                                                                             *
;*              Carl W. Akerlof                                                *
;*              Randall Laboratory of Physics                                  *
;*              450 Church Street                                              *
;*              University of Michigan                                         *
;*              Ann Arbor, Michigan  48109                                     *
;*                                                                             *
;*              November 6, 2007                                               *
;*                                                                             *
;*******************************************************************************

FUNCTION SS_RM_BADPIX, IMAGE, BADPIX
BADPIX_LIST=WHERE(BADPIX, N_BAD)
IF (N_BAD EQ 0L) THEN RETURN, IMAGE
NEWIMAGE=IMAGE
WT=[SQRT(0.5D0),1.0D0,SQRT(0.5D0),1.0D0,1.0D0,SQRT(0.5D0),1.0D0,SQRT(0.5D0)]
WTS=DBLARR(256)
POWER_2=[1,2,4,8,16,32,64,128]
BITS=INDGEN(256)
CNT=BYTARR(256)
FOR I = 0, 7 DO BEGIN
   IX=WHERE(2^I AND BITS, NIX)
   CNT[IX]=CNT[IX]+1
   WTS[IX]=WTS[IX]+WT[I]
ENDFOR
BITS=2^INDGEN(8)
SZ=SIZE(IMAGE)
NX=SZ[1]
NY=SZ[2]
MAP=LONARR(NX+2, NY+2)
MAP[0:NX+1,0]=-1L
MAP[0:NX+1,NY+1]=-1L
MAP[0,1:NY]=-1L
MAP[NX+1,1:NY]=-1L
X=(BADPIX_LIST MOD NX)+1L
Y=(BADPIX_LIST/NX)+1L
MAP[X,Y]=LINDGEN(N_BAD)+1L
XN=[[X-1],[X],[X+1],[X-1],[X+1],[X-1],[X],[X+1]]
YN=[[Y-1],[Y-1],[Y-1],[Y],[Y],[Y+1],[Y+1],[Y+1]]
N_PIX=N_BAD
REPEAT BEGIN
   U=(MAP[XN,YN] EQ 0)#POWER_2
   C=CNT[U]
   CMAX=MAX(C)
   IC=WHERE(C EQ CMAX, NC)
   FOR I = 0L, NC-1 DO BEGIN
      J=IC[I]
      UV=U[J]
      XI=REFORM(XN[J,*]-1)
      YI=REFORM(YN[J,*]-1)
      IXY=WHERE(BITS AND UV)
      NEWIMAGE[X[J]-1,Y[J]-1]=TOTAL(WT[IXY]*NEWIMAGE[XI[IXY],YI[IXY]])/WTS[UV]
   ENDFOR
   MAP[X[IC],Y[IC]]=0L
   U=BYTARR(N_PIX)
   U[IC]=1
   N_PIX=N_PIX-NC
   IF (N_PIX GT 0) THEN BEGIN
      IXY=WHERE(U EQ 0)
      X=X[IXY]
      Y=Y[IXY]
      XN=XN[IXY,*]
      YN=YN[IXY,*]
   ENDIF
ENDREP UNTIL (N_PIX EQ 0)
RETURN, NEWIMAGE
END
