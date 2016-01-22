;*******************************************************************************
;                                                                              *
;       image_summary.pro                                                      *
;                                                                              *
;       Carl W. Akerlof                                                        *
;       Randall Laboratory of Physics                                          *
;       500 East University                                                    *
;       University of Michigan                                                 *
;       Ann Arbor, Michigan  48109                                             *
;                                                                              *
;       November 13, 2002                                                      *
;                                                                              *
;*******************************************************************************

PRO IMAGE_SUMMARY, FILE_LIST_NAME, OUTPUT_FILE_NAME
GET_LUN, UNIT
OPENR, UNIT, FILE_LIST_NAME
FILE_LIST=STRARR(1000)
N_FILE=0L
S=''
WHILE (EOF(UNIT) EQ 0) DO BEGIN
   READF, UNIT, S
   FILE_LIST[N_FILE]=S
   N_FILE=N_FILE+1L
ENDWHILE
CLOSE, UNIT
FREE_LUN, UNIT
FILE_LIST=FILE_LIST[0:N_FILE-1]
FILE_LIST=FILE_LIST[SORT(FILE_LIST)]
T=IMAGE_STATS(FILE_LIST)
IQD=GAUSS_CVF(0.25D0)-GAUSS_CVF(0.75D0)
N=T[0,0]
MED_AV=TOTAL(T[3,1:N], /DOUBLE)/DOUBLE(2*N)
MED2_AV=TOTAL(T[3,1:N]^2, /DOUBLE)/DOUBLE(4*N)
SIGMA=SQRT(MED2_AV-MED_AV^2)
SIGMAP=DOUBLE(T[4,0]-T[2,0])/(4.0D0*IQD)
U=DOUBLE(REFORM(T[3,2:N])-REFORM(T[3,1:N-1]))/2.0D0
ABSDIF=0.5D0*SQRT(!DPI)*TOTAL(ABS(U), /DOUBLE)/DOUBLE(N-1)
PRINT, 'File: ', OUTPUT_FILE_NAME, N, MED_AV, SIGMA, SIGMAP, ABSDIF,           $
       FORMAT='(A,A,I6,F12.3,3F10.3)'
WRITEFITS, OUTPUT_FILE_NAME+'_raw.fit', T
END