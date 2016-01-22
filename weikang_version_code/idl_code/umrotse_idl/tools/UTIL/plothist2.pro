PRO plothist2, arr, xhist,yhist, BIN=bin, PSYM = psym, overplot=overplot ,$
           ANONYMOUS_ = dummy_,fill=fill,fcolor=fcolor, _EXTRA = _extra
;+
; NAME:
;	PLOTHIST2
; PURPOSE:
;	Plot the histogram of an array with the corresponding abcissa.
;
; CALLING SEQUENCE:
;	plothist2, arr, xhist, yhist, [, BIN=bin,   ... plotting keywords]
;
; INPUTS:
;	arr - The array to plot the histogram of.   It can include negative
;		values, but non-integral values will be truncated.              
;
; OPTIONAL OUTPUTS:
;	xhist - X vector used in making the plot  
;		( = indgen( N_elements(h)) * bin + min(arr) )
;	yhist - Y vector used in making the plot  (= histogram(arr/bin))
;
; OPTIONAL INPUT KEYWORDS:
;	BIN -  The size of each bin of the histogram,  scalar (not necessarily
;		integral).  If not present (or zero), the bin size is set to 1.
;
;		Any input keyword that can be supplied to the PLOT procedure
;		can also be supplied to PLOTHIST.
; EXAMPLE:
;	Create a vector of 1000 values derived from a gaussian of mean 0,
;	and sigma of 1.    Plot the histogram of these value with a bin
;	size of 0.1
;
;	IDL> a = randomn(seed,1000)
;	IDL> plothist2,a, bin = 0.1,/overplot
;
; MODIFICATION HISTORY:
;	Written     W. Landsman            January, 1991
;	Add inherited keywords W. Landsman        March, 1994
;	Use ROUND instead of NINT  W. Landsman   August, 1995
;       Keyword to overplot added David Johnston U of Mich 1997
;	keyword to fill added by David Johnston U of Mich 1997
;-
;			Check parameters.
 On_error,2

 if N_params() LT 1 then begin   
	print, 'Syntax - plothist, arr, [ xhist, yhist , BIN=,...plot_keywords]'
	return
 endif

 if N_elements( arr ) LT 2 then message, $
      'ERROR - Input array must contain at least 2 elements'
 arrmin = min( arr, MAX = arrmax)
 if ( arrmin EQ arrmax ) then message, $
       'ERROR - Input array must contain distinct values'

 if not keyword_set(BIN) then bin = 1. else bin = float(abs(bin))

; Compute the histogram and abcissa.

 y = round( ( arr / bin))
 yhist = histogram( y )
 N_hist = N_elements( yhist )
 xhist = lindgen( N_hist ) * bin + min(y*bin) 
 if not keyword_set(PSYM) then psym = 10         ;Default histogram plotting

 if not keyword_set(XRANGE) then xrange = [ xhist(0) ,xhist(N_hist-1) ]

 if not keyword_set(overplot) then begin
      plot, [xhist(0) - bin, xhist, xhist(n_hist-1)+ bin] , [0,yhist,0],  $ 
        PSYM = psym, _EXTRA = _extra 
 endif else begin
      oplot, [xhist(0) - bin, xhist, xhist(n_hist-1)+ bin] , [0,yhist,0], $
	PSYM=psym, _EXTRA=_extra
 endelse
 if keyword_set(fill) then begin
 	color=167
	
number=n_elements(xhist)
	if keyword_set(fcolor) eq 0 then fcolor=150
	bin2=bin/2.0
	nn=2*number+2
	px=fltarr(nn)
	py=fltarr(nn)
	for i=0,number-1 do begin
		px(2*i+1)=xhist(i)-bin2
		px(2*i+2)=xhist(i)+bin2
		py(2*i+1)=yhist(i)
		py(2*i+2)=yhist(i)
	endfor
	px(0)=xhist(0)
	px(nn-1)=xhist(number-1)+bin2
	py(0)=0
	py(nn-1)=0
	polyfill,px,py,color=fcolor
 endif

	
 end





