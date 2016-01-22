pro setup_epochs, st, sensitivity, ntiles=ntiles
;+
; NAME: Setup Epochs
;
; PURPOSE:
;	Create a set of exposure lengths and epochs from settings in user_settings.pro
;
; CALLING SEQUENCE:
;       setup_epochs, st, sensitivity, ntiles=ntiles
;
; INPUTS:
;	sensitivity:	image sensitivity
;
; Keywords:
;	ntiles:		number of fields observed
;
; Outputs:
;	st:		updated statistics structure with epoch sequence variables
;
; REVISION HISTORY:
;	Bob Kehoe	UM	9/19/00
;	Bob Kehoe	UM	11/30/00  -- improve way deal with orphans data
;-
 On_error,2              ;Return to caller

 if N_params() lt 2 then begin
    print, 'Syntax:  setup_epochs, stat, sensitivity, ntiles=ntiles'
    return
 endif

; Initialization

 nobs = (size(st.m_lim))[1]
 user_settings, exptime=exptime_single, readtime=readtime, ncoadds=ncoadds, $
	nsingles=nsingles, mjd=mjd
 coadd_exptime = ncoadds*exptime_single
 coadd_efftime = ncoadds*exptime_single + (ncoadds-1)*readtime
 coadd_mlim = sensitivity
 mlim_single = coadd_mlim - (sqrt(ncoadds) - 1.0)	; uncoadded image sensitivity
 if not keyword_set(ntiles) then ntiles = 1

; Determine structure of data

 if (ntiles eq 1) then begin				; STARE data

; Fill observation parameters for STARE data

    st.exptime = coadd_exptime
    st.efftime = coadd_efftime
    st.m_lim = coadd_mlim
    st.obstime = (coadd_efftime+readtime)*findgen(nobs) + 10.0
    st.ncoadd = ncoadds
 endif else begin						; ORPHANS data

; Fill observation parameters for ORPHANS data

    twos = nsingles/ncoadds
    spares = nsingles mod ncoadds
    gap = twos*(coadd_efftime+readtime) + spares*(exptime_single+readtime)
    seq = intarr(nobs)
    increment = fltarr(nobs)
    ntwos = 0
    index = 0
    while (index lt nobs-twos-1 and index lt nobs-spares-1) do begin
       if (ntwos lt 2) then begin
          seq[index:index+twos-1] = 2
	  index = index + twos
	  ntwos = ntwos + 1
	  if (ntwos eq 1) then increment[index] = gap
	  nspares = 0
       endif else if (nspares lt 2) then begin
	  seq[index:index+spares-1] = 1
	  index = index + spares
	  nspares = nspares + 1
	  if (nspares eq 1) then increment[index] = gap
       endif else begin
	  ntwos = 0
       endelse
    endwhile
    if (index lt nobs-1) then begin
       seq[index:nobs-1] = 2
       increment[index] = gap
    endif
    st[0].obstime = 10.0
    for k = 0,nobs-1 do begin
       if (seq[k] eq 2) then begin
	  st[k].exptime = coadd_exptime
	  st[k].efftime = coadd_efftime
	  st[k].m_lim = coadd_mlim
	  st[k].ncoadd = ncoadds
       endif else if (seq[k] eq 1) then begin
	  st[k].exptime = exptime_single
	  st[k].efftime = exptime_single
	  st[k].m_lim = mlim_single
	  st[k].ncoadd = 1
       endif
       if (k ne 0) then st[k].obstime = st[k-1].obstime + st[k-1].efftime + readtime +increment[k]
    endfor
 endelse

 st.mjd = mjd + (st.obstime/(3600.0*24.0))

 return
end


