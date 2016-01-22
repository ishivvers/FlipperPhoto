pro tvim2,a,scale=scale,range=range,xrange=xrange,yrange=yrange,aspect=aspect,$
title=title,xtitle=xtitle,ytitle=ytitle,noframe=noframe,nolabels=nolabels,$
subtitle=subtitle,_extra=extra_key,invbw=invbw
;+
; NAME:   
;    tvim2
;
; USEAGE:   tvim2,a
;
;           tvim2,a,title=title,xtitle=xtitle,ytitle=ytitle,$
;                              xrange=xrange,yrange=yrange,subtitle=subtitle,$
;                              scale=scale,range=range,noframe=noframe,aspect
;
; PURPOSE:  Display an image with provisions for
;               
;            1. numbered color scale 
;            2. plot title
;            3. annotated x and y axis 
;            4. simplified OPLOT capability
;
; INPUT    a           image quantity
;
; Optional keyword input:
;
;	   **NOTE**: This routine now uses the _extra mechanism to pass
;		     keywords for put_clr_scl2.
;
;          title       plot title
;
;          xtitle      x axis title
; 
;          ytitle      y axis title
;
;	   subtitle    x axis subtitle
;
;          xrange      array spanning entire x axis range.  
;                      NOTE:  TVIM2 only uses XRANGE(0) and
;				XRANGE(N_ELEMENTS(XRANGE)-1).
;
;          yrange      array spanning entire y axis range.  
;                      NOTE:  TVIM2 only uses YRANGE(0) and
;				YRANGE(N_ELEMENTS(YRANGE)-1).
;
;          scale       if set draw color scale.  SCALE=2 causes steped
;                      color scale
;
;          range       two or three element vector indicating physical
;                      range over which to map the color scale.  The
;                      third element of RANGE, if specified, sets the
;                      step interval of the displayed color scale.  It
;                      has no effect when SCALE is not set. E.g.,
;                      RANGE=[0., 1., 0.1] will cause the entire color
;                      scale to be mapped between the physical values
;                      of zero and one; the step size of the displayed 
;                      color scale will be set to 0.1.
;
;          aspect      the x over y aspect ratio of the output image
;                      if not set aspect is set to (size_x/size_y) of the
;                      input image.  
;
;          noframe     if set do not draw axis box around image
;
;	   nolabels    If set, inhibits labels on plot and scale.
;	  
;	   invbw       To invert the color table ie. array=!d.n_colors-1-array
;		       before calling tv. The deault is invbw=1 for the
;		       postscript device and invbw=0 else.		
;
;
; SIDE EFFECTS:        Setting SCALE=2 changes the color scale using the
;                      STEP_CT procedure.  The color scale may be returned
;                      to its original state by the command, STEP_CT,/OFF
;
; PROCEDURE            TVIM first determins the size of the plot data window
;                      with a dummy call to PLOT.  When the output device is
;                      "X", CONGRID is used to scale the image to the size of
;                      the available data window.  Otherwise, if the output
;                      device is Postscript, scaleable pixels are used in the
;                      call to TV.  PUT_COLOR_SCALE draws the color scale and
;                      PLOT draws the x and y axis and titles.
;
; DEPENDENCIES:        PUT_COLOR_SCALE, STEP_CT
;
; AUTHOR:              Paul Ricchiazzi    oct92 
;                      Earth Space Research Group, UCSB
;
;                      Modified version of TVIM by Jeff Bloch, SST-9, LANL
;
;			1.12	10/13/95
;		       Added invbw keyword to invert the color table. 
;		       The default is invbw=1 for postscript and invbw=0 else.
;		       Changed a line to use bytscl function.
;				David Johnston UChicago July 1999
;                     			
;
;-
	
if n_elements(invbw) eq 0 then begin
	if (!d.flags and 1) then begin
		;device is postscript so reverse color by default
		invbw=1
	endif else invbw=0
endif 

sz=size(a)
nx=sz(1)
ny=sz(2)
nxm=nx-1
nym=ny-1
plot, [0,1],[0,1],/nodata,xstyle=4,ystyle=4
px=!x.window*!d.x_vsize
py=!y.window*!d.y_vsize
xsize=px(1)-px(0)
ysize=py(1)-py(0)
if keyword_set(scale) then xsize=xsize-50*!d.x_vsize/700.
if keyword_set(aspect) eq 0 then aspect=float(nx)/ny
if xsize gt ysize*aspect then xsize=ysize*aspect else ysize=xsize/aspect 
px(1)=px(0)+xsize
py(1)=py(0)+ysize
;
;
max_color=!d.n_colors-1
;
if keyword_set(title) eq 0 then title=''
amax=float(max(a))
amin=float(min(a))
if amin eq amax then amax=amin+1
; print, 'a      min and max  ',   amin,amax
if keyword_set(range) eq 0 then range=[amin,amax]
if range(0) eq range(1) then range(1)=range(1)+1
;
;     draw color scale
;
if keyword_set(scale) then begin
  s0=float(range(0))
  s1=float(range(1))
  if s0 gt s1 then invert = 1
  if n_elements(range) eq 3 then begin
    s2=range(2)
    range=range(0:1)
  endif else begin
    rng=alog10(abs(s1-s0))
    if rng lt 0. then pt=fix(alog10(abs(s1-s0))-.5) else $
	pt=fix(alog10(abs(s1-s0))+.5)
    s2=10.^pt
    tst=[.05,.1,.2,.5,1.,2.,5.,10]
    ii=where(abs(s1-s0)/(s2*tst) le 16)
    s2=s2*tst(ii(0))
  endelse 
  xs=px(1)+9*!d.x_vsize/700.
  ys=py(0)
  ysize=py(1)-py(0)
  if scale eq 2 then step_ct,[s0,s1],s2
endif
;

;aa=(max_color-1)*((float(a)-range(0))/(range(1)-range(0)) > 0. < 1.)
aa=bytscl(a,min=range(0),max=range(1),top=max_color)

if invbw eq 1 then begin
	aa=max_color-aa
endif

;
if (!d.flags and 1) eq 0 then begin
  tv,congrid(aa,xsize,ysize),px(0),py(0)
  pos=[px(0),py(0),px(1),py(1)]
endif else begin
  pos=[px(0),py(0),px(1),py(1)]
  tv,aa,px(0),py(0),xsize=xsize,ysize=ysize,/device
endelse

if keyword_set(scale) then begin
	if (total(!p.multi(1:2)) gt 4)  then charsize=0.5
	if (total(!p.multi(1:2)) gt 8)  then charsize=0.25
	put_clr_scl2,xs,ys,range,s2,ysize=ysize,$
	invert=invert,nolabels=nolabels,charsize=charsize,$
	_extra=extra_key
endif
;
if (keyword_set(xtitle) eq 0) then xtitle=''
if (keyword_set(ytitle) eq 0) then ytitle=''
if (keyword_set(subtitle) eq 0) then subtitle=''
if (keyword_set(xrange) eq 0) then $
  xrng=[-0.5,nxm+0.5] else xrng=[xrange(0), xrange(n_elements(xrange)-1)]
if (keyword_set(yrange) eq 0) then $
  yrng=[-0.5,nym+0.5] else yrng=[yrange(0), yrange(n_elements(yrange)-1)]
if keyword_set(noframe) or keyword_set(nolabels) then begin
  plot,[0,0],[0,0],xstyle=5,ystyle=5,title=title,xtitle=xtitle,ytitle=ytitle, $
       subtitle=subtitle,xrange=xrng,yrange=yrng,position=pos,/noerase,/device,/nodata
endif else begin
  plot,[0,0],[0,0],xstyle=1,ystyle=1,title=title,xtitle=xtitle,ytitle=ytitle, $
       subtitle=subtitle,xrange=xrng,yrange=yrng,position=pos,/noerase,/device,/nodata
endelse

if (not keyword_set(noframe)) and keyword_set(nolabels) then begin
	axis,xaxis=1,xtickname=strarr(10)+" "
	axis,xaxis=0,xtickname=strarr(10)+" "
	axis,yaxis=1,ytickname=strarr(10)+" "
	axis,yaxis=0,ytickname=strarr(10)+" "
endif
;
end





