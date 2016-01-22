PRO save_match, m, allstats, over=over, archive=archive, relphmap=relphmap, archdir=archdir, altroot=altroot
;+
; NAME: SAVE_MATCH
;
; CALLING SEQUENCE: save_match, m, allstats, over=over, archive=archive, archdir=archdir
;
; INPUTS:              m: a match structure
;               allstats: the array of all the stat structures
;               relphmap: the relphot3 map (optional)
;
; KEYWORDS:        over: flag to overwrite existing file, if present
;               archive: place saved file in archive, rather than local directory
;               archdir: define a non-standard archive directory
;               altroot: give an alternative root name
;
; REVISION HISTORY:  
;       Don Smith               UM      10/24/01
;       Don Smith                       10/26/01 - added archive option
;       Don Smith                       10/31/01 - added relphot map
;       Don Smith                       10/22/02 - added archdir option
;       Eli Rykoff                      01/19/04 - added altroot option; works
;                                                  with new-style match strs
;================================================================================
;-

if n_params() lt 2 then begin
    print,'syntax- save_match, m, allstats, over=over, archive=archive, relphmap=relphmap, archdir=archdir, altroot=altroot'
    return
endif

if tag_exist(m,'nobs') then begin
    nobs = m.nobs
endif else begin
    nobs = n_elements(m.jd)
endelse


; Set archive path name
  rotse_setup
  archpath = !match_archive_path
  IF keyword_set(archdir) THEN archpath = archdir+'/'

; First, confirm that there is something to save
  nt = n_tags(m)
  IF nt GT 0 THEN BEGIN
;;      nt = n_elements(m.imagename)
      nt = nobs
      ns = n_elements(allstats)
      IF nt EQ ns THEN BEGIN 
; Next, figure out what to name the file
          parts = str_sep(m.imagename[0],'_')
          if n_elements(altroot) ne 0 then root = altroot $
            else root = parts[1]
          root = root + '_' + strmid(parts[2],0,2)
          IF keyword_set(relphmap) THEN mname = root + '_relmat.fit' $
          ELSE mname = root + '_match.fit'
          IF keyword_set(archive) THEN BEGIN 
; Check to make sure archive directory exists
              openw, ul, archpath+'test.txt', /get_lun, error=werr
              IF werr EQ 0 THEN BEGIN
                  close, ul
                  free_lun, ul
              ENDIF ELSE spawn, 'mkdir '+archpath
              mname=archpath+mname
              print, 'Archiving data'
          ENDIF 
          
          oerr = 1
          IF NOT keyword_set(over) THEN BEGIN 
; First, make sure there isn't a file already there by that name
              openr, tlun, mname, /get_lun, error=oerr
              IF oerr EQ 0 THEN BEGIN 
                  close, tlun
                  free_lun, tlun
                  print, 'Error: '+mname+' already exists.  NO SAVE.' 
              ENDIF 
          ENDIF 
; Next, save the match structure and stat structures as extensions
          IF oerr NE 0 THEN BEGIN 
              print, 'Writing match structure '+mname
              mwrfits, m, mname, /create
              mwrfits, allstats, mname
              IF keyword_set(relphmap) THEN mwrfits, relphmap, mname
              spawn, 'chmod 666 '+mname
          ENDIF
      ENDIF ELSE print, 'Error: Different number of observations in stats and match structures.'
  ENDIF ELSE print, 'Error: Match structure is empty.'
END
