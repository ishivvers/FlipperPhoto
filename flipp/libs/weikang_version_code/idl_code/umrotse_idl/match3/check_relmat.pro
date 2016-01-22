FUNCTION check_relmat, mat, archive=archive
  archpath = '/data2/rotse3/match/'
  answer = 1
  parts = str_sep(mat.imagename[0],'_')
  file = parts[1]+'_'+strmid(parts[2],0,2)+'_relmat.fit'
  IF keyword_set(archive) THEN file = archpath + file
  openr,flun,file,/get_lun,error=ferr
  IF ferr EQ 0 THEN BEGIN 
      close, flun
      free_lun, flun
      m = mrdfits(file,1)

      if tag_exist(mat,'nobs') then begin
          mat_nobs = mat.nobs
      endif else begin
          mat_nobs = n_elements(mat.jd)
      endelse

      if tag_exist(m,'nobs') then begin
          m_nobs = m.nobs
      endif else begin
          m_nobs = n_elements(m.jd)
      endelse

;;      IF n_elements(m.jd) NE n_elements(mat.jd) THEN answer = 0 ELSE $
;;        FOR i=0,n_elements(m.jd)-1 DO IF m.imagename[i] NE mat.imagename[i]
;;        THEN answer = 0
      if m_nobs ne mat_nobs then answer = 0 else begin
          for i=0,m_nobs-1 do if m.imagename[i] ne mat.imagename[i] then answer = 0
      endelse

  ENDIF ELSE answer = 0
  return, answer
END 
