;*******************************************************************************
;                                                                              *
;       test_script.pro                                                        *
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

PRO TEST_SCRIPT, NAME
DATA_FILES='D:\'+NAME+'*.fit'
REPEAT BEGIN
   FILE_LIST=FINDFILE(DATA_FILES, COUNT=N_FILES)
ENDREP UNTIL (N_FILES GT 0)
GET_LUN, UNIT
OPENW, UNIT, 'test_script.txt'
FOR I =0, N_FILES-1 DO PRINTF, UNIT, FILE_LIST[I], FORMAT='(A)'
CLOSE, UNIT
FREE_LUN, UNIT
NS=STRPOS(FILE_LIST[0], '\', /REVERSE_SEARCH)+1
S=STRMID(FILE_LIST[0], NS)
NS=STRPOS(S, '_3', /REVERSE_SEARCH)+3
OUT_NAME=STRMID(S, 0, NS)
IMAGE_SUMMARY, 'test_script.txt', OUT_NAME
END
