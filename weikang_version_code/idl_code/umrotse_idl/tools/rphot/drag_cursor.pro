pro drag_cursor,xyarr,device=dvs,normal=norm,fullsize=full, $
	message=mess,show=show,silent=silent,colors=color,thick=thick, $
	initial=initial,leaveonrelease=leaveonrelease
;
; MODIFICATION HISTORY:
;	Matthew Kim, July 1994 : Modified from BOX_CURSOR
;-

device, get_graphics = old, set_graphics = 6  ;Set xor

if n_elements(color) ne 1 then col = !d.n_colors - 1 else col = color

if not keyword_set(thick) then thick = 1 else thick = thick > 1

if keyword_set(full) then begin
	if n_elements(full) ne 2 then begin
		print, 'DRAG_CURSOR : WARNING : illegal FULLSIZE keyword value.'
		print, '                                (must have 2 elements)'
		return
	endif else nx = float(full(0)) & ny = float(full(1))
endif
if keyword_set(full) or keyword_set(norm) or keyword_set(dvs) then devc = 1 $
else devc = 0

if keyword_set(mess) then begin
	print, "Drag Left button to draw box."
	print, "(Middle button to quit)."
	print, "Right button when done."
endif
abort = 0
if keyword_set(initial) then begin
	x0 = initial(0)
	y0 = initial(0)
endif else begin
	cursor, x0, y0, 1, device=devc	;Wait for a button
endelse
x1 = x0
y1 = y0
px = [x0, x1, x1, x0, x0] ;X points
py = [y0, y0, y1, y1, y0] ;Y values

if !err eq 1 then plots,px, py, col=col, device=devc, thick=thick, lines=0 $
else begin
	abort = 1
	goto, THEEND
endelse

while !err le 1 do begin
	old_button = !err
	cursor, x, y, 2, device=devc	;Wait for a button

	if old_button eq 1 then begin ;Dragging
		if !err eq 1 then begin
			plots,px,py,col=col,device=devc,thick=thick,lines=0
			empty				;Decwindow bug
			x1 = x
			y1 = y
			px = [x0, x1, x1, x0, x0] ;X points
			py = [y0, y0, y1, y1, y0] ;Y values
			plots,px, py, col=col, device=devc, thick=thick, lines=0
		endif else begin
			;print,'release'
			!err = 0
			if keyword_set(leaveonrelease) then goto,THEEND
		endelse
	endif else case !err of
		1 : begin
			plots,px,py,col=col,device=devc,thick=thick,lines=0
			empty				;Decwindow bug
			x0 = x
			x1 = x
			y0 = y
			y1 = y
			px = [x0, x1, x1, x0, x0] ;X points
			py = [y0, y0, y1, y1, y0] ;Y values
			plots,px,py,col=col,device=devc,thick=thick,lines=0
			end
		0 :

		else : begin
			plots,px,py,col=col,device=devc,thick=thick,lines=0
			empty				;Decwindow bug
			end
	endcase	

	wait, .01	;Don't hog it all
endwhile

THEEND:
device,set_graphics = old
if abort then begin
	xyarr = [x0,y0,x1,y1]
	return
endif

if keyword_set(show) then begin
	doleave = 1
	case show of
	2 : if !err ne 2 then doleave = 0
	4 : if !err ne 4 then doleave = 0
	else :
	endcase
	if doleave then plots,px,py,col=col,device=devc,thick=thick,lines=0
endif

if x0 gt x1 then begin 
	temp = x1
	x1 = x0
	x0 = temp
endif
if y0 gt y1 then begin 
	temp = y1
	y1 = y0
	y0 = temp
endif
xyarr = [x0,y0,x1,y1]

if keyword_set(full) then begin
	expcont = min([!d.x_vsize / nx, !d.y_vsize / ny])
	xyarr = xyarr / expcont
endif else if keyword_set(norm) then begin
	x0 = x0 / !d.x_vsize
	x1 = x1 / !d.x_vsize
	y0 = y0 / !d.y_vsize
	y1 = y1 / !d.y_vsize
	xyarr = [x0,y0,x1,y1]
endif

if not keyword_set(silent) then print, xyarr
return
end
