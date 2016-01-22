;*******************************************************************************
;                                                                              *
;       print_summary.pro                                                      *
;                                                                              *
;       Carl W. Akerlof                                                        *
;       Randall Laboratory of Physics                                          *
;       500 East University                                                    *
;       University of Michigan                                                 *
;       Ann Arbor, Michigan  48109                                             *
;                                                                              *
;       November 16, 2002                                                      *
;                                                                              *
;*******************************************************************************

PRO PRINT_SUMMARY, INPUT_FILE_NAME
IQD=GAUSS_CVF(0.25D0)-GAUSS_CVF(0.75D0)
DATA_FILES='D:\'+INPUT_FILE_NAME+'*_raw.fit'
REPEAT BEGIN
   FILE_LIST=FINDFILE(DATA_FILES, COUNT=N_FILES)
ENDREP UNTIL (N_FILES GT 0)
FILE_LIST=FILE_LIST[SORT(FILE_LIST)]
FOR I = 0, N_FILES-1 DO BEGIN
   T=READFITS(FILE_LIST[I], /SILENT)
   N=T[0,0]
   MED_AV=TOTAL(T[3,1:N], /DOUBLE)/DOUBLE(2*N)
   MED2_AV=TOTAL(T[3,1:N]^2, /DOUBLE)/DOUBLE(4*N)
   SIGMA=SQRT(MED2_AV-MED_AV^2)
   SIGMAP=DOUBLE(T[4,0]-T[2,0])/(4.0D0*IQD)
   U=DOUBLE(REFORM(T[3,2:N])-REFORM(T[3,1:N-1]))/2.0D0
   ABSDIF=0.5D0*SQRT(!DPI)*TOTAL(ABS(U), /DOUBLE)/DOUBLE(N-1)
   NS=STRPOS(FILE_LIST[I], INPUT_FILE_NAME, /REVERSE_SEARCH)
   S=STRMID(FILE_LIST[I], NS)
   NS=STRPOS(S, '_raw.fit', /REVERSE_SEARCH)
   S=STRMID(S, 0, NS)
   PRINT, 'File: ', S, N, MED_AV, SIGMA, SIGMAP, ABSDIF,                       $
          FORMAT='(A,A,I6,F12.3,3F10.3)'
ENDFOR
RETURN
END