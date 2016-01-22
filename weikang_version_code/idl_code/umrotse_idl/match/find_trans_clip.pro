pro find_trans_clip,x1,y1,x2,y2,goodness,kx,ky,nsig,astrerr,SHOW=show,$
order=order
;+
; NAME:
;find_trans_clip
;
; PURPOSE:
;Does a sigma clipping algoritm to settle on a transformation between 
;two sets of points. The transformation is computed with find_trans 
;(see find_trans for a desciption of the transformation). Then the 
;transfomed points that don't transform "correctly" are thrown out 
;and the transformation is recomputed untill it is a good enough fit.
;The details are in the program. There are a few arbitrary 
;parameters that may be changed or rather handed as variables.
;
; CALLING SEQUENCE:
;find_trans_clip,x1,y1,x2,y2,goodness,kx,ky,nsig,astrerr,order=order,SHOW=show
;
; INPUTS:
;x2,y2: the points that x1,y1 are to be a function of
;x1,y1: the points that are a function of x2,y2
;goodness: this array comes out of the vote array from
;	   get_votearr. It is measure of the sureness that the specific 
;          x1(i),y1(i) correspond to the x2(i),y2(i). It is used to
;	   get the best points first to eliminate false matches. 
;nsig: once a measure of the median (or x percentile is made) and
;      called the sigma for the astrometry error, the clip is made
;      at nsig*median
;
; OUTPUTS:
;kx,ky: one way of reporting the transformation. This is the way that 
;       polywarp (or find_trans) spits out the transformation.
;astrerr: this is the final astrometric error for the final points
;         that remain. It is really a lower limit for the 
;         real astrometric error for the total transfomation.
;         It is computed as the rms of the difference between
;         (x2,y2) and trans(x1,y1).
;
; OPTIONAL KEYWORD PARAMETERS:
;show: this will show the astrometric errors for each loop
;in the transformation by simply plotting them. This is good
;for actually seeing that the method is converging to a good fit
;like .25 (pixels).
;
;order: this is the order of the transformation found by polywarp
;	default is first order ie. linear      
; PROCEDURES CALLED:
;find_trans,transform,percentile
; REVISION HISTORY:
;David Johnston -University of Michigan
;-
 On_error,2                                      ;Return to caller

 if N_params() LT 4 then begin
    print,'Syntax - '
    return
 endif


num=n_elements(x1)
if num lt 4 then begin
	print, 'too few for polywarp'
 	return
endif
if num eq 4 then begin
	find_trans,x1,y1,x2,y2,kx,ky,order,show=show
	return
endif

if n_elements(order) eq 0 then order=1
bsort=sort(goodness)
bobjm1=bsort[(num-10) > 0 :*]
bobjm2=bsort[(num-10) > 0 :*]
xm1=x1(bobjm1)
ym1=y1(bobjm1)
xm2=x2(bobjm2)
ym2=y2(bobjm2)
find_trans,xm1,ym1,xm2,ym2,kx,ky,order,show=show
;was done with the 10 or num best matches
xm1=x1
ym1=y1
xm2=x2
ym2=y2
kmap,xm2,ym2,x,y,kx,ky
d=abs(complex(x-xm1,y-ym1))
if keyword_set(show) then plot,d,psym=1
keep=where(d lt 10.0,k)
if k lt num then print,num-k,' thrown out on first run'
if k lt 4 then begin
	print,'bad matches-abort'
	return
endif 

xm1=xm1(keep)
ym1=ym1(keep)
xm2=xm2(keep)
ym2=ym2(keep)
num=n_elements(xm1)

per=.6
stop=0
loop=0
while stop ne 1 do begin	
	if keyword_set(show) then $
	print,'num used ',num
	find_trans,xm1,ym1,xm2,ym2,kx,ky,order,show=show
	kmap,xm2,ym2,x,y,kx,ky
	d=abs(complex(x-xm1,y-ym1))
	percentile,d,per,pin,p
	if keyword_set(show) then plot,d,psym=7
	cut=nsig*p
	keep=where(d le cut,kept)
	if kept lt 9 then begin
		if keyword_set(show) then $
		print,' finished in loop',loop,' -by too few'
		stop=1
	endif else begin
		if kept eq num then begin
			if keyword_set(show) then $
			print,'finished in loop',loop,'-by no further clips'
			stop=1
		endif
		xm1=xm1(keep)
		ym1=ym1(keep)
		xm2=xm2(keep)
		ym2=ym2(keep)
		num=n_elements(xm1)
		loop=loop+1
	endelse
endwhile
astrerr=mean(abs(d))
return
end

