PRO regmatch3_list, match, stat, list=list, namelist=namelist, pair=pair, limits=limits, save=save, over=over, append=append, archive=archive, error=error, template=template, crop=crop, archdir=archdir, sort=sort,fail=fail
;+
; NAME: REGMATCH3_LIST
;
; This program was written to update Tim McKay's 
; tycho_regmatch_list for the ROTSE-III era.
;
; CALLING SEQUENCE:     regmatch3_list, match, stat, pair=pair, list=list, namelist=namelist,
;                         limits=limits, save=save, over=over, append=append, archive=archive, 
;                         error=error, template=template, crop=crop, archdir=archdir
;
; INPUTS:       list: name of file with list of calibrated object structure files
;               namelist: an array of strings to be used with or without list.
;                  (note: either list or namelist *must* be set)
;               limits: optional four-element vector with [ral,rah,decl,dech]
;               template: structure of ra/dec values.  Non-matches are discarded.
;
; OUTPUTS:      match: final match structure
;               stat: array of stat structures for given list
;               error: returns ferr value
;
; INPUT KEYWORDS:
;               pair: set this if you want pair matching
;               save: set this to save the match/stats structures to a FITS file
;               over: save match/stats structs and overwrite existing
;               append: match is an existing structure and list should be appended to it
;               archive: set this if the saved match structure should go in the archive.
;               crop: set this to discard all sources outside "limits" (or first two
;                     cobj structure limits, if limits not set explicitly
;               archdir: The archive directory, if not the default
;               sort: set this if you want the input name list to be sorted
;                       
; PROCEDURE:
;
; REVISION HISTORY:  
;               Don Smith       UM      10/18/01
;               Don Smith               10/26/01 - Added append and archive options
;               Don Smith               10/31/01 - Added unpack_delts
;               Don Smith               11/13/01 - Removed unpack_delts, added better limits
;               Don Smith               11/28/01 - Returns error value
;               Don Smith               12/19/01 - Added template option
;               Don Smith               08/20/02 - Added crop option
;               Eli Rykoff              02/23/04 - new match structures
;               Eli Rykoff              11/15/04 - removes bad images from stats
;====================================================================================
;-
; First, check if input params parse properly
  fail = 0
  ferr = 0
  IF N_params() NE 2 THEN $
    print,'Syntax - regmatch3_list, match, stat, list=list, namelist=namelist, pair=pair, limits=limits, save=save, over=over, append=append, archive=archive, template=template,crop=crop' $
  ELSE BEGIN 
      IF (NOT keyword_set(list) AND NOT keyword_set(namelist) AND $
          NOT keyword_set(save) AND NOT keyword_set(archive) AND NOT keyword_set(over)) THEN $
        print, 'Either list, namelist, save, over, or archive must be assigned' $
      ELSE BEGIN
          abort = 0
; Check to see if template is in the right format 
          IF keyword_set(template) THEN BEGIN 
              IF datatype(template) EQ 'STC' THEN BEGIN 
                  IF NOT tag_exist(template, 'ra') OR NOT tag_exist(template, 'dec') THEN abort=1
              ENDIF ELSE BEGIN 
                  sz = size(template)
                  IF sz[0] NE 2 OR sz[1] NE 2 THEN abort = 1 ELSE BEGIN 
                      tarr = template
                      template = create_struct("ra", findgen(sz[2]), "dec", findgen(sz[2]))
                      template.ra = tarr[0,*]
                      template.dec = tarr[1,*]
                  ENDELSE 
              ENDELSE 
          ENDIF 
          IF abort EQ 0 THEN BEGIN 
              IF (keyword_set(list) OR keyword_set(namelist)) THEN BEGIN 
                  ferr = compile_list(filestrct, list=list, namelist=namelist, pair=pair, append=append,sort=sort)
                  IF ferr EQ 0 AND keyword_set(append) THEN $
                    ferr = confirm_list(match, filestrct, pair=pair)
; If there was no error, continue
                  IF ferr EQ 0 OR ferr EQ 4 THEN BEGIN
                      IF keyword_set(pair) THEN step = 2 ELSE step = 1
                      if ((n_elements(filestrct) mod step) ne 0) then begin
                          print,'Odd number of files!'
                          return
                      endif
; If the limits are not set manually, set them via first cobj limits
                      IF NOT keyword_set(limits) THEN BEGIN
                          IF keyword_set(crop) THEN limits = targ2lims(crop) $
                          ELSE BEGIN 
                              fudge = 0.4
                              IF keyword_set(append) THEN BEGIN 
                                  match.ral = match.ral - fudge
                                  match.rah = match.rah + fudge
                                  match.decl = match.decl - fudge
                                  match.dech = match.dech + fudge                      
                              ENDIF ELSE limits = set_limits(fudge, filestrct[0].file)
                          ENDELSE
                      ENDIF 
; First get all the stat structures into an array
                      serr = stats_strct(filestrct, stat, nold, append=append)
                      IF serr EQ 0 THEN BEGIN 
                          print, 'Begin regmatch'
; Now initialize the match structure
                          i = 0
                          IF NOT keyword_set(append) OR ferr EQ 4 THEN BEGIN 
                              fail = 0
                              regmatch3_init, match, filestrct, stat, limits, pair=pair, template=template, fail = fail
                              if (fail eq 1) then begin
                                  print,'regmatch3_init failed'
                                  return
                              endif

                              i = 2
                              nold = 0
                          ENDIF 
; Loop through the rest of the data and add to the match structure
                          nf = n_elements(filestrct)
;;                          used_arr=bytarr(nf)+1
                          used_arr = bytarr(n_elements(stat)) + 1
                          if (keyword_set(append)) then $
                            ustart = n_elements(stat)-n_elements(filestrct) $
                            else ustart = 0
                          WHILE i LT nf DO BEGIN
                              regmatch3_add, match, filestrct, i, stat, nold, pair=pair, template=template, crop=crop, fail=fail
                              ;; check if it failed  -- what to do?
                              if (fail eq 1) then begin
                                  used_arr[ustart+i:ustart+i+step-1] = 0
                              endif                             
                              i = i + step
                          ENDWHILE 
                          used=where(used_arr eq 1,uct)
                          if (uct gt 0) then begin
                              stat=stat[used]
                          endif else begin
                              print,'No files used!  Fatal error.'
                              return
                          endelse

; Flag all objects with consecutive observations
                          flag_consec, match
; Calculate diagnostic parameters
                          calc_diag_parms, match
; Flag positions that deviate too much
                          flagposdis,match,stat[0].cdelt1
; Reset the match structure ra/dec limits
                          match.ral = min(match.ra[0:match.nobj-1])
                          match.rah = max(match.ra[0:match.nobj-1])
                          match.decl = min(match.dec[0:match.nobj-1])
                          match.dech = max(match.dec[0:match.nobj-1])
                      ENDIF ELSE print, 'Error in collecting stat structures'
                  ENDIF ELSE BEGIN 
                      print, 'Error in compiling list'
                      IF ferr EQ 1 THEN print, 'File '+list+' not found'
                      IF ferr EQ 2 THEN print, 'Not an even number of cobj files'
                      IF ferr EQ 3 THEN print, 'One or more of the cobj files could not be found'
                      IF ferr EQ 5 THEN print, 'All listed files are already in the match structure.'
                  ENDELSE
              ENDIF 
          ENDIF 
          IF keyword_set(save) OR keyword_set(over) OR keyword_set(archive) THEN $
            save_match, match, stat, over=over, archive=archive, archdir=archdir
      ENDELSE 
  ENDELSE 
  error = ferr
END 
