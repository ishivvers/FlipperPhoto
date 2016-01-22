;
;       iquartile.pro
;
;       Carl W. Akerlof
;       Randall Laboratory of Physics
;       500 East University
;       University of Michigan
;       Ann Arbor, Michigan  48109
;
;       November 10, 2002
;

FUNCTION IQUARTILE, I_ARRAY
N_TERMS=[[1,1,1],[1,0,1],[0,1,0],[1,0,1]]
N_FACTOR=[[2,2,2],[1,4,3],[4,2,4],[3,4,1]]
N_OFF=[[0,0,0],[0,1,0],[1,0,1],[1,1,0]]
N=N_ELEMENTS(I_ARRAY)
R=N/4
P=N MOD 4
H=HISTOGRAM(I_ARRAY, OMIN=H_MIN, OMAX=H_MAX)
NH=N_ELEMENTS(H)
H_SUM=LONARR(NH+1L)
FOR I = 0L, NH-1L DO H_SUM[I+1]=H_SUM[I]+H[I]
IQUART=LONARR(3)
Q=0L
J=0L
FOR I = 0L, 2L DO BEGIN
   Q=Q+R+N_OFF[I,P]
   WHILE (H_SUM[J] LT Q) DO J=J+1L
   IF (N_TERMS[I,P] EQ 0) THEN BEGIN
      U=4*J
   ENDIF ELSE BEGIN
      K=J
      WHILE (H_SUM[K] LT (Q+1L)) DO K=K+1L
      U=N_FACTOR[I,P]*J+(4-N_FACTOR[I,P])*K
   ENDELSE
   IQUART[I]=U+4*(H_MIN-1L)
ENDFOR
RETURN, IQUART
END