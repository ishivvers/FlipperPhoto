FUNCTION read_slist, m, i, nmst, list, stat, allstats, nn
;+
; NAME: READ_SLIST
;
; CALLING SEQUENCE: read_slist, m, i, nmst, list, stat, allstats, nn
;
; INPUTS:       m: a match structure
;               nmst: an array of cobj filename structures
;               x: the index for the next cobj filename
;               allstats: the array of all the stat structures
;               nn: the number of obs in the old match struct
;
; OUTPUTS:      list: the first cobj attachment to name
;               stat: the second cobj attachment to name
;
; RETURNS:      rerr: returns error report 0 = okay, 1 = failed
;       
; REVISION HISTORY:  
;       Don Smith               UM      10/25/01
;       Eli Rykoff                      02/23/04 -- removed truncating
;       Eli Rykoff                      11/15/04 -- more error checking
;================================================================================
;-

if n_params() lt 7 then begin
    print,'syntax- read_slist(m, i, nmst, list, stat, allstats, nn)'
    return,1
endif

  rerr = 0
  if (i ge n_elements(nmst)) then rerr = 1
  if (rerr eq 1) then return,rerr

  list = mrdfits(nmst[i].file,1,status=status)
  if (status ne 0) then begin
      rerr = 1
      return,rerr
  endif

  if (rerr eq 0) then begin
      stat = allstats[i+nn]

      diff = m.rac[0] - stat.rac
      if (abs(diff) gt 350.0 and abs(diff) lt 370.0) THEN BEGIN
          if (diff lt 0) then list.ra = list.ra - 360.0 
          if (diff gt 0) then list.ra = list.ra + 360.0
      ENDIF
      n = where(list.ra gt m.ral and list.ra lt m.rah and list.dec gt m.decl and list.dec lt m.dech)
      
      IF ((size(n))[1] lt 10) THEN BEGIN
          print,'Observation '+nmst[i].name+' has too few objects within the limits'
          rerr = 1
      ENDIF ;;ELSE list = list[n]  ;; do not truncate the list.  This is done later if necessary!
  endif
  return, rerr
END 
