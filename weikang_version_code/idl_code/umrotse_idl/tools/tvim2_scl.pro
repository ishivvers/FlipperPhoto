PRO tvim2_scl,image,xm,xx,ym,yx,range=range,_extra=e

; NAME:
; tvim2_scl
;
; PURPOSE:
; To view a peice of an image and retain the coordinates of the original image in that peice
; CALLING SEQUENCE:
; tvim2_scl,image,xm,xx,ym,yx,range
;
; INPUTS:
; image is the name of the image to be viewed
; xm is the minimum x coordinate
; xx is the maximum x coordinate
; ym is the minimum y coordinate
; yx is the maximum y coordinate
; range is the range with which to view the image
; 
; OUTPUTS:
; A zoomed in peice of an image retaining its original coordinates
; 
; OPTIONAL KEYWORD PARAMETERS:
; none
;
; NOTES:
; 
; PROCEDURES CALLED:
; tvim2
; REVISION HISTORY:
; written by Susan Amrose -University of Michigan July 97

if n_params() eq 0 then begin
 print,'syntax- tvim2_scl,image,xm,xx,ym,yx,range=range,_extra=e'
 return
endif

tvim2,image(xm:xx,ym:yx),range=range,xrange=[xm,xx],yrange=[ym,yx],_extra=e
return
end



