pro boxdata,width,x,y,clrs,device=devc,thick=thicks,hexagon=hexa,hair=hair, $
		gap=gap,circle=circ,_extra=_e
;+
; NAME:
;   BOX
; PURPOSE:
;   Draw box(es) or rectangle(s) in the graphics plane of specified width 
;   centered on the cursor, or at a specified position.  
; CALLING SEQUENCE:
;   BOX		;Prompt for box width, draw box @ cursor position
;   BOX,WIDTH	        ;Draw box of width WIDTH @ current cursor position
;   BOX,WIDTH,X,Y     ;Draw box at position X,Y
;   BOX,WIDTH,X,Y,COLOR     ;Also specify color intensity (0-15) 
; OPTIONAL INPUTS:           
;   WIDTH -  either a scalar giving the width of a box, or a 2 element
;            vector giving the length and width of a rectangle.
;   X  -  x position for box center, or a vector of x positions.
;   Y  -  y position for box center, or a vector of y positions.
;         If X and Y are not specified then program will draw
;         box at current cursor position
;   COLOR - color index, returned from COLORDEX
; OUTPUTS:
;   None
; SIDE EFFECTS:
;   A box or rectangle will be drawn on screen
;   For best results WIDTH should be odd.  (If WIDTH is even, the actual
;   size of the box will be WIDTH + 1.)
; RELATED PROCEDURES:
;   The color of a box in the graphics overlay can be set with GRCOL.   
; RESTRICTIONS:
;   BOX does not check whether box is off the edge of the screen
; REVISON HISTORY:
;   Written, W. Landsman   STX Co.           10-6-87
;   Modified for use with workstations/IDL V2.  M. Greason, STX Co.  4-26-90
;   Modified for multiple boxes.    Saul Perlmutter 10/28/90
;   Modified for device unit.    Matthew Kim  07/20/94
;   Modified for new deep color routines.   Rob Knop  1999-July-22
;-

if not keyword_set(devc) then devcv = 0 else devcv = 1
if not keyword_set(thicks) then thick = 1 else thick = thicks

npar = n_params(0)                         ;Get number of parameters
if npar lt 1 then read,'Enter box width (pixels) ',width
if n_elements(width) eq 2 then w = width/2. else w = [width,width]/2.
if npar lt 3 then cursor,x,y,0,device=devcv	;Get unroamed,unzoomed position

if keyword_set(gap) then gp = abs(gap) < 1. else gp = .0
if gp eq 1. then gp = .5

if keyword_set(hair) then begin
	if keyword_set(gp) then begin
		n = 4
		xarr = fltarr(2,n)
		yarr = fltarr(2,n)
		if hair eq 1 then begin
			xarr(*,0) = [-1,-gp] * w(0)
			yarr(*,0) = [0,0]
			xarr(*,1) = [1,gp] * w(0)
			yarr(*,1) = [0,0]
			xarr(*,2) = [0,0]
			yarr(*,2) = [-1,-gp] * w(1)
			xarr(*,3) = [0,0]
			yarr(*,3) = [1,gp] * w(1)
		endif else begin
			xarr(*,0) = [-1,-gp] * w(0)
			yarr(*,0) = [-1,-gp] * w(1)
			xarr(*,1) = [1,gp] * w(0)
			yarr(*,1) = [1,gp] * w(1)
			xarr(*,2) = [-1,-gp] * w(0)
			yarr(*,2) = [1,gp] * w(1)
			xarr(*,3) = [1,gp] * w(0)
			yarr(*,3) = [-1,-gp] * w(1)
		endelse
	endif else begin
		n = 2
		xarr = fltarr(2,n)
		yarr = fltarr(2,n)
		if hair eq 1 then begin
			xarr(*,0) = [-1,1] * w(0)
			yarr(*,0) = [0,0]
			xarr(*,1) = [0,0]
			yarr(*,1) = [-1,1] * w(1)
		endif else begin
			xarr(*,0) = [-1,1] * w(0)
			yarr(*,0) = [-1,1] * w(1)
			xarr(*,1) = [-1,1] * w(0)
			yarr(*,1) = [1,-1] * w(1)
		endelse
	endelse
endif else if keyword_set(circ) then begin
	if max(w) gt 4 then a = findgen(45)/44 else a = findgen(13)/12
	a = a*2*!pi
	xarr = cos(a) * w(0)
	yarr = sin(a) * w(1)
endif else if keyword_set(hexa) then begin
	r=1.732
	xarr = [ 1, 2, 1,-1,-2,-1, 1] * w(0) / 2
	yarr = [-r, 0, r, r, 0,-r,-r] * w(1) / 2
endif else begin
	xarr = [ 1, 1,-1,-1, 1] * w(0)
	yarr = [-1, 1, 1,-1,-1] * w(1)
endelse

nx = n_elements(x)
ny = n_elements(y)
nboxes = nx > ny

if npar lt 4 then clr = intarr(nboxes) + !top_color $
else clr = clrs                                        ;Set color

ncol = n_elements(clr)
if ncol eq 0 then begin
	if !d.name eq 'X' then begin
            if (!d.n_colors eq 16777216) then clr=16777215 $
            else clr=!top_color
        endif else clr = 0
	ncol = 1
endif else if (!d.n_colors le 256) then begin
    if ncol eq 1 then clr = clr < 255 else begin
        w = where(clr gt 255, j)          ;Make sure the color index is legal.
        if j gt 0 then clr(w) = 255       ;  (for 8-bit displays)
    endelse
endif

for i=0l,nboxes-1 do begin
	xuse = x(i < (nx-1))
	yuse = y(i < (ny-1))
	color = clr(i < (ncol-1))

	if keyword_set(hair) then begin
		for j = 0, n-1 do begin
			xs = xuse + xarr(*,j)
			ys = yuse + yarr(*,j)
		if devcv then plots,xs,ys,/device,color=color,thick=thick,_extra=_e $
		else plots,xs,ys,/data,color=color,thick=thick,_extra=_e
		endfor
	endif else begin
		xs = xuse + xarr              ;X edges of rectangle
		ys = yuse + yarr              ;Y edges of rectangle
		;Plot the box on the window.
		if devcv then plots,xs,ys,/device,color=color,thick=thick,_extra=_e $
		else plots,xs,ys,/data,color=color,thick=thick,_extra=_e
	endelse
endfor

return
end
