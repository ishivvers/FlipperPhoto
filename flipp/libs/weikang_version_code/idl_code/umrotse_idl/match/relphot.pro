pro relphot, match, newmatch, stat=stat
;+
; NAME:	relphot
;
; CALLING SEQUENCE:	relphot, match, newmatch, stat=stat
;
; INPUTS:	match: match structure produced by tycho_regmatch_list
;
; OUTPUTS:	newmatch: copy of match calibrated to itself to reduce 
;			effects of instrumental variations.  includes 
;			relative photometry map and flags for problematic
;			observations
;
; Keywords:     stat: statistics structure
;
; PROCEDURE:	Does observation-to-observation photometry of objects
;
; Created: 00-04-11 Bob Kehoe 
; Updated: 05-24-00 Bob Kehoe -- made modular
;******************************************************************************

 if N_params() lt 2 then begin
    print,'Syntax - relphot, match, newmatch[, stat=stat]'
    return
 endif

; Initialization

 if keyword_set(stat) then begin
    get_calnames,match.imagename, calnames
    tychocal_statslist, calnames, stat, files=1
 endif else stat = match.stat

; Obtain relative photometry image maps.

 map = relphot_makemap(match,stat,100)

; Apply corrections to images in match structure

 apply_relphot,match,stat,map,1,newmatch

 return
end
















