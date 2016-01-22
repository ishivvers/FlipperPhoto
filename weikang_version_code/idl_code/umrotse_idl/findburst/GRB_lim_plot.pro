pro GRB_lim_plot, key, clr

;----------------------------------------------------------------------
;       Carl W. Akerlof
;       Randall Laboratory of Physics
;       500 East University
;       University of Michigan
;       Ann Arbor, Michigan 48109
;
;       May 25, 1999
;
; Updated: 99-12-16 Bob Kehoe
;----------------------------------------------------------------------

;CHAN_23_FLU=[3.2209D-005,3.9755D-006,7.7196D-006,       $
;			 7.0087D-006,1.2819D-005,1.0203D-004]
;CHAN_23_FLU=[1.0,1.0,1.0,1.0,1.0,1.0]

if (key lt 0 or key gt 2) then begin
   print, 'error in key value'
   return
endif

GRB_DATE=['980329','980401','980420',                      $
		  '981121','981223','990123']

if (clr eq 1) then begin
   RED=[000B,000B,000B,000B,125B,255B,255B,128B,128B]
   GRN=[000B,000B,255B,125B,125B,000B,177B,255B,128B]
   BLU=[000B,255B,000B,125B,000B,000B,000B,128B,255B]
endif else if (clr eq 0) then begin
   RED=[000B,230B,185B,140B,095B,050B,100B,080B,060B]
   GRN=[000B,230B,185B,140B,095B,050B,100B,080B,060B]
   BLU=[000B,230B,185B,140B,095B,050B,100B,080B,060B]
endif
TVLCT, RED, GRN, BLU
COLOR_MAP=[1,3,2,4,5,0]
XRANGE=[10.0D0,10000.0D0]

if (key eq 0) then begin
   YRANGE=[18.0D0,8.0D0]
   ystring = '!5optical magnitude'
endif else if (key eq 1) then begin
   yrange=[16.0D0,6.0D0]
   ystring = '!5fluence scaled optical magnitude'
endif else if (key eq 2) then begin
   yrange=[17.0D0,7.0D0]
   ystring = '!5flux scaled optical magnitude'
endif

USERSYM, 1.0*COS((!DPI/18.0D0)*DINDGEN(37)), 1.0*SIN((!DPI/18.0D0)*DINDGEN(37)), /FILL
LTHICK=4.0D0
CSIZE=1.25D0
CTHICK=2.0D0
TTHICK=4.0D0
D_NAME=!D.NAME
FOR I_DEV = 0, 1 DO BEGIN
	IF (I_DEV EQ 1) THEN BEGIN
		SET_PLOT, 'PS'
		DEVICE, FILENAME='GRB_lim_plot.ps', /COLOR
		COLOR_MAP(5)=0
	ENDIF ELSE BEGIN
		COLOR_MAP(5)=1
	ENDELSE

;    	  	 YTITLE='!5optical magnitude', TITLE='!5fluence-scaled optical intensity', $

	PLOT, [0,1], [0,1], /NODATA, /XLOG, XTITLE='!5elapsed time (seconds)',             $
    	  	 YTITLE=ystring, $
    	  	 THICK=LTHICK, CHARSIZE=CSIZE, XCHARSIZE=0.96, YCHARSIZE=0.96, $
    	  	 CHARTHICK=CTHICK, TICKLEN=0.04, XTHICK=TTHICK, YTHICK=TTHICK,     $
    	  	 /XSTYLE, /YSTYLE, XRANGE=XRANGE, YRANGE=YRANGE
	FOR I = 0L, 5L DO BEGIN
		R_DATA=GRB_DATA(GRB_DATE(I), FLU)
		NR_DATA=N_ELEMENTS(R_DATA)/3

		if (key eq 0) then begin
		   D_MAG = 0
		endif else if (key eq 1) then begin
		   tmp = grb_data(grb_date[5], tmpflu)
		   d_mag = 2.5D0*alog10((flu[1]+flu[2])/(tmpflu[1]+tmpflu[2]))
		endif else begin
		   tmp = grb_data(grb_date[5], tmpflu)
		   d_mag = 2.5D0*alog10(flu[4]/tmpflu[4])
		endelse

;		D_MAG=2.5D0*ALOG10(CHAN_23_FLU(I)/CHAN_23_FLU(5))
		FOR J = 0, NR_DATA-1 DO BEGIN
			X1=R_DATA(J,0)
			X2=R_DATA(J,0)+0.5D0*R_DATA(J,2)
			X3=R_DATA(J,0)+R_DATA(J,2)
			Y1=R_DATA(J,1)+D_MAG
			Y2=Y1+0.2D0
			X4=X2/1.05D0
			X5=X2*1.05D0
			Y3=Y2+0.28D0
			IF (I LT 5) THEN BEGIN
				XV=[X1,X3]
				YV=[Y1,Y1]
				OPLOT, XV, YV, THICK=LTHICK, COLOR=COLOR_MAP(I)
				XV=[X2,X2]
				YV=[Y1,Y2]
				OPLOT, XV, YV, THICK=LTHICK, COLOR=COLOR_MAP(I)
				XV=[X2,X4,X5]
				YV=[Y3,Y2,Y2]
				POLYFILL, XV, YV, COLOR=COLOR_MAP(I)
			ENDIF ELSE BEGIN
				XV=[X1,X3]
				YV=[Y1,Y1]
				OPLOT, XV, YV, THICK=LTHICK
				OPLOT, [X2], [Y1], PSYM=8
			ENDELSE
		ENDFOR
          X1=2.00D0*XRANGE(0)
          X2=1.50D0*X1
          X3=X2*1.15D0
          Y1=YRANGE(0)-3.25D0+0.45D0*DOUBLE(I)
          Y2=Y1+0.12D0
          XV=[X1,X2]
          YV=[Y1,Y1]
		OPLOT, XV, YV, THICK=LTHICK, COLOR=COLOR_MAP(I)
		XYOUTS, X3, Y2, '!5'+GRB_DATE(I), ALIGNMENT=0.0,          $
			CHARSIZE=0.9*CSIZE, CHARTHICK=CTHICK, COLOR=COLOR_MAP(I)
		IF (I EQ 5) THEN BEGIN
			OPLOT, [SQRT(X1*X2)], [Y1], PSYM=8
		ENDIF
	ENDFOR
	IF (I_DEV EQ 1) THEN DEVICE, /CLOSE
ENDFOR
SET_PLOT, D_NAME
END





