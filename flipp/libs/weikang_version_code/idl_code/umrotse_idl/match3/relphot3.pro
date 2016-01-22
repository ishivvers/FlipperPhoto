pro relphot3, match, newmatch, rpmap, stat=stat, save=save, archive=archive, over=over, init=init
;+
; NAME:	RELPHOT3
;
; CALLING SEQUENCE:	relphot3, match, newmatch, rpmap, stat=stat, save=save, archive=archive, over=over, init=init
;
; INPUTS:	match: match structure produced by regmatch3_list
;                      or the filename of such a match struct
;
; OUTPUTS:	newmatch: copy of match calibrated to itself to reduce 
;			effects of instrumental variations.  includes 
;                       flags for problematic observations
;		   rpmap: relative photometry map
;
; KEYWORDS:     stat: statistics structure.  Must be present if match is a struct.
;               save: set this to save the match/stats structures to a FITS file
;               over: save match/stats structs and overwrite existing
;               archive: set this if the saved match structure should go in the archive.
;               init: if set, run relphot procedure under any circumstances
;
; PROCEDURE:	Does observation-to-observation photometry of objects
;               Based on Bob Kehoe's RELPHOT
;
; Created: 
;           Don Smith        UM         10/31/01
;           Don Smith                   11/28/01 - Added init option
;           Eli Rykoff                  02/23/04 - added syntax printing
;******************************************************************************
;-

if n_params() lt 3 then begin
    print,'syntax- relphot3,match,newmatch,rpmap,stat=stat,save=save,archive=archive,over=over,init=init'
    return
endif else begin

;; IF N_params() LT 3 THEN doc_library, 'relphot3' $
;; ELSE BEGIN 
     abort = 0
; If we are being passed a match structure name, read in the struct and stats
     IF datatype(match) EQ 'STR' THEN BEGIN 
         openr, mlun, match, /get_lun, error=merr
         IF merr EQ 0 THEN BEGIN 
             close, mlun
             free_lun, mlun
             m = mrdfits(match, 1)
             stat = mrdfits(match, 2)
         ENDIF ELSE BEGIN 
             print, 'Error: cannot open match structure ', match
             abort = 1
         ENDELSE 
     ENDIF ELSE BEGIN 
         IF datatype(match) NE 'STC' THEN BEGIN 
             print, 'Error: match is not a recognized format.' 
             abort = 1
         ENDIF ELSE IF NOT keyword_set(stat) THEN BEGIN 
             print, 'Error: if you pass a match structure, you need to also set stat.' 
             abort = 1
         ENDIF ELSE m = match
     ENDELSE 
      
     IF abort EQ 0 THEN BEGIN 
; First determine if the relphot needs to be applied
         IF NOT keyword_set(init) THEN abort = check_relmat(m,archive=archive)
         IF abort EQ 0 THEN BEGIN 
; Obtain relative photometry image maps.     
             rpmap = relphot3_makemap(m,stat,200)
; Apply corrections to images in match structure
             apply_relphot3,m,stat,rpmap,1,newmatch
; Recalculate diagnostic parameters
             calc_diag_parms,newmatch
             
             IF keyword_set(save) OR keyword_set(over) OR keyword_set(archive) THEN $
               save_match, newmatch, stat, over=over, archive=archive, relphmap=rpmap
         ENDIF ELSE print, 'No relphot necessary.'
     ENDIF 
 ENDELSE 
END
