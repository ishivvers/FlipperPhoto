FUNCTION make_match3, iobs, iobj, old=old
;+
; NAME: MAKE_MATCH3
;
; CALLING SEQUENCE: make_match3, iobs, iobj, old=old
;
; INPUTS:       iobs: number of observations
;               iobj: number of objects
;
; OUTPUTS:      the new match structure
;       
; INPUT KEYWORDS:
;               old: if there is an old match structure to fill in some of the new
;                       
; PROCEDURE:    Based on make_match_struct, this program will create and initialize
;               a match structure. The "shorten" functionality has been moved to a
;               different function: "short_match3".
;       
; REVISION HISTORY:  
;       Don Smith    UM      10/24/01
;       Don Smith    UM      11/13/01 - Changed dra/ddec into longs
;====================================================================================
;-

  abort = 0
  
  if (N_params() lt 2) then begin
      print, 'Syntax: match = make_match3(iobs,iobj[,old=oldmatch])'
      abort = -1
  ENDIF
  nobs = n_elements(iobs)
  nobj = n_elements(iobj)
  IF (NOT keyword_set(old) AND (nobs NE 1 OR nobj NE 1)) THEN BEGIN
      print, 'Cannot filter unspecified match structure.'
      abort = -1
  ENDIF


;  If old match structure is input, then obtain size for new structure and
;  how much to copy from old.

  IF abort EQ 0 THEN BEGIN
      IF keyword_set(old) THEN BEGIN
          i_obs = iobs
          i_obj = iobj
          IF (nobs EQ 1) THEN BEGIN
              nobs = iobs
              nobs_cp = (size(old.jd))[1] < iobs
              i_obs = indgen(nobs_cp)
          ENDIF ELSE BEGIN
              nobs = n_elements(i_obs)
              nobs_cp = nobs
          ENDELSE
          IF (nobj EQ 1) THEN BEGIN
              nobj = iobj
              nobj_cp = (size(old.ra))[1] < iobj
              i_obj = lindgen(nobj_cp)
          ENDIF ELSE BEGIN
              nobj = n_elements(i_obj)
              nobj_cp = nobj
          ENDELSE
      ENDIF ELSE BEGIN
          nobs = iobs
          nobj = iobj
      ENDELSE
      
;  Create new match structure and initialize values.
      
      dra = lindgen(nobs,nobj)
      ddec = lindgen(nobs,nobj)
      match = create_struct("kx", findgen(nobs,4,4), "ky", findgen(nobs,4,4), "jd",$
	dindgen(nobs), "exptime", findgen(nobs), "imagename", sindgen(nobs),$ 
	"rac", findgen(nobs), "decc", findgen(nobs), "ral", 0.0, "rah", $
	0.0, "decl", 0.0, "dech", 0.0, $
        "m", findgen(nobs,nobj), "merr", findgen(nobs,nobj), "flags", $
	indgen(nobs,nobj), "dra", dra, "ddec",ddec, "rflags", bindgen(nobs,nobj),$
	"msys", bindgen(nobs,nobj), "ra", dindgen(nobj), "dec", dindgen(nobj), $
        "numobs", intarr(nobj), "consec", bytarr(nobj), "ngood", indgen(nobj), $
        "mavg", findgen(nobj), "mstd", findgen(nobj), "m_lim",findgen(nobs))
      match.m[*,*] = -1.0
      match.merr[*,*] = -1.0
      match.flags[*,*] = -1
      match.dra[*,*] = 0
      match.ddec[*,*] = 0
      match.rflags[*,*] = 0
      match.msys[*,*] = 0
      match.consec[*] = 0
      match.numobs[*] = 0
      match.ngood[*] = 0
      match.mavg[*] = -1.0
      match.mstd[*] = -1.0
      match.ra[*] = 0.0
      match.dec[*] = 0.0
      match.m_lim[*] = 0.0

;  If an old match structure was input, copy into new structure.
      
      IF keyword_set(old) THEN BEGIN
          FOR k = 0,nobs_cp-1 DO BEGIN
              match.kx[k,*,*] = old.kx[i_obs[k],*,*]
              match.ky[k,*,*] = old.ky[i_obs[k],*,*]
          ENDFOR
          match.jd = old.jd[i_obs]
          match.m_lim = old.m_lim[i_obs]
          match.exptime = old.exptime[i_obs]
          match.imagename = old.imagename[i_obs]
          match.rac = old.rac[i_obs]
          match.decc = old.decc[i_obs]
          match.ral = old.ral
          match.rah = old.rah
          match.decl = old.decl
          match.dech = old.dech
          FOR k = 0,nobs_cp-1 DO BEGIN
              match.m[k,0L:nobj_cp-1L] = old.m[i_obs[k], i_obj[0L:nobj_cp-1L]]
              match.merr[k,0L:nobj_cp-1L] = old.merr[i_obs[k], i_obj[0L:nobj_cp-1L]]
              match.flags[k,0L:nobj_cp-1L] = old.flags[i_obs[k], i_obj[0L:nobj_cp-1L]]
              match.dra[k,0L:nobj_cp-1L] = old.dra[i_obs[k], i_obj[0L:nobj_cp-1L]]
              match.ddec[k,0L:nobj_cp-1L] = old.ddec[i_obs[k], i_obj[0L:nobj_cp-1L]]
              match.rflags[k,0L:nobj_cp-1L] = old.rflags[i_obs[k], i_obj[0L:nobj_cp-1L]]
              match.msys[k,0L:nobj_cp-1L] = old.msys[i_obs[k], i_obj[0L:nobj_cp-1L]]
          ENDFOR
          match.ra = old.ra[i_obj]
          match.dec = old.dec[i_obj]
          match.numobs = old.numobs[i_obj]
          match.consec = old.consec[i_obj]
          match.ngood = old.ngood[i_obj]
          match.mavg = old.mavg[i_obj]
          match.mstd = old.mstd[i_obj]
      ENDIF
      return, match
  ENDIF
  return, abort
END
