pro frame,a,xysteps,invert=invert,zero=zero,span=span,nsigz=zsig,nsigs=ssig, $
	top=topv,align=strict, window_scale=window_scale,noaspect=noaspect,$
	interp=interp,cubic=cubic, background=background,color=color,$
	nocontour=nocont,nogrey=nogrey, c_colors=c_col,c_linestyle=c_lin,$
	c_thick=c_thi,full=full, follow=follow,levels=levels,nlevels=nlev,$
	offset=offsets, xtitle=xtitle,ytitle=ytitle,title=title,$
	subtitle=subtitle,noerase=noer,nodisplay=nodisplay,noframe=noframe,$
	quiet=quiet,outimage=bim,bim=outimage,hflip=hflip
;+
; NAME:
;	FRAME
; PURPOSE:
;	Overlay an image and a contour plot.
; CATEGORY:
;	General graphics.
; CALLING SEQUENCE:
;	frame, IMAGE[,X,Y]
; INPUTS:
;	IMAGE = 2 dimensional array to display.
; OPTIONAL INPUTSL
;	X = 1 dimensional array of x-axis values.
;	Y = 1 dimensional array of y-axis values.
; KEYWORD PARAMETERS:
;	/WINDOW_SCALE = set to scale the window size to the image size,
;		otherwise the image size is scaled to the window size.
;		Ignored when outputting to devices with scalable pixels.
;	/NOASPECT = set not to retain image's aspect ratio.  Assumes square
;		pixels.  If /WINDOW_SCALE is set, the aspect ratio is
;		retained.
;	/INTERP = set to bi-linear interpolate if image is resampled.
;	/NOCONTOUR = set to just display framed image.
;	/INVERT = set to invert the image scale, ie image=255-image
;	plus IDL graphics keywords: xtitle,ytitle,subtitle,title,background.
;	OUTIMAGE = outputs the actual displayed byte array that frame
;		produces internally.  Useful if you want to scale an
;		image or something.
;	/NODISPLAY = doesn't display the image.
;	/QUIET = Silence is golden
; OUTPUTS:
;	No explicit outputs.
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	The currently selected display is affected.
; RESTRICTIONS:
;	None that are obvious.
; PROCEDURE:
;	If the device has scalable pixels then the image is written over
;	the plot window.
; MODIFICATION HISTORY:
;	Adapted from IMAGE_CONT to CONT_IMAGE
;	D. L. Windt, AT&T Bell Laboratories, Nov 1989.
;	Adapted from CONT_IMAG to FRAME by DEEPSEARCH GROUP of LBL, 1992
;	Added the contour function back, Matthew Kim, LBL, Jul 1994
;	Outimage added by Robert Quimby, LBL
;-

on_error,2

sz = size(a)			;Size of image
if sz(0) lt 2 then message,'FRAME -- parameter not 2D'
if min(sz(1:2)) lt 2 then message, 'FRAME -- x or y size is too small'

if keyword_set(xtitle) then xtitle=xtitle else xtitle=!x.title
if keyword_set(ytitle) then ytitle=ytitle else ytitle=!y.title
if keyword_set(title) then title=title else title=!p.title
if not keyword_set(subtitle) then subtitle=!p.subtitle
if keyword_set(background) then back=background else back=!p.background

if n_elements(topv) eq 1 and keyword_set(topv) then begin
top = topv < 255
top = byte(top)
if top le 0 then top = !top_color
endif else top = !top_color

if !d.n_colors gt 16000000 then top = 255
case n_elements(offsets) of
0 : offset = [0,0]
1 : offset = [offsets,offsets]
else : offset = offsets(0:1)
endcase
case n_elements(xysteps) of
0 : xystep = [1.,1.]
1 : xystep = [xysteps,xysteps]
else : xystep = xysteps(0:1)
endcase
ax = findgen(sz(1)) * xystep(0) + offset(0)
ay = findgen(sz(2)) * xystep(1) + offset(1)
xran = [ax(0), ax(sz(1)-1)] + 0.5 * xystep * [-1, 1]
yran = [ay(0), ay(sz(2)-1)] + 0.5 * xystep * [-1, 1]
if keyword_set(hflip) then begin
    temp=yran
    yran[0]=temp[1]
    yran[1]=temp[0]
endif

if not keyword_set(nogrey) then begin
	if n_elements(zero) eq 0 and n_elements(span) eq 0 then begin
		sky,a,skymode,skysig,silent=quiet
		if n_elements(zsig) ne 1 then zsig=-1.5
		if n_elements(ssig) ne 1 then ssig=3.
		zero = skymode + zsig*skysig
		span = ssig*skysig
	endif
	if n_elements(span) eq 0 then span = 255
	if n_elements(zero) eq 0 then zero = 0.0
endif

if keyword_set(full) then begin
	oxm = !x.margin
	oym = !y.margin
	!x.margin = 0
	!y.margin = 0
endif

;set window used by contour
if n_elements(noer) eq 0 then noer = 0
if not keyword_set(nodisplay) then $
  contour,[[0,0],[1,1]],/nodata,back=back,xstyle=4,ystyle=4,noerase=noer

if keyword_set(full) then begin
	!x.margin = oxm 
	!y.margin = oym
endif

px = !x.window * !d.x_vsize	;Get size of window in device units
py = !y.window * !d.y_vsize
swx = px(1)-px(0)		;Size in x in device units
swy = py(1)-py(0)		;Size in Y
six = float(sz(1))		;Image sizes
siy = float(sz(2))
aspi = six / siy		;Image aspect ratio
aspw = swx / swy		;Window aspect ratio
f = aspi / aspw			;Ratio of aspect ratios

if !d.flags then begin		;Scalable pixels?
	if not keyword_set(noaspect) then begin	;Retain aspect ratio?
			;Adjust window size
		if f ge 1.0 then swy = swy / f else swx = swx * f
	endif
	if not keyword_set(nogrey) then begin
		bim = bytscl(a,min=zero,max=zero+span)
		if keyword_set(invert) then bim = 255b - bim
                if keyword_set(hflip) then bim=rotate(bim,7)
		if not keyword_set(nodisplay) then tv,bim,px(0),py(0),$
			xsize = swx, ysize = swy, /device
	endif
	if n_elements(color) ne 1 then color = 0
endif else begin	;Not scalable pixels
	if keyword_set(window_scale) then begin ;Scale window to image?
		bim = bytscl(a,min=zero,max=zero+span,top=top)
		swx = six               ;Set window size from image
		swy = siy
	endif else begin
		if not keyword_set(noaspect) then begin	;Scale window
			if f ge 1.0 then swy = swy / f else swx = swx * f
		endif		;aspect
	endelse
	interptype=0
	if keyword_set(interp) then interptype = 1
	if keyword_set(cubic) then interptype = 2
	if not keyword_set(nogrey) then begin
		bim = bytscl(poly_2d(a,[0,0,six/swx,0],[0,siy/swy,0,0], $
		interptype,swx,swy),min=zero,max=zero+span,top=top)
		if keyword_set(invert) then bim = top - bim
                if keyword_set(hflip) then bim=rotate(bim,7)
		if not keyword_set(nodisplay) then $
			tv,bim,px(0),py(0)      ;Output image
		if keyword_set(outimage) then outimage=bim
	endif
	if n_elements(color) ne 1 then color = !d.n_colors - 1
endelse

if n_elements(nocont) gt 0 then begin
	 if keyword_set(nocont) then docontour = 0 else docontour = 1
endif else begin
	docontour = n_elements(c_col) + n_elements(c_lin) + $
		n_elements(c_thi) + n_elements(nlev) + n_elements(levels)
	if docontour gt 0 then docontour = 1
endelse

if keyword_set(noframe) then xystl=5 else xystl=1 
if docontour then begin
	if n_elements(c_col) eq 0 then begin
		if !d.flags then c_col = 0 else c_col=255
	endif
	if n_elements(c_lin) eq 0 then c_lin=0
	if n_elements(c_thi) eq 0 then c_thi=1
	if n_elements(nlev) ne 1 then nlevel=0 else nlevel = nlev

	if n_elements(levels) gt 0 then begin
	  if not keyword_set(nodisplay) then $
		contour,a,ax,ay,/noerase,xran=xran,yran=yran, $
		pos=[px(0),py(0),px(0)+swx,py(0)+swy],/dev, $
 		c_col=c_col,c_lin=c_lin,c_thi=c_thi,color=color, $
       	levels=levels,follow=keyword_set(follow),ystyl=xystl, $
       	xtitle=xtitle,ytitle=ytitle,title=title,subtitle=subtitle,xstyl=xystl
	endif else if not keyword_set(nodisplay) then $
		contour,a,ax,ay,/noerase,xran=xran,yran=yran, $
		pos=[px(0),py(0),px(0)+swx,py(0)+swy],/dev, $
		c_col=c_col,c_lin=c_lin,c_thi=c_thi,color=color, $
		nlev=nlevel,follow=keyword_set(follow),ystyl=xystl, $
		xtitle=xtitle,ytitle=ytitle,title=title,subtitle=subtitle,xstyl=xystl
 
endif else if not keyword_set(nodisplay) then $
	contour,a,ax,ay,/noerase,/nodata,color=color,xran=xran, $
	pos=[px(0),py(0),px(0)+swx,py(0)+swy],/dev,yran=yran,ystyl=xystl, $
	xtitle=xtitle,ytitle=ytitle,title=title,subtitle=subtitle,xstyl=xystl

return
end


