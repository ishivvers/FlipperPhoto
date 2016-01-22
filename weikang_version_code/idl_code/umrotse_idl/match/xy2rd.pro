pro xy2rd, x, y, astr, a, d
;+
; NAME:
;	XY2RD
;
; PURPOSE:
;	Compute R.A. and Dec in degrees from X and Y and an astrometry structure
;	(extracted by EXTAST)  from a FITS header.   A tangent (gnomonic) 
;	projection is computed directly; other projections are computed using 
;	WCSXY2SPH.
;	XY2AD is meant to be used internal to other procedures.  For interactive
;	purposes use XYAD.
;
; CALLING SEQUENCE:
;	XY2AD, x, y, astr, a, d   
;
; INPUTS:
;	X     - row position in pixels, scalar or vector
;	Y     - column position in pixels, scalar or vector
;	ASTR - astrometry structure, output from EXTAST procedure containing:
;   	 .CD   -  2 x 2 array containing the astrometry parameters CD1_1 CD1_2
;		in DEGREES/PIXEL                                   CD2_1 CD2_2
;	 .CDELT - 2 element vector giving physical increment at reference pixel
;	 .CRPIX - 2 element vector giving X and Y coordinates of reference pixel
;		(def = NAXIS/2)
;	 .CRVAL - 2 element vector giving R.A. and DEC of reference pixel 
;		in DEGREES
;	 .CTYPE - 2 element vector giving projection types 
;	 .LONGPOLE - scalar longitude of north pole (default = 180) 
;        .PROJP1 - Scalar parameter needed in some projections
;	 .PROJP2 - Scalar parameter needed in some projections
;
; OUTPUT:
;	A - R.A. in DEGREES, same number of elements as X and Y
;	D - Dec. in DEGREES, same number of elements as X and Y
;
; RESTRICTIONS:
;	Note that all angles are in degrees, including CD and CRVAL
;	Also note that the CRPIX keyword assumes an FORTRAN type
;	array beginning at (1,1), while X and Y give the IDL position
;	beginning at (0,0).
;	No parameter checking is performed.
;
; REVISION HISTORY:
;	Written by R. Cornett, SASC Tech., 4/7/86
;	Converted to IDL by B. Boothman, SASC Tech., 4/21/86
;	Perform CD  multiplication in degrees  W. Landsman   Dec 1994
;	Rename xy2rd forces tangent projection	David Johnston
;-
 if N_params() LT 4 then begin
	print,'Syntax -- XY2AD, x, y, astr, a, d'
	return
 endif
 radeg = 180.0d/!DPI                  ;Double precision !RADEG

 cd = astr.cd
 crpix = astr.crpix
 cdelt = astr.cdelt

 xdif = x - (crpix(0)-1) 
 ydif = y - (crpix(1)-1)
 xsi = cdelt(0)*(cd(0,0)*xdif + cd(0,1)*ydif)	;Can't use matrix notation, in
 eta = cdelt(1)*(cd(1,0)*xdif + cd(1,1)*ydif)	;case X and Y are vectors

 xsi = xsi / radeg
 eta = eta / radeg
 crval = astr.crval / radeg
 beta = cos(crval(1)) - eta * sin(crval(1))
 a = atan(xsi, beta) + crval(0)
 gamma = sqrt((xsi^2) +(beta^2))
 d = atan(eta*cos(crval(1))+sin(crval(1)) , gamma)
 a = a*RADEG   &  d = d*RADEG


 return
 end
