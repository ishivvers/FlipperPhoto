pro scircle, list, index=index, radius=radius
;+
; NAME:
;       SCIRCLE
; PURPOSE:
;	Allow one to easily circle objects from a sextractor structure
;
; CALLING SEQUENCE:
;       scircle, list
;
; INPUTS:
;	list: a sextractor output structure
;	  Must contain
;		x_image,y_image
;       
; OUTPUTS:
;	circles on the plot
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
;	index: an index of the ones you want circled
;	radius: the radius you want to use
; 
; PROCEDURE: This just creates circles on the image
;
; REVISION HISTORY:
;	Tim McKay	UM 	4/27/98
;		Created 
;-
 On_error,2              ;Return to caller

 if N_params() ne 1 then begin
        print,'Syntax - scircle,list
        return
 endif
 
 if keyword_set(radius) then begin
	r = radius
 endif else begin
	r = 3.0
 endelse

; NOTE, should figure out how to "where" the list before circling,
; just need to know the plot data limits

 if keyword_set(index) then begin
	tvcircle,r,list(index).x_image-1,list(index).y_image-1,$
		/data,noclip=0
 endif else begin
	tvcircle,r,list.x_image-1,list.y_image-1,/data,noclip=0
 endelse

 return
 end





