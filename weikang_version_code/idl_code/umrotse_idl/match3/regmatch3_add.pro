PRO regmatch3_add, match, fst, x, stats, nschon, pair=pair, template=template, crop=crop,fail=fail
;+
; NAME: REGMATCH3_ADD
;
; CALLING SEQUENCE: regmatch3_add, match, fst, x, stats, nschon, pair=pair, template=template,fail=fail
;
; INPUTS:       match: a match structure; this is updated
;               fst: the array of cobj name structures
;               x: the index of the cobj file name to start with
;               stats: the array of cobj stat structures
;               nschon: the number of obs in the old match struct
;               template: ra/dec values to keep
;
; INPUT KEYWORDS: pair: if set, add cobj lists in pairs
;                 crop: set to discard all new object outside old match limits
;                       
; PROCEDURE:    The purpose of this function is to add observations to a field 
;       template. It will either add a single file, or, if "pair" is set, add
;       only those observations that are in a pair of files. Adapted from 
;       TYCHO_REGMATCH_ADD and TYCHO_REGMATCH_ADDPAIR
;       
; REVISION HISTORY:  
;       Don Smith               UM      10/19/01
;       Don Smith                       12/19/01 - Added template option
;       Don Smith                       08/20/02 - Added crop option
;       Eli Rykoff                      10/20/03 - reduced close_matches; fixed 
;                                                  multiple matching; improved
;                                                  pair matching
;       Eli Rykoff                      02/23/04 - new-style match structures,
;                                                  and clean up old code
;       Don Smith                       08/09/04 - Added sanity check
;       Eli Rykoff                      11/15/04 - returns "fail" if fails
;================================================================================
;-

; Set some initial variables
  fail = 0
  
;First read in the image list from the next file. 
  fail = read_slist(match, x, fst, l1, st1, stats, nschon)
  IF fail EQ 0 THEN BEGIN
      IF keyword_set(pair) THEN BEGIN 
; If this is pairwise matching, read in the sources and stats from the second file
          fail = read_slist(match, x+1, fst, l2, st2, stats, nschon)
          IF fail EQ 0 THEN BEGIN  
              close_match_radec,l1.ra,l1.dec,l2.ra,l2.dec,m1,m2,0.0009D,1.0,miss1,/silent,/box
              npairmatch=n_elements(m1)
              ;; this has been taken out, but may need to go back in
             ;; if (npairmatch lt 10) then begin
             ;;     print,'not enough matches in pair'
             ;;     fail = 1
             ;; endif

;Now reduce the lists to include JUST the ones which match each other.....
              print,'Matched ',n_elements(m1),' stars between two cobj lists.'
              IF n_elements(m1) GT 1 AND n_elements(m2) GT 1 THEN BEGIN 
                  l1=l1[m1]
                  l2=l2[m2]
              ENDIF 
              match_ra = (l1.ra + l2.ra) / 2d    ;; these are the positions to compare
              match_dec = (l1.dec + l2.dec) / 2d ;;  to the match structure
              h1=where(l1.m lt 25. AND l1.m GT 0.,ngm1)
              h2=where(l2.m lt 25. AND l2.m GT 0.,ngm2)
              IF ngm1 LT 1 OR ngm2 LT 1 THEN BEGIN 
                  fail = 1
                  print, 'Could not find any valid matches.'
              ENDIF ELSE BEGIN 
                  st1.m_lim = get_perc(90,l1[h1].m)
                  st2.m_lim = get_perc(90,l2[h2].m)
                  IF keyword_set(pair) THEN BEGIN 
                      st1.m_lim = (st1.m_lim + st2.m_lim)/2.0
                      st2.m_lim = st1.m_lim  
                  ENDIF 
              ENDELSE 
          ENDIF 
      ENDIF else begin
          match_ra = l1.ra
          match_dec = l1.dec
      endelse

      IF fail EQ 0 THEN BEGIN 
; If the crop keyword is set, eliminate those new sources that 
;    fall outside the limits of the old match structure
          IF keyword_set(crop) THEN BEGIN 
              ;;s = where(l1.ra GE match.ral AND l1.ra LE match.rah AND l1.dec GE
              ;;match.decl AND l1.dec LE match.dech)
              s = where(match_ra ge match.ral and match_ra le match.rah and $
                        match_dec gt match.decl and match_dec le match.dech, scnt)
              ;; need a count check here!
              if (scnt gt 0) then begin
                  l1 = l1[s]
                  match_ra=match_ra[s]
                  match_dec=match_dec[s]
                  IF keyword_set(pair) THEN BEGIN 
                      ;;  s = where(l2.ra GE match.ral AND l2.ra LE match.rah AND l2.dec GE match.decl AND l2.dec LE match.dech)
                      l2 = l2[s]
                  ENDIF 
              endif else begin
                  print,'no objects make the cut...'
                  fail = 1
              endelse
          ENDIF 
; At this point, we have either one or two lists, which need to be compared 
; with the match structure, and then stuffed into said structure.
          
;Now actually match these from one list to the master 
          if (fail eq 0) then begin
              compobj = lindgen(match.nobj)
              close_match_radec,match_ra,match_dec,match.ra[compobj],match.dec[compobj],mm1,mm2,0.0009d,1,/silent,/box
              print,'Matched ',n_elements(mm1),' objects from first cobj to existing match structure'
              stuff_match,match,l1,st1,mm1,mm2,stats,template=template
              print,'Match structure now has ' + string(match.nobj,format='(i6)') + $
                '/' + string(n_elements(match.ra),format='(i6)') + ' objects.'
              
              IF keyword_set(pair) THEN BEGIN 
                  stuff_match, match, l2, st2, mm1, mm2, stats, /pair, template=template
              ENDIF 
          endif
      ENDIF 
  ENDIF   
END
