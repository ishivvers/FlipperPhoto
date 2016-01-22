pro compare_badpix,badpix,xvals,yvals,radius,bpflags,bprms,check_sat=check_sat
;+
; NAME:	COMPARE_BADPIX
;
; CALLING SEQUENCE:	compare_badpix,badpix,xvals,yvals,radius,bpflags
;
; INPUTS:	badpix: a badpixel structure
;		xvals,yvals: the x and y positions of the objects
;		radius: the radius around an object center that will count
;			if a bad pixel is there
;
; OUTPUTS:	bpflags: the bad pixel type on top of the object
;		bprms: the rms value of the bad pixel
;			These are initialized if they do not already exist
;	
;
; INPUT KEYWORDS:
;		check_sat: check if a pixel is near saturation, and scale
;			the rms accordingly
;			
; PROCEDURE:	Finds what types of bad pixels are near your objects.
;			High pixel: Type 1
;			Unstable pixel: Type 2
;			"Strange" pixel, with 1 anomolous value: Type 4
;		If an object has > 1 bad pixel, then the outputs are:
;			bpflags: the flag of the pixel with the largest rms
;			bprms: the rms values added in quadrature
;
; REVISION HISTORY:  
;	Eli Rykoff		UM	5/24/00
;					Created
;
;******************************************************************************
;-



if n_params() eq 0 then begin
    print,'syntax-compare_badpix,badpix,xvals,yvals,radius,bpflags,bprms,check_sat=check_sat'
    return
endif

if n_elements(xvals) ne n_elements(yvals) then begin
    print,'Error: We must have equal length xval and yval arrays.'
    return
endif

bpstruct=badpix		; make a local copy

if ((size(bpflags))(0) eq 0) then begin
   bpflags=replicate(byte(0),n_elements(xvals))
   print,'initflags...'
endif

if ((size(bprms))(0) eq 0) then begin
   bprms=replicate(0.0,n_elements(xvals))
   print,'initrms...'
endif

tempflags=replicate(byte(0),n_elements(xvals))

close_match,bpstruct.x,bpstruct.y,xvals,yvals,m1,m2,radius,3,miss,/circle

;m2 gives us the xval indices...m1 the bpstruct indices

if (m1(0) eq -1) then begin
   return
endif

if keyword_set(check_sat) then begin
   sat_level=16383.
   close_sat_pixels=where(bpstruct(m1).median gt (sat_level-sqrt(sat_level)),cscount)
   if (cscount gt 0) then begin
     underest_rms=where(bpstruct(m1(close_sat_pixels)).rms lt sqrt(bpstruct(m1(close_sat_pixels)).median),urcount)
     if (urcount gt 0) then begin
       bpstruct(m1(close_sat_pixels(underest_rms))).rms = sqrt(bpstruct(m1(close_sat_pixels(underest_rms))).median)
     endif
   endif
endif


for i=0l,n_elements(m1)-1 do begin
  if (tempflags(m2(i)) eq 0) then begin
     tempflags(m2(i))=bpstruct(m1(i)).type
     bprms(m2(i))=bpstruct(m1(i)).rms
  endif else begin
     if (bpstruct(m1(i)).rms gt bprms(m2(i))) then begin
       tempflags(m2(i)) = bpstruct(m1(i)).type
     endif
     bprms(m2(i))=sqrt(bprms(m2(i))^2+float(bpstruct(m1(i)).rms)^2) 
  endelse
endfor


bpflags=bpflags or tempflags

return

end

