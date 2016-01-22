function ss_make_spline_kernels_2

FA=DOUBLE([0,1,4,1,0])/4.0D0
FB=DOUBLE([0,1,8,27,60,93,108,93,60,27,8,1,0])/108.0D0
FC=DOUBLE([0,1,8,27,64,121,184,235,256,235,184,121,64,27,8,1,0])/256.0D0

X=INTARR(9, 9)
Y=INTARR(9, 9)
F=DBLARR(9, 9, 25)
NA=N_ELEMENTS(FA)/2
NB=N_ELEMENTS(FB)/2
NC=N_ELEMENTS(FC)/2
FOR IX = 0, 2 DO BEGIN
   FOR I = 0, 8 DO BEGIN
      X[*,I]=((INDGEN(9)-3-IX) > (-NA)) < NA
   ENDFOR
   FOR IY= 0, 2 DO BEGIN
      FOR I = 0, 8 DO BEGIN
         Y[I,*]=((INDGEN(9)-3-IY) > (-NA)) < NA
      ENDFOR
      IXY=IX+3*IY
      E=FA[X+NA]*FA[Y+NA]
      F[*,*,IXY]=E
   ENDFOR
ENDFOR
XB=[4,3,0,-3,-4,-3, 0,+3]
YB=[0,3,4,+3, 0,-3,-4,-3]
FOR IR = 0, 7 DO BEGIN
   FOR I = 0, 8 DO BEGIN
      X[*,I]=((2*INDGEN(9)-8-XB[IR]) > (-NB)) < NB
      Y[I,*]=((2*INDGEN(9)-8-YB[IR]) > (-NB)) < NB
   ENDFOR
   IXY=9+IR
   E=FB[X+NB]*FB[Y+NB]
   F[*,*,IXY]=E
ENDFOR
XC=[7,5,0,-5,-7,-5, 0,+5]
YC=[0,5,7,+5, 0,-5,-7,-5]
FOR IR = 0, 7 DO BEGIN
   FOR I = 0, 8 DO BEGIN
      X[*,I]=((2*INDGEN(9)-8-XC[IR]) > (-NC)) < NC
      Y[I,*]=((2*INDGEN(9)-8-YC[IR]) > (-NC)) < NC
   ENDFOR
   IXY=17+IR
   E=FC[X+NC]*FC[Y+NC]
   F[*,*,IXY]=E
ENDFOR

return,F
END
