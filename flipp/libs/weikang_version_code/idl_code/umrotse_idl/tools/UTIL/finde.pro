pro finde, aratio, posangle, e1_ad, e2_ad, e1_lup, e2_lup, verbose=verbose

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    finde
;       
; PURPOSE: 
;    Find the e1 and  for a perfectly elliptal object with the 
;          given axis ratio.  e1_ad and e2_ad are for unweighted or adaptively
;          weighted moments.  e1_lup and e2_lup are Robert Luptons q and u
;          which are in SDSS PHOTO catalogs.
;	
;
; CALLING SEQUENCE:
;    
;     finde, aratio, posangle, e1_ad, e2_ad, e1_lup, e2_lup, silent=silent
;      
; INPUTS: 
;    aratio:  The axis ratio of the object.
;    posangle: The positon angle from the x-axis.
;
; INPUT KEYWORD PARAMETERS:
;         /verbose: Print out the result.
;       
; OUTPUTS: 
;    e1_ad, e2_ad:  Ellipticity parameters in unweighted for adaptively
;                   weighted moments.
;
; OPTIONAL OUTPUTS: 
;    e1_lup, e2_lup:  q and u from PHOTO catalog.
;
;
; REVISION HISTORY:
;	
;   Author: Erin Scott Sheldon   U of M  5/25/99 
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


if n_params() LT 2 then begin
	print,'-syntax finde, aratio, posangle [, e1_ad, e2_ad, e1_lup, e2_lup, verbose=verbose]'
        print,' Give posangle in radians'
	return
endif

e0_ad = (1 - (aratio)^2)/(1+(aratio)^2)
e0_lup = (1-aratio)/(1+aratio)

e1_ad = e0_ad*cos(2*posangle)
e2_ad = e0_ad*sin(2*posangle)
e1_lup = e0_lup*cos(2*posangle)
e2_lup = e0_lup*sin(2*posangle)

IF keyword_set(verbose) THEN BEGIN
  print,'Adaptive e1: ',strtrim(string(e1_ad),2)
  print,'Adaptive e2: ',strtrim(string(e2_ad),2)
  print,'Lupton e1: ',strtrim(string(e1_lup),2)
  print,'Lupton e2: ',strtrim(string(e2_lup),2)
ENDIF

end
