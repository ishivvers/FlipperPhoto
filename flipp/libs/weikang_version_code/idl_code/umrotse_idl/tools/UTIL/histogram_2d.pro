pro histogram_2d,x,y,hist,xrange,yrange,nxbins,nybins,silent=silent

;+
; NAME:
;	histogram_2d
;
;PURPOSE:
;	takes two dimentional data x,y and makes a histogram, 
;	hist,with hist_2d.  hist is a structure that also contains
;	the scaling parameters so one can display
;	it with the right x,y, scale etc.
;
;CALLING SEQUENCE:
;
;	-syntax histogram_2d,x,y,hist,xrange,yrange,nxbins,nybins,silent=silent
;
;INPUTS:
;	x ,y : the two one-dimentional arrays that you want histogrammed
;	
;OUTPUTS:
;	hist : the histogram structure contains 3 fields
;	.map (the 2D array) , .xrange, .yrange (the two ranges)
;	these ranges permit mapping from the data to the histogram map
;	and vice versa
;
;KEYWORDS:
;	xrange,yrange : the range to include data from
;	these are output and saved in the hist structure
;	the default is min, max
;	if these are flipped like [12,3]
;	it will use 3 as min and 12 as max and then flip the histogram
;	
;	nxbins, nybins : the number of bins for each dimention
;
;	silent : speak no evil	
;
;EXTERNAL CALLS:
;	none
;
;METHOD:
;	uses hist2d rather than the built in
;	IDL routine hist_2d because it has to work with floating
;	point numbers as well
;
;EXAMPLE:
;  IDL> histogram2d,radius,mag,hist,[0,6],[24,14],250,250
;  IDL> tvim2,hist.map,range=[0,100],xrange=hist.xrange,yrange=hist.yrange
;
;NOTES
;
;HISTORY:  written by David Johnston -University of Chicago
;       Physics Department 1999
;-

if n_params() eq 0 then begin
	print,'-syntax histogram_2d,x,y,hist,xrange,yrange,nxbins,nybins,silent=silent'
	return
endif

if n_elements(xrange) eq 0 then xrange=[min(x),max(x)]
if n_elements(yrange) eq 0 then begin
	yrange=[min(y),max(y)]
	if not keyword_set(silent) then begin
		print,'xrange= ',xrange
		print,'yrange= ',yrange
	endif
endif

if n_elements(nxbins) eq 0 then nxbins=100
if n_elements(nybins) eq 0 then nybins=100
;the default size

min1=xrange(0) < xrange(1)
min2=yrange(0) < yrange(1)
max1=xrange(0) > xrange(1)
max2=yrange(0) > yrange(1)

;this is because xrange may be something like [12.0, 3.0]
;in which case the caller wants 3,0 to be the min and
;12.0 to be the max BUT the output array should be flipped

w=where(x gt min1 and x lt max1 and y gt min2 and y lt max2,wif)
;the relevent data

if not keyword_set(silent) then print,wif,' in histogram'

xx=x(w)-min1
yy=y(w)-min2

rangex=float(abs(xrange(1)-xrange(0)))
rangey=float(abs(yrange(1)-yrange(0)))

hist2d,xx,yy,h,[0,rangex],[0,rangey],nxbins,nybins

h=float(h)
xrange=float(xrange)
yrange=float(yrange)

if xrange(0) gt xrange(1) then h=rotate(h,5)
;flip x
if yrange(0) gt yrange(1) then h=rotate(h,7)
;flip y

hist={map:h,xrange:xrange,yrange:yrange}
;make the hist structure

return
end




