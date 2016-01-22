pro put_clr_scl2,x1,y1,range,inc,ysize=ysize,charsize=charsize,invert=invert,$
	nolabels=nolabels,_extra=extra_key
;+
; ROUTINE:    put_clr_scl2
;
; USEAGE:     PUT_CLR_SCL2,x1,y1,range[,inc,ysize=ysize,charsize=charsize]
;
; PURPOSE:   Draws a numbered color scale
;
;   INPUT:   
;
;  x1,y1        device coordinates of lower left hand corner of color bar
;
;  range        array which contains full range of physical values,
;               The number scale limits are computed fron min(range) and
;               max(range).
;  inc          increment step of the number scale in physical units
;
;   OPTIONAL KEYWORD INPUT:
;
;  charsize     character size on number scale. Defaults to !p.charsize.
;  ysize        vertical size of color bar in device units. 
;
;  invert	used to invert the color scale.
;
;  nolabels	Used to inhibit labels.
;
; AUTHOR:       Paul Ricchiazzi    oct92 
;               Earth Space Research Group, UCSB
;
; MODIFIED:	Jeff Bloch	From put_color_scale to handle
;				inverted color scales indicated by
;				the new keyword INVERT. Also default
;				character size taken from !p.charsize.
;
;				10/13/95	1.4
;-
;

if !p.charsize ne 0.0 then cs = !p.charsize else cs = 1.0
if keyword_set(charsize) eq 0 then charsize=cs

max_color=!d.n_colors-1
if keyword_set(ysize) eq 0 then ysize=max_color
amin=min(range)
amax=max(range)
if amax eq amin then amax=amin+1
s0=float(amin)
s1=float(amax)
s0=fix(s0/inc)*inc     & if s0 lt amin then s0=s0+inc
s1=fix(s1/inc)*inc     & if s1 gt amax then s1=s1-inc
;
frmt='(e9.2)'
if inc ne 0 then nzs=fix(alog10(inc*1.01)) else nzs = 0
if nzs lt 0 and nzs gt -4 then begin
  frmt='(f8.'+string(form='(i1)',-nzs+1)+')'  ; used on scale
endif
if nzs ge 0 and nzs le 3 then frmt='(f8.1)'
mg=6
smax=string(amax,form=frmt)
smax=strcompress(smax,/remove_all)
smin=string(amin,form=frmt)
smin=strcompress(smin,/remove_all)
lablen=strlen(smax) > strlen(smin)
if (!d.flags and 1) eq 0 then begin
  dx=20                       ; width of color bar
  x2=x1+dx
  x3=x2+2
  mg=6                        ; black out margin
  dy=ysize                    ; height of color bar
  y2=y1+dy
  ramp = indgen(y2-y1)
  if keyword_set(invert) then ramp=max(ramp)-ramp
  bw=dx+2*mg+charsize*lablen*!d.x_ch_size
  bh=dy+2*mg+charsize*!d.y_ch_size
  tv,replicate(0,bw,bh),x1-mg,y1-mg,/device   ;  black out background 
  tv,bytscl(replicate(1,dx) # ramp,top=max_color),x1,y1,/device
endif else begin
  xs=!d.x_vsize/700.          ; about 100 pixels per inch on screen
  ys=!d.y_vsize/700.
  dx=20*xs                    ; width of color bar
  x2=x1+dx
  x3=x2+2*xs
  mg=6*xs                     ; black out margin
  dy=ysize                    ; height of color bar
  y2=y1+dy
  ramp = indgen(y2-y1) 
  if keyword_set(invert) then ramp=max(ramp)-ramp

;  bw=dx+2*mg+charsize*lablen*!d.x_ch_size
;  bh=dy+2*mg+charsize*!d.y_ch_size
;  tv,replicate(0,2,2),x1-mg,y1-mg,xsize=bw,ysize=bh   ;  black out background 
  tv,bytscl(replicate(1,2) # ramp,top=max_color), $
     x1,y1,xsize=dx,ysize=dy
endelse
;
boxx=[x1,x2,x2,x1,x1]
boxy=[y1,y1,y2,y2,y1]
plots,boxx,boxy,/device
denom=amax-amin
;
nval=fix((s1-s0)/inc+.1)
if not keyword_set(nolabels) then begin
  for ival=0,nval do begin
    val=s0+inc*float(ival)
    ss=(val-amin)/denom
    if ss ge 0 and ss le 1 then begin
      yval=y1+(y2-y1)*ss
      sval=string(val,form=frmt)
      sval=strcompress(sval,/remove_all)
      plots,[x1,x2],[yval,yval],/device
      xyouts,x3,yval,sval,/device,charsize=charsize
    endif
  endfor
endif
;
end



