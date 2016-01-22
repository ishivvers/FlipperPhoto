pro rbias,imagein,b_imageout
;+
; NAME:	rbias	
;
; CALLING SEQUENCE:	rotsebias,imagein,file_name,b_imageout
;
; INPUTS:	imagein = raw image to be bias subtracted
;
;
; OUTPUTS:	b_imageout = bias subtracted image
;
;
; INPUT KEYWORDS:	Silent = if this keyword is present and non-zero, then
;			the bias subtracted image will not be saved to the out
;			directory.	
;
; PROCEDURE:	Bias subtracts images 
;
; REVISION HISTORY:  
; 	Robin Dalrymple		UM		7/21/97
;	Tim McKay		UM		9/23/97	
;******************************************************************************
 On_error, 2			;Return to caller

 IF N_params() LT 2 then BEGIN
	print,'Syntax-rbias,imagein,b_imageout'
	return
 ENDIF

 info=size(imagein)
 
 if (info(1) eq 2044 and info(2) eq 2044) then begin
;Average the bias overscan
 imleft = imagein(7:17,*)
;Subtract average from image
 sky,imleft,asky,sigma,/silent
 b_imageout = imagein - asky

;Crop off bias overscan from b_imageout
;Cropping here produces a 2015x2015 image
 b_imageout = b_imageout(29:2043,3:2017)
 return
 endif

 if (info(1) eq 2032 and info(2) eq 2064) then begin
;Average the bias overscan
 imleft = imagein(7:11,*)
;Subtract average from image
 sky,imleft,asky,sigma,/silent
 b_imageout = imagein - asky

;Crop off bias overscan from b_imageout
;Cropping here produces a 2015x2015 image
 b_imageout = b_imageout(14:2028,3:2017)
 return
 endif

 if (info(1) eq 2048 and info(2) eq 2080) then begin
;Average the bias overscan
 imleft = imagein(7:11,*)
;Subtract average from image
 sky,imleft,asky,sigma,/silent
 b_imageout = imagein - asky

;Crop off bias overscan from b_imageout
;Cropping here produces a 2015x2015 image
 b_imageout = b_imageout(14:2028,3:2017)
 return
 endif



END

