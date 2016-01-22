pro plot_freqp, file_name, plot=plot_flag	

;******************************************************************************
;*                                                                            *
;*    	plot_freqp.pro                                                        *
;*                                                                            *
;*	"plot_freqp" reads an ASCII text file created by "format_freq" and    *
;*  generates plots on an X-window terminal or formatted to a Postscript      *
;*  output file. This routine is called by "plot_freq.pro".                   *
;*                                                                            *
;*		Carl W. Akerlof                                               *
;*		Randall Laboratory of Physics                                 *
;*		500 East University                                           *
;*		University of Michigan                                        *
;*		Ann Arbor, Michigan  48109                                    *
;*                                                                            *
;*		January 29, 1996                                              *
;*                                                                            *
;******************************************************************************


	IF (N_ELEMENTS(PLOT_FLAG) EQ 0) THEN BEGIN
	   PLOT_FLAG=0
	ENDIF
	GET_LUN, UNIT
	TMP=FINDGEN(32)*(!PI*2/32)
	USERSYM, 0.7*COS(TMP), 0.7*SIN(TMP), /FILL
	NAME=STRLOWCASE(FILE_NAME)
	FILE_STRING=NAME + ".txt"
	OPENR, UNIT, FILE_STRING, ERROR=IO_STATUS
	IF (IO_STATUS NE 0) THEN BEGIN
	   PRINT, !ERR_STRING
	ENDIF ELSE BEGIN
	   UPNAME=STRUPCASE(NAME)
	   N=1
	   READF, UNIT, N
	   X=FLTARR(N)
	   Y=FLTARR(N)
	   DY=FLTARR(N)
	   XLO=0.0 & XHI=1.0 & YLO=0.0 & YHI=1.0
	   READF, UNIT, XLO, XHI, YLO, YHI
	   TMP=FLTARR(3)
	   FOR I = 0, N-1 DO BEGIN
	      READF, UNIT, TMP
	      X(I)=TMP(0)
	      Y(I)=TMP(1)
	      DY(I)=TMP(2)
	   ENDFOR
	   IF (PLOT_FLAG NE 0) THEN BEGIN
	      DEVICE_NAME=!D.NAME
	      SET_PLOT, 'PS'
	      DEVICE, FILENAME=FILE_NAME+".ps", XSIZE=19, YSIZE=24,   $
	              XOFFSET=1.25, YOFFSET=3.00
	   ENDIF
	   !P.MULTI=[0, 0, 2, 0, 0]
	   PLOT, X, Y, PSYM=8, /XSTYLE, /YSTYLE, XRANGE=[XLO, XHI],        $
	         YRANGE=[YLO, YHI], CHARSIZE=1.0, FONT=-1,                 $
	         XTITLE="!5"+UPNAME+" observation time (days)",            $
	         YTITLE="!5Amplitude"
	   PLOTBARS, X, (XHI-XLO)/200.0, Y, DY
	   READF, UNIT, N
	   X=FLTARR(N)
	   Y=FLTARR(N)
	   DY=FLTARR(N)
	   READF, UNIT, XLO, XHI, YLO, YHI
	   READF, UNIT, F, N_INTERVALS
	   TMP=FLTARR(3)
	   FOR I = 0, N-1 DO BEGIN
	      READF, UNIT, TMP
	      X(I)=TMP(0)
	      Y(I)=TMP(1)
	      DY(I)=TMP(2)
	   ENDFOR
	   PLOT, X, Y, PSYM=8, /XSTYLE, /YSTYLE, XRANGE=[XLO, XHI],        $
	         YRANGE=[YLO, YHI], CHARSIZE=1.0, FONT=-1,                 $
	         XTITLE="!5Light curve for "+UPNAME,                       $
	         YTITLE="!5Amplitude"
	   PLOTBARS, X, (XHI-XLO)/200.0, Y, DY
           XT=+1.00*XLO+0.00*XHI
           YT=-0.03*YLO+1.03*YHI
           FNOTE=STRTRIM(STRING(FORMAT='(I6)',N_INTERVALS), 2)
           XYOUTS, XT, YT, "!5n = "+FNOTE, CHARSIZE=1.0, FONT=-1, ALIGNMENT=0.0
	   XT=+0.00*XLO+1.00*XHI
	   FNOTE=STRTRIM(STRING(FORMAT='(F10.6)', F), 2)
	   XYOUTS, XT, YT, "!5f = "+FNOTE, CHARSIZE=1.0, FONT=-1,          $
	           ALIGNMENT=1.0
	   READF, UNIT, N
	   X=FLTARR(N)
	   Y=FLTARR(N)
	   TMP=FLTARR(2)
	   FOR I = 0, N-1 DO BEGIN
	      READF, UNIT, TMP
	      X(I)=TMP(0)
	      Y(I)=TMP(1)
	   ENDFOR
	   OPLOT, X, Y
	   CLOSE, UNIT
	ENDELSE
	IF (PLOT_FLAG NE 0) THEN BEGIN
	   DEVICE, /CLOSE_FILE
	   SET_PLOT, DEVICE_NAME
	ENDIF
	!P.MULTI=[0, 0, 0, 0, 0]
	FREE_LUN, UNIT
	RETURN
	END
