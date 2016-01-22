pro clean_sub, im1, im2, imsub, t1=t1, t2=t2, k1=k1, k2=k2
;+
; NAME:
;       CLEAN_SUB
; PURPOSE:
;	Perform a "clean" subtraction of ROTSE images which have already
;	been warped
;
; CALLING SEQUENCE:
;       clean_sub, im1, im2
;
; INPUTS:
;	im1
;	im2 (Will determine im1-im2)
;       
; OUTPUTS:
;	imsub=im1-im2 (doctored to clean it up...)
;
; OPTIONAL INPUTS:
;	threshold for cutoff....
;
; OPTIONAL OUTPUT ARRAYS:
; 
; PROCEDURE: This subtracts images, blanking out regions which _might_ be 
;	saturated in _either_ image. Images should be scaled before using 
;	this.
;
; REVISION HISTORY:
;	Tim McKay	UM 	9/8/98
;		Created 
;-
 On_error,2              ;Return to caller

 if N_params() lt 1 then begin
        print,'Syntax - clean_sub, im1, im2, imsub, t1=t1, t2=t2'
        return
 endif

 if not keyword_set(t1) then begin
	t1=16000
 endif
 if not keyword_set(t2) then begin
	t2=16000
 endif

; Find sky in the two images
 sky,im1,sky1,skyerr1
 sky,im2,sky2,skyerr2

 imsub=im1-im2

 k1=where(im1 gt t1)
 if ((size(k1))(0) gt 0) then begin
	 imsub(k1)=sky1-sky2
 endif

 k2=where(im2 gt t2)
 if ((size(k2))(0) gt 0) then begin
	 imsub(k2)=sky1-sky2
 endif

 return
 end

 

