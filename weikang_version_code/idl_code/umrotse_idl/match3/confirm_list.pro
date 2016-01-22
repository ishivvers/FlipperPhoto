FUNCTION confirm_list, m, fst, pair=pair
;+
; NAME: CONFIRM_LIST
;
; CALLING SEQUENCE:  confirm_list, m, fst, pair=pair
;
; INPUTS:       m: a match structure
;               fst: an array of cobj filenames
;
; KEYWORDS:     pair: set this if you want pair matching
;
; OUTPUTS:      cerr: 0 if okay, 4 if no elements in match structure, 5 if all 
;                     listed files are already in match structure, 2 if only
;                     an odd number of files are available for pair matching
;
; REVISION HISTORY:  
;       Don Smith     UM      10/26/01
;       Eli Rykoff            02/23/04 - works with new/old match strs
;================================================================================
;-

  cerr = 0
  nn = n_elements(fst)

  if tag_exist(m,'nobs') then begin
      nobs = m.nobs
  endif else begin
      nobs = n_elements(m.jd)
  endelse

; First, we need to know if the match structure has been defined or not.
  mtp = datatype(m)
  IF mtp NE 'STC' THEN cerr = 4 ELSE BEGIN 
;;      nm = n_elements(m.imagename)  
      nm = nobs
      IF nm LE 0 THEN cerr = 4 ELSE BEGIN 
          flag = indgen(nn)*0
          FOR i=0,nn-1 DO BEGIN 
              j = 0
              WHILE j LT nm DO BEGIN 
                  rootf = strsplit(fst[i].name,'_cobj.fit',/extract,/regex)

;;                  rootf = str_sep(fst[i].name, '_cobj.fit')
                  if (strpos(m.imagename[j],'_c.fit') ge 0) then $
                    rootm = strsplit(m.imagename[j],'_c.fit',/extract,/regex) $
                  else rootm = strsplit(m.imagename[j],'.fit',/extract,/regex)
;;                  rootm = str_sep(m.imagename[j], '.fit')
                  IF rootf[0] EQ rootm[0] THEN BEGIN 
                      print, 'Eliminating '+fst[i].name+' from list as duplicate.'
                      flag[i] = 1
                      j = nm + 1
                  ENDIF
                  j = j + 1
              ENDWHILE
          ENDFOR 
          ifl = where(flag EQ 0, icount)
          IF icount GT 0 THEN fst = fst[ifl] ELSE cerr = 5 
          IF (cerr EQ 0 AND icount AND keyword_set(pair)) THEN cerr = 2
      ENDELSE
  ENDELSE 
  return, cerr
END 
