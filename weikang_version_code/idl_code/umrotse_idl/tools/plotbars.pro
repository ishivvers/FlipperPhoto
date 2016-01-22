	PRO PLOTBARS, X, DX, Y, DY

;******************************************************************************
;*                                                                            *
;*	plotbars.pro                                                          *
;*                                                                            *
;*	fits_pix reads a FITS data file and prints 8 successive pixels        *
;*  values along a single image row. The program should be invoked with       *
;*  three arguments: the FITS data file name, the starting column, and the    *
;*  selected row.                                                             *
;*                                                                            *
;*		Carl W. Akerlof                                               *
;*		Center for Particle Astrophysics                              *
;*		301 Le Conte Hall                                             *
;*		University of California                                      *
;*		Berkeley, California  94720                                   *
;*                                                                            *
;*		May 28, 1993                                                  *
;*                                                                            *
;******************************************************************************

	N=N_ELEMENTS(X)
	FOR I =0, N-1 DO BEGIN
	   PLOTS, [X(I)-DX, X(I)+DX], [Y(I)-DY(I), Y(I)-DY(I)]
	   PLOTS, [X(I)-DX, X(I)+DX], [Y(I)+DY(I), Y(I)+DY(I)]
	   PLOTS, [X(I), X(I)], [Y(I)+DY(I), Y(I)-DY(I)]
	ENDFOR
	RETURN
	END
