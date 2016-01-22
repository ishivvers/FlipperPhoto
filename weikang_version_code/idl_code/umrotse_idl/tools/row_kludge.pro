;******************************************************************************
;*                                                                            *
;*      ROW_KLUDGE.PRO                                                        *
;*                                                                            *
;*      ROW_KLUDGE tests the row alignment of CCD images by comparing lists   *
;*  of "hot pixels" taken from successive image frames. The alignment most    *
;*  common to all images defines the zero shift reference. Those image files  *
;*  not properly aligned are rewritten after suitable rearrangement to        *
;*  restore proper correlation. This program operates on all primary image    *
;*  files located in the directory specified by the environmental variable,   *
;*  STAR_LIST_DIR. Each of the four ROTSE-I cameras is processed separately.  *
;*  Dark frames with zero exposure length are ignored since they cannot be    *
;*  correlated. A summary of the results are recorded in the file,            *
;*  row_kludge.lst. A batch file, row_kludge.bat, is also created to rename   *
;*  all modified image files.                                                 *
;*                                                                            *
;*                                                                            *
;*      Carl W. Akerlof                                                       *
;*      Randall Laboratory of Physics                                         *
;*      500 East University                                                   *
;*      University of Michigan                                                *
;*      Ann Arbor, Michigan  48109                                            *
;*                                                                            *
;*      May 11, 1998                                                          *
;*                                                                            *
;******************************************************************************

      FILE_DIR=GETENV('STAR_LIST_DIR')
      IF (STRLEN(FILE_DIR) LE 0) THEN BEGIN
         PRINT, 'Empty file directory string'
         EXIT
      ENDIF
      CAM_ID=['a','b','c','d']
      N_DIF=5
      MATCH_MAX=500L
      SIG_THRESH=1.644854D0
      FRAC=GAUSSINT(SIG_THRESH)
      MAT_CNT=INTARR(2*N_DIF+1)
      ROW_MIN=INTARR(2*N_DIF+1)
      ROW_MAX=INTARR(2*N_DIF+1)
      S_DEF=['*****************','                    ']
      S_BEGIN='Begin:   '+SYSTIME()
      T_BEGIN=SYSTIME(1)
      GET_LUN, P_UNIT
      OPENW, P_UNIT, 'row_kludge.lst'
      PRINTF, P_UNIT, "ROW_KLUDGE image file list", FORMAT='(/A/)'
      GET_LUN, R_UNIT
      OPENW, R_UNIT, 'row_kludge.bat'
      PRINTF, R_UNIT, 'row_kludge.bat',                                       $
            'execute this file to rename realigned image file to source file',$
                                           FORMAT='("#"/"#",7X,A/"#",7X,A/"#")'
      GET_LUN, U_UNIT
      OPENW, U_UNIT, 'row_ukludge.bat'
      PRINTF, U_UNIT, 'row_ukludge.bat',                                      $
              'execute this file to restore original image file name',        $
                                           FORMAT='("#"/"#",7X,A/"#",7X,A/"#")'
      GET_LUN, UNIT
      FOR I_CAM = 0, 3 DO BEGIN
         KEY='_1'+CAM_ID(I_CAM)
         FILES=FINDFILE(FILE_DIR+'/*'+KEY+'*.fit')
         N_FILES=N_ELEMENTS(FILES)
         FILE_INDX=INTARR(N_FILES)
         FILE_SORT=INTARR(N_FILES)
         FILE_SIZE=LONARR(N_FILES)
         I=0
         FOR I_FILE = 0, N_FILES-1 DO BEGIN
            FILE_NAME=FILES(I_FILE)
            L=STRLEN(FILE_NAME)
            M=STRPOS(FILE_NAME, KEY, 0)
            TAG=STRMID(FILE_NAME, M+1, L-M-1)
            IF (STRPOS(TAG, '_', 0) LT 0) THEN BEGIN
               IF (STRPOS(FILE_NAME, 'drk0000', 0) LT 0) THEN BEGIN
                  M=STRPOS(TAG, '.', 0)
                  CHAR=STRMID(TAG, M-1, 1)
                  D=BYTE(CHAR)
                  IF ((D(0) GE 48) AND (D(0) LE 57)) THEN BEGIN
                     OPENR, UNIT, FILES(I_FILE)
                     FS=FSTAT(UNIT)
                     IF (FS.SIZE GT 0) THEN BEGIN
                        FILE_INDX(I)=I_FILE
                        FILE_SORT(I)=FIX(STRMID(TAG, M-3, 3))
                        FILE_SIZE(I)=FS.SIZE
                        I=I+1
                     ENDIF
                     CLOSE, UNIT
                  ENDIF
               ENDIF
            ENDIF
         ENDFOR
         N_FILES=I
         IF (N_FILES GE 1) THEN BEGIN
            FILE_SORT=SORT(FILE_SORT(0:I-1))
            FILES=FILES(FILE_INDX(FILE_SORT))
            FILE_SIZE=FILE_SIZE(FILE_SORT)
            T=READFITS(FILES(0), HDR, /SILENT)
            IMAGE_SIZE=SIZE(T)
            N_COL=IMAGE_SIZE(1)
            N_ROW=IMAGE_SIZE(2)
            N_I=N_COL/16
            N_J=N_ROW/16
            FOR J = 0, N_J-1 DO BEGIN
               JA=16*J
               JB=JA+15
               FOR I = 0, N_I-1 DO BEGIN
                  IA=16*I
                  IB=IA+15
                  U=T(IA:IB,JA:JB)
                  T(IA:IB,JA:JB)=U-FIX(MEDIAN(U))
               ENDFOR
            ENDFOR
            H=HISTOGRAM(LONG(T), OMIN=NX_MIN, OMAX=NX_MAX)
            SUM=LONARR(NX_MAX+1-NX_MIN)
            SUM(0)=H(0)
            FOR I = 1L, NX_MAX-NX_MIN DO SUM(I)=SUM(I-1)+H(I)
            QUART=DBLARR(3)
            FOR I = 0, 2 DO BEGIN
               Q=0.25D0*DOUBLE((I+1)*N_COL*N_ROW)
               INDX=WHERE(SUM GE Q)
               QUART(I)=INDX(0)+NX_MIN-                                       $
                                      DOUBLE(SUM(INDX(0))-Q)/DOUBLE(H(INDX(0)))
            ENDFOR
            SIGMA=(QUART(2)-QUART(0))/(2.0D0*SQRT(2.0D0*ALOG(2.0D0)))
            Q=FRAC*DOUBLE(N_COL*N_ROW)
            INDX=WHERE(SUM GE Q)
            Q_THRESH=INDX(0)+NX_MIN-DOUBLE(SUM(INDX(0))-Q)/DOUBLE(H(INDX(0)))
            THRESH=FIX(Q_THRESH+(3.0D0-SIG_THRESH)*SIGMA)
            B_MASK=T LE THRESH
            N_MASK=NOT B_MASK
            ONE_COL=BYTARR(N_ROW)+1B
            ONE_ROW=BYTARR(N_COL)+1B
            N_MASK=N_MASK AND [[B_MASK(*,1:N_ROW-1)],[ONE_ROW]] AND           $
                              [[ONE_ROW],[B_MASK(*,0:N_ROW-2)]]
            B_MASK=TRANSPOSE(TEMPORARY(B_MASK))
            L_MASK=TRANSPOSE([[B_MASK(*,1:N_COL-1)],[ONE_COL]])
            R_MASK=TRANSPOSE([[ONE_COL],[B_MASK(*,0:N_COL-2)]])
            N_MASK=N_MASK AND L_MASK AND R_MASK AND                           $
                              [[L_MASK(*,1:N_ROW-1)],[ONE_ROW]] AND           $
                              [[ONE_ROW],[L_MASK(*,0:N_ROW-2)]] AND           $
                              [[R_MASK(*,1:N_ROW-1)],[ONE_ROW]] AND           $
                              [[ONE_ROW],[R_MASK(*,0:N_ROW-2)]]
            INDX=WHERE(N_MASK, N)
            IF (N GT MATCH_MAX) THEN BEGIN
               N=MATCH_MAX
               JNDX=REVERSE(SORT(T(INDX)))
               INDX=INDX(JNDX(0:N-1))
               INDX=INDX(SORT(INDX))
            ENDIF
            N_MASK=BYTARR(N_COL, N_ROW)
            IF (N GT 0) THEN BEGIN
               N_MASK(INDX)=1B
            ENDIF
            N_OFF=LONARR(2, N_FILES)
            MATCH=INTARR(2, N_FILES)
            ROW_LIM=INTARR(4, N_FILES)
            MATCH(0,0)=MATCH_MAX
            ROW_LIM(2,0)=N_ROW-1
            PRINT, 'Camera '+CAM_ID(I_CAM)+':', FORMAT='(/A/)'
            PRINTF, P_UNIT, 'Camera '+CAM_ID(I_CAM)+':', FORMAT='(/A/)'
         ENDIF
         FOR I_FILE = 1, N_FILES-1 DO BEGIN
            T=READFITS(FILES(I_FILE), HDR, /SILENT)
            IMAGE_SIZE=SIZE(T)
            M_COL=IMAGE_SIZE(1)
            M_ROW=IMAGE_SIZE(2)
            M_I=M_COL/16
            M_J=M_ROW/16
            FOR J = 0, M_J-1 DO BEGIN
               JA=16*J
               JB=JA+15
               FOR I = 0, M_I-1 DO BEGIN
                  IA=16*I
                  IB=IA+15
                  U=T(IA:IB,JA:JB)
                  T(IA:IB,JA:JB)=U-FIX(MEDIAN(U))
               ENDFOR
            ENDFOR
            H=HISTOGRAM(LONG(T), OMIN=MX_MIN, OMAX=MX_MAX)
            SUM=LONARR(MX_MAX+1-MX_MIN)
            SUM(0)=H(0)
            FOR I = 1L, MX_MAX-MX_MIN DO SUM(I)=SUM(I-1)+H(I)
            QUART=DBLARR(3)
            FOR I = 0, 2 DO BEGIN
               Q=0.25D0*DOUBLE((I+1)*M_COL*M_ROW)
               INDX=WHERE(SUM GE Q)
               QUART(I)=INDX(0)+MX_MIN-                                       $
                                      DOUBLE(SUM(INDX(0))-Q)/DOUBLE(H(INDX(0)))
            ENDFOR
            SIGMA=(QUART(2)-QUART(0))/(2.0D0*SQRT(2.0D0*ALOG(2.0D0)))
            Q=FRAC*DOUBLE(M_COL*M_ROW)
            INDX=WHERE(SUM GE Q)
            Q_THRESH=INDX(0)+MX_MIN-DOUBLE(SUM(INDX(0))-Q)/DOUBLE(H(INDX(0)))
            THRESH=FIX(Q_THRESH+(3.0D0-SIG_THRESH)*SIGMA)
            B_MASK=T LE THRESH
            M_MASK=NOT B_MASK
            ONE_COL=BYTARR(M_ROW)+1B
            ONE_ROW=BYTARR(M_COL)+1B
            M_MASK=M_MASK AND [[B_MASK(*,1:M_ROW-1)],[ONE_ROW]] AND           $
                              [[ONE_ROW],[B_MASK(*,0:M_ROW-2)]]
            B_MASK=TRANSPOSE(TEMPORARY(B_MASK))
            L_MASK=TRANSPOSE([[B_MASK(*,1:M_COL-1)],[ONE_COL]])
            R_MASK=TRANSPOSE([[ONE_COL],[B_MASK(*,0:M_COL-2)]])
            M_MASK=M_MASK AND L_MASK AND R_MASK AND                           $
                              [[L_MASK(*,1:M_ROW-1)],[ONE_ROW]] AND           $
                              [[ONE_ROW],[L_MASK(*,0:M_ROW-2)]] AND           $
                              [[R_MASK(*,1:M_ROW-1)],[ONE_ROW]] AND           $
                              [[ONE_ROW],[R_MASK(*,0:M_ROW-2)]]
            INDX=WHERE(M_MASK, M)
            IF (M GT MATCH_MAX) THEN BEGIN
               M=MATCH_MAX
               JNDX=REVERSE(SORT(T(INDX)))
               INDX=INDX(JNDX(0:M-1))
               INDX=INDX(SORT(INDX))
            ENDIF
            M_MASK=BYTARR(M_COL, M_ROW)
            IF (M GT 0) THEN BEGIN
               M_MASK(INDX)=1B
            ENDIF
            L_COL=N_COL < M_COL
            L_ROW=N_ROW < M_ROW
            N_MASK(*,0:N_DIF-1)=0B
            N_MASK(*,L_ROW-N_DIF:L_ROW-1)=0B
            L_MASK=M_MASK(0:L_COL-1,N_DIF:L_ROW-N_DIF-1)
            FOR I = -N_DIF, +N_DIF DO BEGIN
               INDX=WHERE(N_MASK(0:L_COL-1,N_DIF-I:L_ROW-N_DIF-1-I) AND       $
                                                               L_MASK, N_MATCH)
               MAT_CNT(I+N_DIF)=N_MATCH
               INDX=INDX/L_COL
               ROW_MIN(I+N_DIF)=MIN(INDX)+N_DIF
               ROW_MAX(I+N_DIF)=MAX(INDX)+N_DIF
            ENDFOR
            INDX=REVERSE(SORT(MAT_CNT))
            N_OFF(*,I_FILE)=INDX(0:1)-N_DIF+N_OFF(*,I_FILE-1)
            MATCH(*,I_FILE)=MAT_CNT(INDX(0:1))
            ROW_LIM(0:1,I_FILE)=ROW_MIN(INDX(0:1))
            ROW_LIM(2:3,I_FILE)=ROW_MAX(INDX(0:1))
            N_COL=M_COL
            N_ROW=M_ROW
            N_MASK=M_MASK
         ENDFOR
         IF (N_FILES GT 0) THEN BEGIN
            H=HISTOGRAM(N_OFF(0,*), OMIN=L)
            VAL=MAX(H)
            INDX=WHERE(H EQ VAL)
            N_OFF=N_OFF-(INDX(0)+L)
         ENDIF
         FOR I_FILE = 0, N_FILES-1 DO BEGIN
            I=N_OFF(0,I_FILE)
            IF (I NE 0) THEN BEGIN
               T=READFITS(FILES(I_FILE), HDR, /SILENT)
               IMAGE_SIZE=SIZE(T)
               N_COL=IMAGE_SIZE(1)
               N_ROW=IMAGE_SIZE(2)
               U=INTARR(N_COL, N_ROW)
               IF (I LT 0) THEN BEGIN
                  U(*,-I:N_ROW-1)=T(*,0:N_ROW+I-1)
                  U(*,0:-I-1)=T(*,N_ROW+I:N_ROW-1)
               ENDIF ELSE BEGIN
                  U(*,0:N_ROW-I-1)=T(*,I:N_ROW-1)
                  U(*,N_ROW-I:N_ROW-1)=T(*,0:I-1)
               ENDELSE
               WRITEFITS, FILES(I_FILE)+'k', U, HDR
               PRINT, N_OFF(0,I_FILE), MATCH(0,I_FILE), FILES(I_FILE),        $
                                                       FORMAT='(I3,2X,I4,2X,A)'
               PRINTF, P_UNIT, N_OFF(0,I_FILE), MATCH(0,I_FILE),              $
                                        FILES(I_FILE), FORMAT='(I3,2X,I4,2X,A)'
               PRINTF, R_UNIT, "mv "+FILES(I_FILE)+" "+FILES(I_FILE)+"x"
               PRINTF, R_UNIT, "mv "+FILES(I_FILE)+"k "+FILES(I_FILE)
               PRINTF, U_UNIT, "mv "+FILES(I_FILE)+"x "+FILES(I_FILE)
            ENDIF
         ENDFOR
      ENDFOR
      FREE_LUN, UNIT
      T_END=SYSTIME(1)
      S_END='End:     '+SYSTIME()
      PRINT, S_BEGIN, S_END, T_END-T_BEGIN, FORMAT='(/A/A/"Elapsed:",F9.3)'
      PRINTF, P_UNIT, S_BEGIN, S_END, T_END-T_BEGIN,                          $
                                                FORMAT='(/A/A/"Elapsed:",F9.3)'
      CLOSE, P_UNIT
      FREE_LUN, P_UNIT
      CLOSE, R_UNIT
      FREE_LUN, R_UNIT
      SPAWN, 'chmod u+x row_kludge.bat'
      CLOSE, U_UNIT
      FREE_LUN, U_UNIT
      SPAWN, 'chmod u+x row_ukludge.bat'
      END
