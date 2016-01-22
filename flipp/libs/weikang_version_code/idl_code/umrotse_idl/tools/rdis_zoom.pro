pro rdis_zoom, image, pls, newpls=newpls


; Name:
;	rdis_zoom
; Purpose:
;	Allows zooming in rdis
;
; Calling sequence:
;	rdis_zoom, image, xmin, xmax, ymin, ymax
;
; Inputs:
;	Points selected by user using cursor
;
; Optional output arrays:
;
;
; Revision history:
;	Andrew Waltman   UM   5/1/98
;
 
 On_error,2              ;Return to caller
	if N_params() eq 0 then begin
        print,'Syntax-rdis_zoom, image, pls'
 return 
 
 endif
	rdis_setup, pls
; Input keyword parameter
	cursor, x,y, /data, /up 
;while (!mouse.button ne 4) do begin
	cursor, x1, y1, /data, /up	
; endwhile


 if (x1 le x) then begin
	pls.xmn=x1
	pls.xmx=x
 endif else begin
	pls.xmn=x
	pls.xmx=x1
 endelse

 if (y1 le y) then begin
	pls.ymn=y1
  	pls.ymx=y
 endif else begin
	pls.ymn=y	    
	pls.ymx=y1
 endelse
 if keyword_set(pls2) then begin
	
 rdis, image, pls
 
 return
 
 end









































