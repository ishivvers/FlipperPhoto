pro ploth,x,y,hist,xrange=xrange,yrange=yrange,_extra=ex,$
nxbins=nxbins,nybins=nybins,range=range,$
log=log,sqrt=sqrt,median=median,smooth=smooth,g_smooth=g_smooth,silent=silent
;+
; NAME:		
;		ploth
;
;PURPOSE:	like plotting points but makes a two dimentional
;		histogram first and displays that as an image with tvim2
;		and returns a histogram structure
;
;CALLING SEQUENCE:
;	 ploth,x,y,hist,median=3
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
;	range : the display range given to tvim2
;		default is to go around the mean by three sigma
;		uses sigma clipping algorithm
;
;	log, sqrt : use log or square root scaling
;
;	median : do a median filter smoothing on a square this size
;		should be an odd integer
;
;	smooth : so boxcar average smoothing on a square this size
;		should be an odd integer	
;	
;	g_smooth : do gaussian smoothing with a gaussian of fwhm
;		of this amount. Should be a float > 1.0.
;
;	silent : speak no evil	
;
;EXTERNAL CALLS:
;
;	histogram_2d
;	tvim2
;	make_gaussian
;
;METHOD: call histogram_2d which calls hist_2d (a built in IDL routine)
;
;EXAMPLE
;
;NOTES
;
;	if median,smooth or g_smooth are set the resultant hist.map
;	will be smoothed upon output, though if log or sqrt are set they 
;	hist.map will NOT be scaled as it is displayed
;
;HISTORY:  written by David Johnston -University of Chicago 
;       Physics Department 1999
;-

if n_params() eq 0 then begin
	print,'-syntax ploth,x,y,hist,xrange=xrange,yrange=yrange,_extra=ex'
	print,'nxbins=nxbins,nybins=nybins,range=range,'
	print,'log=log,sqrt=sqrt,median=median,smooth=smooth,'
	print,'g_smooth=g_smooth,silent=silent'
	return
endif
 
histogram_2d,x,y,hist,xrange,yrange,nxbins,nybins,silent=silent
;the main call

if n_elements(range) eq 0 then begin
	map=median(hist.map,3)
        mom=moment(map)
        avg=median(map)
        sig=sqrt(mom(1))
	nsig1=3.0
	nsig2=7.0
	if keyword_set(sqrt) then begin
		nsig1=3.0
		nsig2=9.0
	endif
	if keyword_set(log) then begin
		range=[min(map),max(map)]
	endif else begin
		range=[(avg-nsig1*sig > 0),(avg+nsig2*sig > 2)]
	endelse

        range=[(avg-nsig1*sig > 0),(avg+nsig2*sig > 2)]
        if not keyword_set(silent) then print,'RANGE IS:','     ',range
	
	;get a decent display range if none is given
endif

if n_elements(median) gt 0 then begin
	hist.map=median(hist.map,median)
	;median filter if desired
endif

if n_elements(smooth) gt 0 then begin
	hist.map=smooth(hist.map,smooth,/edge_tr)
	;smooth if desired
endif

if n_elements(g_smooth) gt 0 then begin
	make_gaussian,gauss,size=[2.0*g_smooth,2.0*g_smooth],$
	fwhm=g_smooth,counts=1.0
	hist.map=convol(hist.map,gauss,/edge_tr)
	;make a gaussian and convolve with it
endif

map=hist.map
;makes a copy here to be displayed
;will differ from hist.map iff keywords log or sqrt are set

if keyword_set(log) then begin
	map=alog10(map > .0001)
	range=alog10(range > .0001 )
	;log scale ?	
endif

if keyword_set(sqrt) then begin
	map=sqrt(map)
	range=sqrt(range)	
	;square root scale
endif


tvim2,map,xrange=hist.xrange,yrange=hist.yrange,range=range,_extra=ex

return
end


