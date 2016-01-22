PRO regmatch3_init, match, files, stat, lim, pair=pair, template=template, fail=fail
;+
; NAME: REGMATCH3_INIT
;
; CALLING SEQUENCE: regmatch3_init, m, files, stat, lim, nschon, pair=pair, template=template
;
; INPUTS:       files:  array of cobj filename structures
;               lim: four-element vector with ra and dec lim to keep
;               stat: the array of stat structures from the cobj files
;               template: ra/dec values to keep
;
; OUTPUTS:      match: the new match structure
;       
; INPUT KEYWORDS:
;               pair: set this if you want to save ONLY the matches from this pair...
;                       
; PROCEDURE:    The purpose of this function is to set up the template for
;       adding subsequent observations of this region of the sky.  It will
;       use the first two elements in the files array to do so.  Based on
;       TYCHO_REGMATCH_BEGIN.
;       
; REVISION HISTORY:  
;       Don Smith  UM      10/19/01
;       Don Smith  UM      11/13/01 - Changed dra/ddec to longs
;       Don Smith  UM      12/19/01 - Added template option
;       Don Smith  UM      03/03/31 - tightened template option -- no misses
;                                     are added
;       Eli Rykoff         02/23/04 - new-style match structures
;====================================================================================
;-

 fail = 0

; Read in calibrated object lists and associated statistics
  l1=mrdfits(files[0].file,1)
  l2=mrdfits(files[1].file,1)
  st1 = stat[0]
  st2 = stat[1]

  ;; temporary
  ;;if (not finite(l1[0].ra)) then begin
  ;;    print,'help! '+files[0].file+ ' is rotten.'
  ;;    killit
  ;;endif
  ;;if (not finite(l2[0].ra)) then begin
  ;;    print,'help! '+files[1].file+ ' is rotten.'
  ;;    killit
  ;;endif

; Check to make sure the images don't shift across the zero point in R.A.
; If they do, wrap l2 around by 2pi
 diff = st1.rac - st2.rac
 if (abs(diff) gt 350.0 and abs(diff) lt 370.0) then begin
    if (diff lt 0) then l2.ra = l2.ra - 360.0 
    if (diff gt 0) then l2.ra = l2.ra + 360.0
 ENDIF

 IF keyword_set(template) THEN BEGIN 
     close_match_radec,l1.ra,l1.dec,template.ra,template.dec,mo1,mo2,0.0009D,1.0,miss1,/box
     IF (size(mo1))[0] GT 0 THEN l1 = l1[mo1]
     close_match_radec,l2.ra,l2.dec,template.ra,template.dec,mp1,mp2,0.0009D,1.0,miss1,/box
     IF (size(mp1))[0] GT 0 THEN l2 = l2[mp1]
 ENDIF 

;Now define the parts of these lists which are within the selected region on
;the sky.

 IF NOT keyword_set(template) THEN BEGIN 
     n1=where(l1.ra gt lim[0] and l1.ra lt lim[1] and l1.dec gt lim[2] and l1.dec lt lim[3],nn1)
     n2=where(l2.ra gt lim[0] and l2.ra lt lim[1] and l2.dec gt lim[2] and l2.dec lt lim[3],nn2)
     
     ;Reduce the lists to just these parts of the list
     IF nn1 LE 30 OR nn2 LE 30 THEN BEGIN                            
     ; If there are not enough sources, widen the limits until there are
         centra = (lim[0]+lim[1])/2.
         centdec = (lim[2]+lim[3])/2.
         dra = lim[1] - centra
         ddec = lim[3] - centdec
         iter = 0
         WHILE ((nn1 LE 30) OR (nn2 LE 30)) and (iter lt 5) DO BEGIN 
             if (dra lt 0.1 or ddec lt 0.1) then begin
                 dra = 0.1
                 ddec = 0.1
             endif else begin
                 dra = dra * 1.2
                 ddec = ddec * 1.2
             endelse
             lim[0] = centra - dra
             lim[1] = centra + dra
             lim[2] = centdec - ddec
             lim[3] = centdec + ddec
             n1=where(l1.ra gt lim[0] and l1.ra lt lim[1] and l1.dec gt lim[2] and l1.dec lt lim[3],nn1)
             n2=where(l2.ra gt lim[0] and l2.ra lt lim[1] and l2.dec gt lim[2] and l2.dec lt lim[3],nn2)
             iter=iter+1
         ENDWHILE 
     ENDIF 
     
     if (n1[0] eq -1) or (n2[0] eq -1) then begin
         print,'Could not get an initial list'
         fail = 1
         return
     endif

     l1=l1[n1]
     l2=l2[n2]
 ENDIF 

;Now actually match these pieces of the two structures
 close_match_radec,l1.ra,l1.dec,l2.ra,l2.dec,m1,m2,0.0009D,1.0,miss1,/box

 if (miss1[0] eq -1) then begin
     nmisses1=0
 endif else begin
     nmisses1=N_elements(miss1)
 endelse
 nmatches = N_elements(m1)
 IF (size(m1))[0] EQ 0 THEN BEGIN 
     nmatches = 0
     nmisses1 = n_elements(l1)
     miss1 = lindgen(nmisses1)
 ENDIF 
 nob2=n_elements(l2)
 miss2=lindgen(nob2)
;; stop
 IF (size(m2))[0] GT 0 THEN remove,m2,miss2
 nmisses2=n_elements(miss2)
 nobj=nmatches+nmisses1+nmisses2 
 IF keyword_set(pair) OR keyword_set(template) THEN nobj=nmatches

 make_match3_new,match,2,nobj

 match.nobs = 2
 match.nobj = nobj
 match.numobs[*] = 2
 IF keyword_set(pair) THEN match.numobs[*] = 1
 match.jd[0] = st1.mjd
 match.exptime[0] = st1.exptime
 match.imagename[0] = st1.filename
 match.kx[0,*,*] = st1.kx
 match.ky[0,*,*] = st1.ky
 match.rac[0] = st1.rac
 match.decc[0] = st1.decc
 match.m_lim[0] = st1.m_lim
 match.ral=lim[0]
 match.rah=lim[1]
 match.decl=lim[2]
 match.dech=lim[3]
 match.jd[1] = st2.mjd
 match.exptime[1] = st2.exptime
 match.imagename[1] = st2.filename
 match.kx[1,*,*] = st2.kx
 match.ky[1,*,*] = st2.ky
 match.rac[1] = st2.rac
 match.decc[1] = st2.decc 
 match.m_lim[1] = st2.m_lim

 IF n_elements(m1) GT 1 THEN BEGIN 
     h1=where(l1[m1].m lt 25 AND l1[m1].m GT 0.)
     h2=where(l2[m2].m lt 25 AND l2[m2].m GT 0.)
     
     match.m_lim[0] = get_perc(90,l1[m1[h1]].m)
     match.m_lim[1] = get_perc(90,l2[m2[h2]].m)
     st1.m_lim = match.m_lim[0]
     st2.m_lim = match.m_lim[1]
     IF keyword_set(pair) THEN BEGIN 
         match.m_lim[0] = (match.m_lim[0] + match.m_lim[1])/2.0
         match.m_lim[1] = match.m_lim[0]
     ENDIF  

     IF NOT keyword_set(pair) THEN match.numobs[0:nmatches-1] = match.numobs[0:nmatches-1] + 1
     match.ra[0:nmatches-1]=(l1[m1].ra+l2[m2].ra)/2.0
     match.dec[0:nmatches-1]=(l1[m1].dec+l2[m2].dec)/2.0

     match.ddec[0,0:nmatches-1] = long(l1[m1].dec*1000000.)
     match.dra[0,0:nmatches-1] = long(l1[m1].ra*1000000.)
     match.ddec[1,0:nmatches-1] = long(l2[m2].dec*1000000.)
     match.dra[1,0:nmatches-1] = long(l2[m2].ra*1000000.)
     
     match.m[0,0:nmatches-1]=l1[m1].m
     match.merr[0,0:nmatches-1]=l1[m1].merr
     match.flags[0,0:nmatches-1]=l1[m1].flags
     
     IF (tag_exist(l1[0],'rflags')) THEN $
       match.rflags[0,0:nmatches-1]=l1[m1].rflags
     IF (tag_exist(l1[0],'msys200')) THEN $
       match.msys[0,0:nmatches-1]=l1[m1].msys200
     
     match.m[1,0:nmatches-1]=l2[m2].m
     match.merr[1,0:nmatches-1]=l2[m2].merr
     match.flags[1,0:nmatches-1]=l2[m2].flags

     IF (tag_exist(l2[0],'rflags')) THEN $
       match.rflags[1,0:nmatches-1]=l2[m2].rflags
     IF (tag_exist(l2[0],'msys200')) THEN $
       match.msys[1,0:nmatches-1]=l2[m2].msys200
 ENDIF 

 IF NOT keyword_set(pair) AND NOT keyword_set(template) THEN BEGIN     
     if (nmisses1 gt 0) then begin
         match.ra[nmatches:nmatches+nmisses1-1]=l1[miss1].ra
         match.dec[nmatches:nmatches+nmisses1-1]=l1[miss1].dec
         match.m[0,nmatches:nmatches+nmisses1-1]=l1[miss1].m
         match.merr[0,nmatches:nmatches+nmisses1-1]=l1[miss1].merr
         match.flags[0,nmatches:nmatches+nmisses1-1]=l1[miss1].flags
         IF (tag_exist(l1[0],'msys200')) THEN $
           match.msys[0,nmatches:nmatches+nmisses1-1]=l1[miss1].msys200
         IF (tag_exist(l1[0],'rflags')) THEN $
           match.rflags[0,nmatches:nmatches+nmisses1-1]=l1[miss1].rflags
     endif
     
     match.ra[nmatches+nmisses1:nobj-1]=l2[miss2].ra
     match.dec[nmatches+nmisses1:nobj-1]=l2[miss2].dec
     match.m[1,nmatches+nmisses1:nobj-1]=l2[miss2].m
     match.merr[1,nmatches+nmisses1:nobj-1]=l2[miss2].merr
     match.flags[1,nmatches+nmisses1:nobj-1]=l2[miss2].flags
     IF (tag_exist(l1[0],'msys200')) THEN $
       match.msys[1,nmatches+nmisses1:nobj-1]=l2[miss2].msys200
     IF (tag_exist(l1[0],'rflags')) THEN $
       match.rflags[1,nmatches+nmisses1:nobj-1]=l2[miss2].rflags

     if (nmisses1 gt 0) then begin
         match.ddec[0,nmatches:nmatches+nmisses1-1] = long(l1[miss1].dec*1000000.)
         match.dra[0,nmatches:nmatches+nmisses1-1] = long(l1[miss1].ra*1000000.)
     endif
     match.ddec[1,nmatches+nmisses1:nobj-1] = long(l2[miss2].dec*1000000.)
     match.dra[1,nmatches+nmisses1:nobj-1] = long(l2[miss2].ra*1000000.)
 ENDIF 

END
