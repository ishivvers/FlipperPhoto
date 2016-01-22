FUNCTION getseqnum, name
  fls = str_sep(name,'/')
  nf = n_elements(fls)-1
  parts = str_sep(fls[nf],'_')
  sq = strmid(parts[2],2,3)+0
  return, sq
END 

PRO update_match, startroot, all, pair=pair, archive=archive, sky=sky, init=init, relphot=relphot, matchdir=matchdir, usecoadd=usecoadd
;+
; NAME: UPDATE_MATCH
;
; CALLING SEQUENCE: update_match, startroot, all, pair=pair, archive=archive, sky=sky, init=init, $
;                                 relphot=relphot, matchdir=matchdir, usecoadd=usecoadd
;
; INPUTS:   matchdir: optional directory to work in.  Default is working dir.
;           startroot: array of roots to process
;
; OUTPUTS:  all: string array containing all the root names
;
; KEYWORDS: pair: set to do pair matching
;           archive: set to save (with overwrite) in the archive directory
;           sky: set to only do sky patrol data
;           init: don't read in any existing match str
;           relphot: apply relative photometry to match structures
; 
; REVISION HISTORY:  
;       Don Smith   UM      10/28/01
;       Don Smith           11/13/01 - Added option to perform relphot3 on finished match
;       Don Smith           11/13/01 - Added matchdir, and restricted relphot to only
;                                        match structures with > relphot_num observations
;       Don Smith           11/13/01 - Will now accept both 15 and 10 char root names
;       Don Smith           11/05/03 - Removed check on scope ID; will now take sub-strings on root
;       Don Smith           04/30/04 - If only one root is specified, it will only search for cobj
;                                           files with that root.  Saves a *lot* of time.
;       Don Smith           05/03/04 - Incorporated Eli's "find_rotse3_tlaroot"
;       Don Smith           05/12/04 - Added "usecoadd" feature
;================================================================================
;-

  relphot_num = 6
  IF n_params() EQ 0 THEN doc_library, 'update_match' $
  ELSE BEGIN 
      IF keyword_set(matchdir) THEN cd, matchdir
      nroot = n_elements(startroot)
      rootlist = startroot

; Loop through the roots and create the match structures
; For each root, check to see if the match structure is there
; in the archive already, if the archive option is set.
      
      IF nroot LE 0 THEN print, 'Error: no roots to parse' ELSE BEGIN
          all = rootlist
          FOR i=0,nroot-1 DO BEGIN 
              print, 'Root ',all[i]
              namebyroot = find_rotse3_tlaroot(all[i]+'*', /pair, usecoadd=usecoadd)
              found = 0
              IF NOT keyword_set(init) THEN BEGIN 
                  print, 'Searching for match structure for ', rootlist[i], ' in ', matchdir
                  found = search_match(rootlist[i], mat, matstr, archive=archive, matchdir=matchdir) 
                  IF found EQ 1 THEN $
                    print, 'Found match structure already present.' $
                    ELSE print, 'No match structure found.'
              ENDIF 

              nlist = n_elements(namebyroot)
              datelist = lindgen(nlist)*0
              alldates = lindgen(nlist)*0
              name = namebyroot
              ndates = 0
; Find out how many dates are present, and loop through them
              FOR j=0,nlist-1 DO BEGIN 
                  dirs = str_sep(namebyroot[j],'/')
                  name[j] = dirs[n_elements(dirs)-1]
                  newdate = strmid(name[j],0,6)
                  alldates[j] = newdate*1l
                  print, j, name[j], alldates[j]

                  dateflag = 0
                  FOR k=0,ndates-1 DO IF newdate EQ datelist[k] THEN dateflag = 1
                  IF dateflag EQ 0 THEN BEGIN 
                      datelist[ndates] = newdate*1l
                      ndates = ndates + 1
                  ENDIF
              ENDFOR

              gooddates = where(datelist GT 0, gdc)

              IF gdc GT 0 THEN BEGIN 
                  datelist = datelist[gooddates]
                  datelist = datelist[sort(datelist)]
              ENDIF

              FOR j=0,gdc-1 DO BEGIN 
; For each date, pull out the files from the list
                  thisdate = where(alldates EQ datelist[j],dcount)
                  IF dcount GT 0 THEN BEGIN 
                      thisdatelist = namebyroot[thisdate]
                      namedatelist = name[thisdate]
                      minnum = 1
                      IF keyword_set(pair) THEN BEGIN
                          minnum = 2
                          IF dcount GE 2 THEN BEGIN 
                              badflag = indgen(dcount)*0
                              k = 0
                              WHILE k LT dcount-2 DO BEGIN 
                                  seq0 = getseqnum(namedatelist[k])
                                  IF NOT seq0 THEN BEGIN 
                                      badflag[k] = 1
                                      k = k + 1
                                      IF k LT dcount-1 THEN seq0 = getseqnum(namedatelist[k]) $
                                      ELSE badflag[k] = 1
                                  ENDIF 
                                  IF k LT dcount-1 THEN BEGIN 
                                      seq1 = getseqnum(namedatelist[k+1])
                                      IF seq1 NE seq0+1 THEN badflag[k:k+1] = 1
                                  ENDIF ELSE badflag[k] = 1
                                  k = k + 2
                              ENDWHILE 
                              good = where(badflag EQ 0, gcount)
                              IF gcount LT dcount THEN thisdatelist = thisdatelist[good]
                          ENDIF
                          nfiles = n_elements(thisdatelist)
                          IF nfiles AND nfiles GT 2 THEN thisdatelist = thisdatelist[0:nfiles-2]
                      ENDIF 
                      
                      IF n_elements(thisdatelist) GE minnum THEN BEGIN 
                          IF found EQ 0 THEN BEGIN 
                                  print, 'beginning mat with ', thisdatelist
                              regmatch3_list, mat, matstr, namelist=thisdatelist, /pair, error=lerr
                              found = 1
                          ENDIF ELSE BEGIN  
                                  print, 'appending mat with ', thisdatelist
                              regmatch3_list, mat, matstr, namelist=thisdatelist, /pair, /append, error=lerr
                              IF n_elements(thisdatelist) GE 4 AND lerr EQ 0 THEN BEGIN 
                                  x = indgen(n_elements(thisdatelist)) + n_elements(mat.jd) - n_elements(thisdatelist)
;                                      flag_asteroids, mat, appendobs=x
                              ENDIF 
                          ENDELSE
                      ENDIF 
                  ENDIF 
              ENDFOR
              IF found THEN BEGIN 
                  sort_match, mat, nm, indgen(n_elements(mat.jd)), nos
                  nmatst = matstr[nos]
                  print, nm.imagename
                  regmatch3_list, nm, nmatst, /over, archive=archive
                  IF keyword_set(relphot) AND n_elements(mat.jd) GT relphot_num THEN $
                    relphot3, nm, newmat, rmap, stat=nmatst, archive=archive, init=init, /over
              ENDIF
              print, 'Finished with root ', rootlist[i]
          ENDFOR
      ENDELSE 
  ENDELSE
END
