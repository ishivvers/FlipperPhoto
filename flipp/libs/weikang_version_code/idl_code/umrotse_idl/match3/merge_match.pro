PRO merge_match, m1, m2, m3, st1, st2, st3, template=template
;+
;
;  PRO merge_match, m1, m2, m3, st1, st2, st3, template=template
;
;  INPUT: m1 - first match structure
;         m2 - second match structure
;         st1 - stats structure for m1
;         st2 - stats structure for m2
;
;  KEYWORD: template - if called, discard sources in m2 not in m1
;
;  OUTPUTS: m3 - combined match structure
;           st3 - combined stats structure
;
;  NOTE: calls "sort_match" on m3 and st3 before returning them.
;-
  close_match_radec, m1.ra, m1.dec, m2.ra, m2.dec, mj, mi, 0.0009d, 1.0, miss1
  template_obj=N_elements(m1.ra)
  tobs = n_elements(m1.jd)
  n2=N_elements(m2.ra)
  miss2 = lindgen(n2)
  IF ((size(mi))[0] NE 0 AND n2 GT template_obj) THEN remove, mi, miss2
  nmisses = 0
  IF n2 GT template_obj THEN nmisses=N_elements(miss2)
  nobj=template_obj+nmisses
  IF keyword_set(template) THEN nobj = n_elements(m1.ra)
  nobs = n_elements(m1.jd)+n_elements(m2.jd)
  m3 = make_match3(nobs, nobj, old=m1)

  temst = st1[0]
  st3 = replicate(temst, nobs)
  FOR i = 0,nobs-1 DO BEGIN 
      IF i LT n_elements(st1) THEN BEGIN 
          struct_assign,st1[i],temst
          st3[i] = temst
      ENDIF ELSE BEGIN 
          struct_assign,st2[i-tobs],temst
          st3[i] = temst
      ENDELSE 
  ENDFOR 

  m3.kx[tobs:nobs-1,*,*] = m2.kx
  m3.ky[tobs:nobs-1,*,*] = m2.ky
  m3.rac[tobs:nobs-1] = m2.rac
  m3.decc[tobs:nobs-1] = m2.decc
  m3.jd[tobs:nobs-1] = m2.jd
  m3.m_lim[tobs:nobs-1] = m2.m_lim
  m3.imagename[tobs:nobs-1] = m2.imagename
  m3.exptime[tobs:nobs-1] = m2.exptime

  ra = double(m2.dra/1000000.)
  dec = double(m2.ddec/1000000.)

  IF ((size(mi))[0] NE 0) THEN BEGIN
      FOR iobs=tobs,nobs-1 DO BEGIN 
          i = iobs - tobs
          print, 'Merging observation ', i+1, ' of ', n_elements(m2.jd)
          gd = where(m2.m[i,mi] GT 0.0, ngd)
          IF ngd GT 0 THEN BEGIN 
              m3.ra[mj[gd]]=((m1.ra[mj[gd]]*(m3.numobs[mj[gd]])+ra[i,mi[gd]])/(m3.numobs[mj[gd]]+1))
              m3.dec[mj[gd]]=((m1.dec[mj[gd]]*(m3.numobs[mj[gd]])+dec[i,mi[gd]])/(m3.numobs[mj[gd]]+1))
              m3.numobs[mj[gd]] = m3.numobs[mj[gd]] + 1
          ENDIF 
              
          m3.m[iobs,mj]=m2.m[i,mi]
          m3.merr[iobs,mj]=m2.merr[i,mi]
          m3.flags[iobs,mj]=m2.flags[i,mi]
          
          m3.ddec[iobs,mj] = m2.ddec[i,mi]
          m3.dra[iobs,mj] = m2.dra[i,mi]
              
          IF (tag_exist(m2[0],'msys200')) THEN $
            m3.msys[iobs,mj]=m2.msys200[i,mi]
          IF (tag_exist(m2[0],'rflags')) THEN $
            m3.rflags[iobs,mj]=m2.rflags[i,mi]
      ENDFOR 
  ENDIF

  IF nobj GT template_obj AND NOT keyword_set(template) THEN BEGIN 
      FOR iobs=tobs,nobs-1 DO BEGIN 
          i = iobs - tobs
          gd = where(m2.m[i,miss2] GT 0.0, ngd)
          mg = miss2[gd]
          IF ngd GT 0 THEN BEGIN 
              m3.ra[template_obj+mg]=((m3.ra[template_obj+mg]* $
                                       (m3.numobs[template_obj+mg])+$
                                       m2.dra[i,mg]/1000000.)/ $
                                      (m3.numobs[template_obj+mg]+1))
              m3.dec[template_obj+mg]=((m3.dec[template_obj+mg]* $
                                        (m3.numobs[template_obj+mg])+$
                                         m2.ddec[i,mg]/1000000.)/ $
                                       (m3.numobs[template_obj+mg]+1))
              m3.numobs[template_obj+mg] = m3.numobs[template_obj+mg]+1
          ENDIF 

          m3.m[iobs,template_obj:nobj-1]=m2.m[i,miss2]
          m3.merr[iobs,template_obj:nobj-1]=m2.merr[i,miss2]
          m3.flags[iobs,template_obj:nobj-1]=m2.flags[i,miss2]
          IF (tag_exist(m2,'msys200')) THEN $
            m3.msys[iobs,template_obj:nobj-1]=m2.msys200[i,miss2]
          IF (tag_exist(m2,'rflags')) THEN $
            m3.rflags[iobs,template_obj:nobj-1]=m2.rflags[i,miss2]
          m3.ddec[iobs,template_obj:nobj-1] = m2.ddec[i,miss2]
          m3.dra[iobs,template_obj:nobj-1] = m2.dra[i,miss2]
      ENDFOR 
  ENDIF 
  IF (m3.ral GT min(m3.ra)) THEN m3.ral = min(m3.ra)
  IF (m3.rah LT max(m3.ra)) THEN m3.rah = max(m3.ra)
  IF (m3.decl GT min(m3.dec)) THEN m3.decl = min(m3.dec)
  IF (m3.dech LT max(m3.dec)) THEN m3.dech = max(m3.dec)

  sort_match, m3, m4, st3, st4
  m3 = m4
  st3 = st4
END 
