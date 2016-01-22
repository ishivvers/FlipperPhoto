PRO stuff_match, match, list, stat, mi, mj, allstat, pair=pair, template=template
;+
; NAME: STUFF_MATCH
;
; CALLING SEQUENCE: stuff_match, match, list, allstat, mi, mj
;
; INPUTS:       match: a match structure
;               list: the array of objects to be stuffed
;               stat: the stat structure associated with the array
;               mi: the index array for the list for elements that match
;               mj: the counterpart array for the match structure array
;               allstat: the entire array of stat structures
;               template: the structure of ra/dec values for matching (keyword only)
; 
; KEYWORDS:    pair: set this if we are stuffing the second list in a pair
;
; REVISION HISTORY:  
;       Don Smith    UM      10/23/01
;       Don Smith    UM      11/13/01 - Added -2 flag for out of FOV
;       Don Smith    UM      11/13/01 - Changed dra/ddec to longs
;       Don Smith    UM      11/13/01 - Now updates match ra/dec limits
;       Don Smith    UM      11/14/01 - if one of a pair is -2, the other will be
;       Don Smith    UM      11/16/01 - also pass complete array of stats structures
;       Don Smith    UM      11/26/01 - call check_in_fov, set BADIMAGE flag
;       Eli Rykoff   UM      02/23/04 - improved match structures; -2 setting
;                                       also commented out BADIMAGE flag
;================================================================================
;-

;Find the number of objects which match and don't

  ;if n_elements(match.jd) eq 8 then killit

  ;;template_obj=N_elements(match.ra) ; set number already in match
  template_obj = match.nobj
  n1=n_elements(mi)
  n2=N_elements(list)               ; set number to be added
  miss2=lindgen(n2)                 ; the full array
  if ((size(mi))[0] ne 0 and n2 gt n1) then begin
      remove,mi,miss2               ; miss2 now contains the true misses
      nmisses = n_elements(miss2)
  endif else nmisses = 0
  nobj=template_obj+nmisses         ; number of objects in new match structure
;;  nobs=n_elements(match.jd) + 1    ; number of observations in new match
;;  structure
  nobs = match.nobs + 1             ; true number of observations in new match

; If we are stuffing the second one in a pair, we need to change some of these
  IF keyword_set(pair) THEN BEGIN 
      nobj = template_obj            ; we've already added the misses
      template_obj = nobj - nmisses  ; ditto
  ENDIF 

  IF keyword_set(template) THEN nobj = n_elements(match.ra)

; Create new match structure and stuff with old structure.
  make_match3_new,match,nobs,nobj,/useold
  
; Add relevent values from new stat struct
  match.nobj = nobj
  match.nobs = nobs
  match.kx[nobs-1,*,*] = stat.kx
  match.ky[nobs-1,*,*] = stat.ky
  match.rac[nobs-1] = stat.rac
  match.decc[nobs-1] = stat.decc
  match.jd[nobs-1] = stat.mjd
  match.m_lim[nobs-1] = stat.m_lim
  match.imagename[nobs-1] = stat.filename
  match.exptime[nobs-1] = stat.exptime

; Now add the matches
  IF ((size(mi))[0] NE 0) THEN BEGIN
      match.ra[mj]=((match.ra[mj]*(match.numobs[mj])+list[mi].ra)/(match.numobs[mj]+1))
      match.dec[mj]=((match.dec[mj]*(match.numobs[mj])+list[mi].dec)/(match.numobs[mj]+1))
      
      match.numobs[mj] = match.numobs[mj] + 1
      
      match.m[nobs-1,mj]=list[mi].m
      match.merr[nobs-1,mj]=list[mi].merr
      match.flags[nobs-1,mj]=list[mi].flags

      match.ddec[nobs-1,mj] = long(list[mi].dec*1000000.)
      match.dra[nobs-1,mj] = long(list[mi].ra*1000000.)

      IF (tag_exist(list[0],'msys200')) THEN $
        match.msys[nobs-1,mj]=list[mi].msys200
      IF (tag_exist(list[0],'rflags')) THEN $
        match.rflags[nobs-1,mj]=list[mi].rflags
  ENDIF

; Add misses if necessary
  IF nobj GT template_obj AND NOT keyword_set(template) THEN BEGIN 
      match.ra[template_obj:nobj-1]=((match.ra[template_obj:nobj-1]* $
                                       (match.numobs[template_obj:nobj-1])+list[miss2].ra)/ $
                                      (match.numobs[template_obj:nobj-1]+1))
      match.dec[template_obj:nobj-1]=((match.dec[template_obj:nobj-1]* $
                                        (match.numobs[template_obj:nobj-1])+list[miss2].dec)/ $
                                       (match.numobs[template_obj:nobj-1]+1))
      match.numobs[template_obj:nobj-1] = match.numobs[template_obj:nobj-1]+1
      match.m[nobs-1,template_obj:nobj-1]=list[miss2].m
      match.merr[nobs-1,template_obj:nobj-1]=list[miss2].merr
      match.flags[nobs-1,template_obj:nobj-1]=list[miss2].flags
      IF (tag_exist(list[0],'msys200')) THEN $
        match.msys[nobs-1,template_obj:nobj-1]=list[miss2].msys200
      IF (tag_exist(list[0],'rflags')) THEN $
        match.rflags[nobs-1,template_obj:nobj-1]=list[miss2].rflags
      match.ddec[nobs-1,template_obj:nobj-1] = long(list[miss2].dec*1000000.)
      match.dra[nobs-1,template_obj:nobj-1] = long(list[miss2].ra*1000000.)
  ENDIF 

; Set the BADIMAGE flag if necessary
;;  print,'setting badimage'
;;  IF stat.m_lim LT 17.0 THEN $
;;    match.rflags[nobs-1,*] = set_flags3('BADIMAGE', old=match.rflags[nobs-1,*], type='RFLAGS')
  
; Check to see what sources are out of the FOV of each observation
; Do not bother if using template
  IF NOT keyword_set(template) THEN BEGIN 

      ;; the following works well
      if (nmisses gt 0) then begin
          for i=0,nobs-2 do begin
              newlist = lindgen(nmisses)+template_obj
              checkobjs = where(match.m[i,newlist] eq -1, ct0)
              if (ct0 gt 0) then begin
                  checkobjs = newlist[checkobjs]
                  ofov = check_in_fov(i,match,allstat,checkobjs,count=ct)
                  if (ct gt 0) then match.m[i,ofov] = -2
              endif
          endfor
      endif
      i=nobs-1
      checkobjs = where(match.m[i,0:(match.nobj-1)] eq -1, ct1)
      if (ct1 gt 0) then begin
          ofov = check_in_fov(i,match,allstat,checkobjs,count=ct2)
          if (ct2 gt 0) then match.m[i,ofov] = -2
      endif
      
  ENDIF 
  IF keyword_set(pair) THEN BEGIN
      i = 1
      WHILE i LT nobs DO BEGIN 
          badpair = where(match.m[i,*] EQ -2 OR match.m[i-1,*] EQ -2, nbad)
          IF nbad GT 0 THEN match.m[i-1:i,badpair] = -2
          i = i + 2
      ENDWHILE
  ENDIF

; Update match structure limits
  IF (match.ral GT min(match.ra[0:match.nobj-1])) THEN match.ral = min(match.ra[0:match.nobj-1])
  IF (match.rah LT max(match.ra[0:match.nobj-1])) THEN match.rah = max(match.ra[0:match.nobj-1])
  IF (match.decl GT min(match.dec[0:match.nobj-1])) THEN match.decl = min(match.dec[0:match.nobj-1])
  IF (match.dech LT max(match.dec[0:match.nobj-1])) THEN match.dech = max(match.dec[0:match.nobj-1])



END 
