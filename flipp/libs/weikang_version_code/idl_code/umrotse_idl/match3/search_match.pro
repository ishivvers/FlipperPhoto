FUNCTION search_match, root, m, str, archive=archive, matchdir=matchdir
;+
; NAME: SEARCH_MATCH
;
; CALLING SEQUENCE: search_match, root, m, str, archive=archive
;
; INPUTS:   root: the root name for the match structure
;
; KEYWORDS: archive: set to look in the archive directory
;
; OUTPUTS: fflag: returns 0 if not found, 1 if found
;          m: if found, this is the read-in match structure
;          str: if found, this is the read-in stats structure
; 
; REVISION HISTORY:  
;       Don Smith    UM      10/28/01
;       Don Smith    UM      11/16/01 - Added "matchdir" option
;================================================================================
;-

  scope = ['_3a', '_3b', '_3c', '_3d']
  archdir = '/data2/rotse3/match/'
  fflag = 0
  i = 0

  WHILE i LT 4 AND fflag EQ 0 DO BEGIN 
      mname = root + scope[i] + '_match.fit'
      IF keyword_set(archive) THEN mname = archdir + mname $
      ELSE IF keyword_set(matchdir) THEN mname = matchdir + mname
      openr, mlun, mname, /get_lun, error=merr
      IF merr EQ 0 THEN BEGIN 
          close, mlun
          free_lun, mlun
          fflag = 1
          m = mrdfits(mname,1)
          str = mrdfits(mname,2)
      ENDIF
      i = i + 1
  ENDWHILE 
  return, fflag
END 
