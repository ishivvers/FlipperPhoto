FUNCTION stats_strct, fs, st, nschon, append=append
;+
; NAME: STATS_STRCT
;
; This program will take a file structure array (of cobj file names)
; and fill an array of stat structures from the files 
;
; CALLING SEQUENCE:     stats_strct, fs, st
;
; INPUTS:       fs: array of file name structures
;               st: array of stat structures from cobj files in fs
;
; OUTPUTS:      serr: error flag
;
; KEYWORDS:     append: set this to append to an existing st, else overwrite
;
; REVISION HISTORY:  
;               Don Smith       UM      10/18/01
;====================================================================================
;-

  serr = 0
  nschon = 0

  IF keyword_set(append) THEN nschon = n_elements(st)
  ntot = nschon + n_elements(fs)
  stats = mrdfits(fs[0].file, 2)
  template=stats
  newst = replicate(stats, ntot)
  FOR i = 0,nschon-1 DO BEGIN 
      struct_assign,st[i],template
      newst[i] = template
  ENDFOR 
  newst[nschon] = stats
  FOR k = nschon+1, ntot-1 DO BEGIN
      i = k - nschon
      struct_assign,mrdfits(fs[i].file, 2),template
      newst[k] = template
  ENDFOR 
  st = newst
  return, serr
END
