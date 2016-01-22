;*******************************************************************************
;                                                                              *
;       lin_check.pro                                                          *
;                                                                              *
;       Carl W. Akerlof                                                        *
;       Randall Laboratory of Physics                                          *
;       500 East University                                                    *
;       University of Michigan                                                 *
;       Ann Arbor, Michigan  48109                                             *
;                                                                              *
;                                                                              *
;                                                                              *
;       November 17, 2002                                                      *
;                                                                              *
;*******************************************************************************

FUNCTION LIN_CHECK, SEARCH_STRING, output_file, READ_NOISE, ADU_CALIB
IQD=GAUSS_CVF(0.25D0)-GAUSS_CVF(0.75D0)
IF (N_ELEMENTS(READ_NOISE) EQ 0) THEN READ_NOISE=1.94D0
IF (N_ELEMENTS(ADU_CALIB) EQ 0) THEN ADU_CALIB=4.23D0
DNX=2048L
NXA=53L
NXB=NXA+DNX
DNY=2048L
NYA=2L
NYB=NYA+DNY
N_PIX=DNX*DNY
DATA_FILES=SEARCH_STRING
REPEAT BEGIN
   FILE_LIST=FINDFILE(DATA_FILES, COUNT=N_FILES)
ENDREP UNTIL (N_FILES GT 0)
FILE_LIST=FILE_LIST[SORT(FILE_LIST)]
INTEN_CODE=STRARR(N_FILES)
T=DBLARR(N_FILES)
FOR I = 0, N_FILES-1 DO BEGIN
  ; NS=STRPOS(FILE_LIST[I], DATE_STRING, /REVERSE_SEARCH)
  ; ns=strpos(file_list[i], 
  ; S=STRMID(FILE_LIST[I], NS)
  ; NS=STRPOS(S, '_')+3
  ; INTEN_CODE[I]=STRMID(S, NS, 1)
  ; T[I]=FIX(STRMID(S, NS+1, 3))
    parts=str_sep(file_list[i], '_')
    inten_code[i]=strmid(parts[1],2,1)
    t[i]=fix(strmid(parts[1],3,3))
    print,inten_code[i],t[i]
ENDFOR
INTEN_CNT=LONARR(N_FILES)
J=0L
FOR I = 1, N_FILES-1 DO BEGIN
   IF (INTEN_CODE[I] NE INTEN_CODE[I-1]) THEN J=J+1L
   INTEN_CNT[I]=J
ENDFOR
N_INTEN=J+1L
INTEN_CNT[0]=-1L
;
;       Find average pixels
;
IMAGE=READFITS(FILE_LIST[N_FILES-1], /SILENT)
IMAGE=REFORM(IMAGE[NXA:NXB-1,NYA:NYB-1], N_PIX)
ISTAT=IQUARTILE(IMAGE)
N_LO=ISTAT[0]/4
N_HI=(ISTAT[2]+3)/4
INDXA=WHERE((IMAGE GE N_LO) AND (IMAGE LE N_HI), N_INDXA)
IMAGE=READFITS(FILE_LIST[N_FILES-2], /SILENT)
IMAGE=REFORM(IMAGE[NXA:NXB-1,NYA:NYB-1], N_PIX)
ISTAT=IQUARTILE(IMAGE)
N_LO=ISTAT[0]/4
N_HI=(ISTAT[2]+3)/4
IMAGE=IMAGE[INDXA]
INDXB=WHERE((IMAGE GE N_LO) AND (IMAGE LE N_HI), N_INDXB)
DN_INDX=N_INDXB/50L
INDX=INDXA[INDXB[0:50L*DN_INDX-1L]]
INDXA=0B
INDXB=0B
;
;       Compute pixel sums
;
PIX_SUM=DBLARR(51, N_FILES)
FOR I = 0, N_FILES-1 DO BEGIN
   IMAGE=READFITS(FILE_LIST[I], /SILENT)
   IMAGE=REFORM(IMAGE[NXA:NXB-1,NYA:NYB-1], N_PIX)
   IMAGE=IMAGE[INDX]
   FOR J = 0, 49 DO BEGIN
      PIX_SUM[J,I]=TOTAL(IMAGE[50L*J:50L*J+49], /DOUBLE)
   ENDFOR
   PIX_SUM[50,I]=TOTAL(PIX_SUM[0:49,I], /DOUBLE)
ENDFOR
PIX_VAR=DOUBLE(DN_INDX)*READ_NOISE^2+PIX_SUM/ADU_CALIB
PIX_VAR[50,*]=DOUBLE(50L*DN_INDX)*READ_NOISE^2+PIX_SUM[50,*]/ADU_CALIB
FOR I = 1, N_FILES-1 DO BEGIN
   PIX_SUM[*,I]=PIX_SUM[*,I]-PIX_SUM[*,0]
   PIX_VAR[*,I]=PIX_VAR[*,I]+PIX_VAR[*,0]
ENDFOR
;
;       Compute power law coefficients
;
A=DBLARR(51, 2*N_INTEN)
P=DBLARR(51, N_INTEN+1)
FOR I = 0, 50 DO BEGIN
   M=DBLARR(5, N_INTEN+1)
   FOR J = 0, N_INTEN-1 DO BEGIN
      INDX=WHERE(INTEN_CNT EQ J)
      X=ALOG(T[INDX])
      Y=REFORM(PIX_SUM[I,INDX])
      W=Y^2/REFORM(PIX_VAR[I,INDX])
      M[0,J]=TOTAL(W*X^2, /DOUBLE)
      M[1,J]=TOTAL(W*X, /DOUBLE)
      M[2,J]=TOTAL(W, /DOUBLE)
      M[3,J]=TOTAL(W*X*ALOG(Y), /DOUBLE)
      M[4,J]=TOTAL(W*ALOG(Y), /DOUBLE)
      DET=M[0,J]*M[2,J]-M[1,J]^2
      A[I,J]=(-M[1,J]*M[3,J]+M[0,J]*M[4,J])/DET
      P[I,J]=(+M[2,J]*M[3,J]-M[1,J]*M[4,J])/DET
   ENDFOR
   MAT=DBLARR(N_INTEN+1, N_INTEN+1)
   VEC=DBLARR(N_INTEN+1)
   MAT[0,0]=TOTAL(M[0,0:N_INTEN-1], /DOUBLE)
   VEC[0]=TOTAL(M[3,0:N_INTEN-1], /DOUBLE)
   FOR J=0, N_INTEN-1 DO BEGIN
      MAT[J+1,0]=M[1,J]
      MAT[J+1,J+1]=M[2,J]
      VEC[J+1]=M[4,J]
   ENDFOR
   CHOLDC, MAT, U, /DOUBLE
   V=CHOLSOL(MAT, U, VEC, /DOUBLE)
   A[I,N_INTEN:2*N_INTEN-1]=V[1:N_INTEN]
   P[I,N_INTEN]=V[0]
ENDFOR
;
;       Compute power law fit residuals
;
T_EXT=EXP(A[50,INTEN_CNT[1:N_FILES-1]+N_INTEN]-A[50,N_INTEN])*T[1:N_FILES-1]
T_EXT=REFORM(T_EXT)
RES=DBLARR(6, N_FILES-1)
FOR I = 1, N_FILES-1 DO BEGIN
   J=INTEN_CNT[I]
   YE=ALOG(PIX_SUM[*,I])
   YC=A[*,J]+P[*,J]*ALOG(T[I])
   DY=YE-YC
   INDX=SORT(DY[0:49])
   RES[0,I-1]=DY[50]
   RES[1,I-1]=DY[INDX[12]]
   RES[2,I-1]=DY[INDX[37]]
   YC=A[*,N_INTEN+J]+P[*,N_INTEN]*ALOG(T[I])
   DY=YE-YC
   INDX=SORT(DY[0:49])
   RES[3,I-1]=DY[50]
   RES[4,I-1]=DY[INDX[12]]
   RES[5,I-1]=DY[INDX[37]]
ENDFOR
;
;       Plot results
;
XR=[0.5D0*T_EXT[0],2.0D0*T_EXT[N_FILES-2]]
BAR=[1.0D0/1.05D0,1.05D0]
ANGLE=!DPI*DINDGEN(21)/10.0D0
USERSYM, 0.75D0*COS(ANGLE), 0.75D0*SIN(ANGLE), /FILL
RED=[000B,255B,255B,000B,000B,255B,000B,255B,255B]
GRN=[000B,255B,000B,255B,000B,000B,255B,140B,255B]
BLU=[000B,255B,000B,000B,255B,255B,255B,020B,000B]
TVLCT, RED, GRN, BLU
DEV_NAME=!D.NAME
FOR I_DEV = 0, 1 DO BEGIN
   !P.MULTI=[0,0,2,0,0]
   IF (I_DEV EQ 0) THEN BEGIN
      DEVICE, DECOMPOSED=0
      WINDOW, XSIZE=560, YSIZE=700, TITLE='lin_check'
   ENDIF ELSE BEGIN
      SET_PLOT, 'PS'
      DEVICE, FILENAME=output_file, /COLOR, XSIZE=20.32, YSIZE=25.40,    $
      XOFFSET=1.00, YOFFSET=0.80
   ENDELSE
   YR=[MIN(RES[1,*]),MAX(RES[2,*])]
   PLOT, [0,0], [0,0], /NODATA, XRANGE=XR, YRANGE=YR, /XLOG,                   $
      TITLE='!5'+output_file+' broken power law', XTITLE='!5light intensity',  $
      YTITLE='!5power law fractional deviation', XTICKLEN=0.03, CHARSIZE=1.4,  $
      CHARTHICK=2.0, XTHICK=4.0, YTHICK=4.0, THICK=4.0
   OPLOT, XR, [0,0], LINESTYLE=2, THICK=4.0
   FOR I = 0, N_FILES-2 DO BEGIN
      TP=T_EXT[I]
      COL=INTEN_CNT[I+1]+2
      OPLOT, [TP, TP], [RES[1,I],RES[2,I]], THICK=4.0, COLOR=COL
      OPLOT, BAR*[TP,TP], [RES[1,I],RES[1,I]], THICK=4.0, COLOR=COL
      OPLOT, BAR*[TP,TP], [RES[2,I],RES[2,I]], THICK=4.0, COLOR=COL
   ENDFOR
   FOR I = 0, N_INTEN-1 DO BEGIN
      INDX=WHERE(INTEN_CNT[1:N_FILES-1] EQ I)
      OPLOT, T_EXT[INDX], RES[0,INDX], PSYM=8, COLOR=I+2
      INDX=SORT(P[0:49,I])
      P_AV=P[50,I]
      P_STD=(P[INDX[37],I]-P[INDX[12],I])/IQD
      S='!5p = '+STRTRIM(STRING(P_AV, FORMAT='(F10.3)'), 2)
      S=S+' !9+!5 '+STRTRIM(STRING(P_STD, FORMAT='(F10.3)'), 2)
      XS=10.0D0^!X.CRANGE[1]/1.25D0
      FS=DOUBLE(90-6*I)/100.0D0
      YS=(1.0D0-FS)*!Y.CRANGE[0]+FS*!Y.CRANGE[1]
      XYOUTS, XS, YS, S, ALIGNMENT=1.0, CHARTHICK=2.0, COLOR=I+2
   ENDFOR
   YR=[MIN(RES[4,*]),MAX(RES[5,*])]
   PLOT, [0,0], [0,0], /NODATA, XRANGE=XR, YRANGE=YR, /XLOG,                   $
   TITLE='!5'+output_file+' single power law', XTITLE='!5light intensity',     $
   YTITLE='!5power law fractional deviation', XTICKLEN=0.03, CHARSIZE=1.4,     $
   CHARTHICK=2.0, XTHICK=4.0, YTHICK=4.0, THICK=4.0
   OPLOT, XR, [0,0], LINESTYLE=2, THICK=4.0
   FOR I = 0, N_FILES-2 DO BEGIN
      TP=T_EXT[I]
      COL=INTEN_CNT[I+1]+2
      OPLOT, [TP, TP], [RES[4,I],RES[5,I]], THICK=4.0, COLOR=COL
      OPLOT, BAR*[TP,TP], [RES[4,I],RES[4,I]], THICK=4.0, COLOR=COL
      OPLOT, BAR*[TP,TP], [RES[5,I],RES[5,I]], THICK=4.0, COLOR=COL
   ENDFOR
   FOR I = 0, N_INTEN-1 DO BEGIN
      INDX=WHERE(INTEN_CNT[1:N_FILES-1] EQ I)
      OPLOT, T_EXT[INDX], RES[3,INDX], PSYM=8, COLOR=I+2
   ENDFOR
   INDX=SORT(P[0:49,N_INTEN])
   P_AV=P[50,N_INTEN]
   P_STD=(P[INDX[37],N_INTEN]-P[INDX[12],N_INTEN])/IQD
   S='!5p = '+STRTRIM(STRING(P_AV, FORMAT='(F10.3)'), 2)
   S=S+' !9+!5 '+STRTRIM(STRING(P_STD, FORMAT='(F10.3)'), 2)
   XS=10.0D0^!X.CRANGE[1]/1.25D0
   FS=DOUBLE(90)/100.0D0
   YS=(1.0D0-FS)*!Y.CRANGE[0]+FS*!Y.CRANGE[1]
   XYOUTS, XS, YS, S, ALIGNMENT=1.0, CHARTHICK=2.0
   IF (I_DEV EQ 1) THEN DEVICE, /CLOSE_FILE
   !P.MULTI=0
ENDFOR
SET_PLOT, DEV_NAME
RETURN, TRANSPOSE([[T_EXT],[TRANSPOSE(RES)]])
END
