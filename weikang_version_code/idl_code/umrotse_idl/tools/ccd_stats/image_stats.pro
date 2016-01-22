;*******************************************************************************
;                                                                              *
;       image_stats.pro                                                        *
;                                                                              *
;       Carl W. Akerlof                                                        *
;       Randall Laboratory of Physics                                          *
;       500 East University                                                    *
;       University of Michigan                                                 *
;       Ann Arbor, Michigan  48109                                             *
;                                                                              *
;       November 12, 2002                                                      *
;                                                                              *
;*******************************************************************************

FUNCTION IMAGE_STATS, FILE_LIST
N_FILES=N_ELEMENTS(FILE_LIST)
DNX=2048L
NXA=53L
NXB=NXA+DNX
DNY=2048L
NYA=2L
NYB=NYA+DNY
N_PIX=DNX*DNY
STATS=LONARR(6L, N_FILES+1L)
FOR I = 1L, N_FILES DO BEGIN
   IMAGE=READFITS(FILE_LIST[I-1], /SILENT)
   Q=REFORM(IMAGE[NXA:NXB-1,NYA:NYB-1], N_PIX)
   STATS[0,I]=N_PIX
   STATS[1,I]=2L*MIN(Q)
   STATS[2:4,I]=IQUARTILE(Q)/2L
   STATS[5,I]=2L*MAX(Q)
ENDFOR
Q=REFORM(STATS[3,1:N_FILES])
STATS[0,0]=N_FILES
STATS[1,0]=2L*MIN(Q)
STATS[2:4,0]=IQUARTILE(Q)/2L
STATS[5,0]=2L*MAX(Q)
RETURN, STATS
END