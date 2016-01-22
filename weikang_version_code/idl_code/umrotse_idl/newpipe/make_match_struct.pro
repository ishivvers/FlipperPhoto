function make_match_struct, iobs, iobj, old=old, extended=extended, shorten=shorten, cdelt=cdelt

;+
; Purpose: create and initialize the standard match structure
;
; Created 00-04-10 Bob Kehoe
; Updated:  00-04-19 Bob Kehoe  -- generalized to allow filtering of existing
;				   match structure
; Updated: 06-05-00 Bob Kehoe -- many modifications
; Updated: 06-22-00 Eli Rykoff -- uses cdelt to get the pixel scale
;-

if not keyword_set(shorten) then begin
   if (N_params() lt 2) then begin
      print, 'Syntax match = make_match_struct(iobs,iobj[,old=oldmatch,extended=extended,shorten=longmatch,cdelt=cdelt]'
      return, -1
   endif
   nobs = n_elements(iobs)
   nobj = n_elements(iobj)
   if (not keyword_set(old) and (nobs ne 1 or nobj ne 1)) then begin
      print, 'Cannot filter unspecified match structure.'
      return, -1
   endif
endif

;  If old match structure is input, then obtain size for new structure and
;  how much to copy from old.

   if keyword_set(old) then begin
      i_obs = iobs
      i_obj = iobj
      if (nobs eq 1) then begin
         nobs = iobs
         nobs_cp = (size(old.jd))[1] < iobs
         i_obs = indgen(nobs_cp)
      endif else begin
         nobs = n_elements(i_obs)
         nobs_cp = nobs
      endelse
      if (nobj eq 1) then begin
         nobj = iobj
         nobj_cp = (size(old.ra))[1] < iobj
         i_obj = lindgen(nobj_cp)
      endif else begin
         nobj = n_elements(i_obj)
         nobj_cp = nobj
      endelse
   endif else if keyword_set(shorten) then begin
      nobs = (size(shorten.m))[1]
      nobj = (size(shorten.m))[2]
   endif else begin
      nobs = iobs
      nobj = iobj
   endelse

;  Create new match structure and initialize values.

   if keyword_set(extended) then begin
      dra = dindgen(nobs,nobj)
      ddec = dindgen(nobs,nobj)
   endif else begin
      dra = bytarr(nobs,nobj)
      ddec = bytarr(nobs,nobj)
   endelse
   match = create_struct("kx", findgen(nobs,4,4), "ky", findgen(nobs,4,4), "jd",$
	dindgen(nobs), "exptime", findgen(nobs), "imagename", sindgen(nobs),$ 
	"rac", findgen(nobs), "decc", findgen(nobs), "ral", findgen(1), "rah", $
	findgen(1), "decl", findgen(1), "dech", findgen(1), "m", $
	findgen(nobs,nobj), "merr", findgen(nobs,nobj), "flags", $
	indgen(nobs,nobj), "dra", dra, "ddec",ddec, "rflags", bindgen(nobs,nobj),$
	"msys", bindgen(nobs,nobj), "ra", dindgen(nobj), "dec", dindgen(nobj))
   match.m[*,*] = -1.0
   match.merr[*,*] = -1.0
   match.flags[*,*] = -1
   match.dra[*,*] = -1.0
   match.ddec[*,*] = -1.0
   match.rflags[*,*] = 0
   match.msys[*,*] = 0
   if keyword_set(extended) then match = create_struct(match, 'numobs', $
		intarr(nobj), 'consec', bytarr(nobj))

;  If an old match structure was input, copy into new structure.

   if keyword_set(old) then begin
      for k = 0,nobs_cp-1 do begin
         match.kx[k,*,*] = old.kx[i_obs[k],*,*]
         match.ky[k,*,*] = old.ky[i_obs[k],*,*]
      endfor
      match.jd = old.jd[i_obs]
      match.exptime = old.exptime[i_obs]
      match.imagename = old.imagename[i_obs]
      match.rac = old.rac[i_obs]
      match.decc = old.decc[i_obs]
      match.ral = old.ral
      match.rah = old.rah
      match.decl = old.decl
      match.dech = old.dech
      for k = 0,nobs_cp-1 do begin
         match.m[k,0L:nobj_cp-1L] = old.m[i_obs[k], i_obj[0L:nobj_cp-1L]]
         match.merr[k,0L:nobj_cp-1L] = old.merr[i_obs[k], i_obj[0L:nobj_cp-1L]]
         match.flags[k,0L:nobj_cp-1L] = old.flags[i_obs[k], i_obj[0L:nobj_cp-1L]]
         match.dra[k,0L:nobj_cp-1L] = old.dra[i_obs[k], i_obj[0L:nobj_cp-1L]]
         match.ddec[k,0L:nobj_cp-1L] = old.ddec[i_obs[k], i_obj[0L:nobj_cp-1L]]
         match.rflags[k,0L:nobj_cp-1L] = old.rflags[i_obs[k], i_obj[0L:nobj_cp-1L]]
	 match.msys[k,0L:nobj_cp-1L] = old.msys[i_obs[k], i_obj[0L:nobj_cp-1L]]
      endfor
      match.ra = old.ra[i_obj]
      match.dec = old.dec[i_obj]
      if keyword_set(extended) then begin
	 match.numobs = old.numobs[i_obj]
	 match.consec = old.consec[i_obj]
      endif
   endif else if keyword_set(shorten) then begin
      pixscale = cdelt*3600
      renorm = 255.0/(2.0*pixscale)
      struct_assign,shorten,match
      for l = 0, nobs-1 do begin
         gdobj = where(match.m[l,*] ne -1.0, count3)
         if (count3 ne 0) then begin
	    new_dra = 3600.0*(shorten.dra[l,gdobj]*cos(shorten.dec[gdobj]*!DTOR) - $
			shorten.ra[gdobj]*cos(shorten.dec[gdobj]*!DTOR))
            new_ddec = 3600.0*(shorten.ddec[l,gdobj] - shorten.dec[gdobj])
	    dis = sqrt(new_dra^2.0 + new_ddec^2.0)
	    badpos = where(dis gt 0.5*pixscale, count4)
	    if (count4 ne 0) then begin
	       tmparr = make_array(count4, /INT, value=set_flags('BADPOS',type='RFLAGS'))
	       match.rflags[l,gdobj[badpos]] = match.rflags[l,gdobj[badpos]] + tmparr
	    endif
	    match.dra[l,gdobj] = byte(0>renorm*(new_dra+pixscale)<255)
	    match.ddec[l,gdobj] = byte(0>renorm*(new_ddec+pixscale)<255)
	 endif
      endfor
   endif

   return, match
end






