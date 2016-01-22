; *****************************************************************************
; update_stats, c, h, s
;
; c = configuration structure from idlpacman
; h = stats structure (second attachment to cobj file)
; s = sobj structure 
; This program will pull certain information out of the header of the cobj
;   file and write it to a running log file.  It will also plot the night's
;   history of saturation and position error.
; 05/02/2002 - D. Smith - Added date string to plot 
; 03/28/2003 - D. Smith - Added date stamp to status monitor gif file name
; 10/07/2003 - D. Smith - Made label font size bigger
; 12/02/2003 - D. Smith - Added lock file for writing status graph
; 08/18/2004 - D. Smith - Added more diagnostic graphs, changed to FITS format
; 09/28/2004 - E. Rykoff - Added 2nd ext. graphs for daq updates
; 10/26/2004 - S. Yost - allow non-calib files, so add sobjonly flag
;              to tell it how to adjust graphs
;              also add to stats the # obj in sobj, & ibit (OK obj bc flags=0)
; 11/02/2005 - S. Yost  - adding the best zero-point file/structure: 
;                       bestzp.fit in conf.workdir
; 03/03/2005 - S. Yost  - fwhm created previously, in cal struct now                            
;; *****************************************************************************

PRO update_stats, c, h, s, zpstr, sobjonly=sobjonly
  num_points = 0

  save_pos = !p.position
  save_multi = !p.multi
  save_csize = !p.charsize
  save_device = !d.name

  nfields = n_elements(zpstr)

;; new_fwhm comes from the cal structure h.fwhm - created in
;;                                                rotse_iii_usno_cal
;;                                                or make_sobjstat

  new_fwhm = h.fwhm

  n_sobj = float(n_elements(s.flags))
;;  n_okobj = float(n_elements(ibit))
  ibit = where(s.flags EQ 0,ict)
  n_okobj = ict

  ostat = 0
  statfile = c.statdir + '/' + strmid(h.fname,0,6) + '_' + c.statroot + '_run.fit'
  no_updates = 0
;  print, 'looking for '+statfile
; make sure file exists
  openr, ulun, statfile, /get_lun, error=oerr
  IF (oerr NE 0) THEN BEGIN 
      print, 'Failed to find '+statfile+' (creating new one)'
      num_points = 1
      nstattemp = create_struct('fname','0', 'mjd', 1.0d, 'temp', 1.0, 'pra', 1.0d, $
                                'pdec', 1.0d, 'rra', 1.0d, 'rdec', 1.0d, 'ral', 1.0d, $
                                'rah', 1.0d, 'dcl', 1.0d, 'dch', 1.0d, 'fwhm', new_fwhm, $
                                'elev', 1.0, 'mlim', 1.0, 'wspd', 1.0,$
                                'azimuth', 0.0,$
                                'offstra', 0.0,$
                                'offstdec', 0.0,$
                                'offsttot', 0.0,$
                                'obstime', 0.0,$
                                'focus', 0.0,$
                                'nsat', 0l,$
                                'camtemp', 0.0,$
                                'winddir', 0.0,$
                                'barom', 0.0,$
                                'humidity', 0.0,$
                                'dewpoint', 0.0,$
                                'pos_sigma', 0.0,$
                                'meansub', 0.0,$
                                'stddevsub', 0.0,$
                                'mediansub', 0.0,$
                                'minsub', 0l,$
                                'maxsub', 0l,$
                                'encra', 0.0,$
                                'encdec', 0.0,$
                                'mounterr', 0.0,$
                                'satcnts', 0l,$
                                'vprecip', 0.0,$
                                'fscore', 0.0,$
                                'exptime', 0.0,$
                                'efftime', 0.0,$
                                'bzero', 0.0,$
                                'bscale', 0.0,$
                                'xfactor', 0,$
                                'yfactor', 0,$
                                'ncoadd', 0,$
                                'date_obs', '','loctime', '',$
                               'n_sobj', 0.0,$
                               'n_okobj', 0.0,$
                               'zp_off', 0.0,$
                               'zp_zpbest', -99.99)
 
      no_updates = 1
  ENDIF ELSE BEGIN 
      close, ulun
      free_lun, ulun
      ostat = mrdfits(statfile,1) 
      updates = mrdfits(statfile,2,status=status)   ;; the update information is in the 2nd ext
      if (status eq -2) then no_updates = 1
      nstattemp = ostat[0]
      num_points = n_elements(ostat)+1
  ENDELSE 

  if (no_updates) then begin
      ;; template for update information
      updates = create_struct('mjd', 0d, $                              
                              'ofocus', -1.0d, $
                              'nfocus', -1.0d, $
                              'ora', -1.0d, $
                              'nra', -1.0d, $
                              'odec', -100d, $
                              'ndec', -100d) 
  endif  

  nstat = replicate(nstattemp, num_points)

  IF num_points GT 1 THEN FOR i=0,num_points-2 DO nstat[i] = ostat[i]

  nstat[num_points-1].fname = h.fname
  nstat[num_points-1].mjd = h.mjd
  nstat[num_points-1].temp = h.tempout
  nstat[num_points-1].pra = h.mountra
  nstat[num_points-1].pdec = h.mountdec
  nstat[num_points-1].rra = h.crval1
  nstat[num_points-1].rdec = h.crval2
  nstat[num_points-1].ral = h.ra_low
  nstat[num_points-1].rah = h.ra_high
  nstat[num_points-1].dcl = h.dec_low
  nstat[num_points-1].dch = h.dec_high
  nstat[num_points-1].fwhm = new_fwhm
  nstat[num_points-1].elev = h.elev
  nstat[num_points-1].mlim = h.m_lim
  nstat[num_points-1].wspd = h.windspd

  nstat[num_points-1].azimuth=h.azimuth
  nstat[num_points-1].obstime=h.obstime
  nstat[num_points-1].focus=h.focus
  nstat[num_points-1].nsat=h.nsat
  nstat[num_points-1].camtemp=h.camtemp
  nstat[num_points-1].winddir=h.winddir
  nstat[num_points-1].barom=h.barom
  nstat[num_points-1].humidity=h.humidity
  nstat[num_points-1].dewpoint=h.dewpoint
  nstat[num_points-1].pos_sigma=h.pos_sigma
  nstat[num_points-1].meansub=h.mean
  nstat[num_points-1].stddevsub=h.stddev
  nstat[num_points-1].mediansub=h.median
  nstat[num_points-1].minsub=h.min
  nstat[num_points-1].maxsub=h.max
  nstat[num_points-1].encra=h.encra
  nstat[num_points-1].encdec=h.encdec
  nstat[num_points-1].mounterr=h.mounterr
  nstat[num_points-1].satcnts=h.satcnts
  nstat[num_points-1].vprecip=h.vprecip
  nstat[num_points-1].fscore=h.fscore
  nstat[num_points-1].exptime=h.exptime
  nstat[num_points-1].efftime=h.efftime
  nstat[num_points-1].bzero=h.bzero
  nstat[num_points-1].bscale=h.bscale
  nstat[num_points-1].xfactor=h.xfactor
  nstat[num_points-1].yfactor=h.yfactor
  nstat[num_points-1].ncoadd=h.ncoadd
  nstat[num_points-1].date_obs=h.date_obs
  nstat[num_points-1].loctime=h.loctime

  nstat[num_points-1].n_sobj=n_sobj
  nstat[num_points-1].n_okobj=n_okobj


  nstat[num_points-1].zp_off = h.zp_offset

;; check the list for 60-sec & 20-sec, and IF it's on the list (sky
;; patrol fields) AND best recorded isn't the dummy value -99.99 (for
;; no coverage wit h pos_sigma < 0.3), give the ZP offset relative to
;; the best recorded (kept in the structure)

  if not keyword_set(sobjonly) then begin
      if (abs(h.exptime-60) LT 0.01) then begin

          parts = str_sep(h.fname,'_') & fieldname=parts[1]
          ww =where( (zpstr.fieldname eq fieldname) AND (zpstr.best_zp60 gt -99) )

          if (min(ww) gt -1) then $
            nstat[num_points-1].zp_zpbest = h.zp_offset - zpstr[ww[0]].best_zp60

      endif else if (abs(h.exptime-20) LT 0.01) then begin

          parts = str_sep(h.fname,'_') & fieldname=parts[1]
          ww =where( (zpstr.fieldname eq fieldname) AND (zpstr.best_zp20 gt -99) )

          if (min(ww) gt -1) then $
            nstat[num_points-1].zp_zpbest = h.zp_offset - zpstr[ww[0]].best_zp20
      endif
  endif

;;stop

  IF num_points GT 1 THEN BEGIN 
      tz = min(nstat.mjd)
      DAYCNV, tz+2400000.5D, zyr, zmn, zday, zhr 
      tzstr = string(zyr,format="(i4.4)") + '/' + $
        string(zmn,format="(i2.2)") + '/' + string(zday,format="(i2.2)") + ', ' + $
        string(zhr, format="(f8.4)") + ' hours'
      ts = sort(nstat.mjd)
      hour = (nstat[ts].mjd - tz) * 24.
      set_plot, 'z'
      device, set_resolution=[600,800]  ;;hmm
      loadct, 39
      !p.background = 255
      !p.color = 0
;;      !p.multi = [0,2,3]
      !p.multi = [0,2,4]
      !p.charsize = 1.5
      !p.position = 0 ;; IF NE 0, !P.MULTI ONLY IS USED FOR 1st ELEMENT      

      ;; Get calendar date from Julian date
      IF num_points GT 1 THEN BEGIN 
          jd = double(nstat[ts[n_elements(ts)-1]].mjd) + 2400000.5D
          daycnv, jd, yr, mon, day, hr
          datelab = 'Last data point ' + string(yr,format="(i4.4)") + '/' + $
            string(mon,format="(i2.2)") + '/' + string(day,format="(i2.2)") + ' ' + $
            string(hr, format="(f8.4)") + ' hours'
          xyouts, 0.5, 0.5, datelab, alignment=0.5, /norm
      ENDIF 

      ;; prepare the offset (focus and pointing) info
      offhrs = (updates.mjd - tz) * 24.
      focoff = where(updates.ofocus ge 0, nfocoff)
      ptgoff = where(updates.ora ge 0, nptgoff)

      ;; figure out which had cobj, which don't
      wcobj = where(nstat[0:(num_points-2)].offsttot GT -9999.)
      if (keyword_set(sobjonly) AND min(wcobj) LT 0) then begin
          sobjlabel = "NOTHING CALIBRATED: sobj: "+strtrim(num_points,2)
          plotonlysobj=1
          nstat[num_points-1].offstra = -9999.
          nstat[num_points-1].offstdec = -9999.
          nstat[num_points-1].offsttot = -9999.
          aresobj=1
      endif else begin

          plotonlysobj=0
          if not(keyword_set(sobjonly)) then if (min(wcobj) LT 0) then wcobj = num_points-1 else wcobj=[wcobj,num_points-1]

;; now redo the sort

          ts = sort(nstat[wcobj].mjd)
          hour = [(nstat[ts].mjd - tz) * 24.]

;; explicitly get the sobj positions

          wsobj = where(nstat[0:(num_points-2)].offsttot LT -999.)
          if (keyword_set(sobjonly)) then if (min(wsobj) LT 0) then wsobj = num_points-1 else wsobj=[wsobj,num_points-1]

          if (min(wsobj) LT 0) then aresobj=0 else begin
              aresobj=1
              ts_s = sort(nstat[wsobj].mjd)
              hour_s = [(nstat[ts_s].mjd - tz) * 24.]
          endelse

      endelse


      ;;  !p.position = [0.55,0.55,0.95,0.95]
      if (plotonlysobj) then begin

          !p.multi=0
          plot, [hour], [hour-hour-99], /nodata, /ynozero, ytick_get = v, $
            xtitle='HOURS FROM '+tzstr, $
            ytitle='LIMITING MAGNITUDE'
          for i=0,nfocoff - 1 do begin
              plots,offhrs[focoff[i]],v[0]
              plots,offhrs[focoff[i]],v[1],/continue
          endfor
          xyouts, 0.3, 0.5, sobjlabel, /norm

      endif else begin
;;stop

          if (aresobj) then titlelab = "for "+strtrim(fix(n_elements(wcobj)),2)+" cobj files, plus "+strtrim(fix(n_elements(wsobj)),2)+" sobj only cases" $
          else titlelab = "for "+strtrim(fix(n_elements(wcobj)),2)+" cobj files"

          plot, [hour], [nstat[wcobj[ts]].mlim], psym=4, /ynozero, ytick_get = v, $
            xtitle='HOURS FROM '+tzstr, $
            ytitle='LIMITING MAGNITUDE', title=titlelab
          for i=0,nfocoff - 1 do begin
              plots,offhrs[focoff[i]],v[0]
              plots,offhrs[focoff[i]],v[1],/continue
          endfor
          maxmag = max(nstat[wcobj].mlim)
          maglab = 'Max. Limiting Mag = '+string(maxmag,format='(f4.1)')
          xyouts,0.11,0.94,maglab,/norm, charsize=1.2

          if (aresobj) then oplot, [hour_s], fltarr(n_elements(wsobj))+v[0], psym=2, symsize=2

      
      ;; Plot pointing offset
      ;; can only make these if calibrated
      dr = fltarr(num_points)-9999. & dd=dr & ds=dr
      dr[wcobj] = (nstat[wcobj].rra - nstat[wcobj].pra)*60.*cos(nstat[wcobj].rdec*3.14159/180.)
      dd[wcobj] = (nstat[wcobj].rdec - nstat[wcobj].pdec)*60.
      ds[wcobj] = sqrt(dd[wcobj]^2+dr[wcobj]^2)

      nstat[num_points-1].offstra = dr[num_points-1]
      nstat[num_points-1].offstdec = dd[num_points-1]
      nstat[num_points-1].offsttot = ds[num_points-1]

      if (aresobj) then begin
          if (max(wsobj) GT max(wcobj)) then maxplotind=max(wsobj) else maxplotind=max(wcobj) 
      endif else maxplotind=max(wcobj)

      
      plot, [dr[wcobj]], [dd[wcobj]], psym=2, /ynozero, $
        xtitle='R.A. POINTING OFFSET (arcmin)', $
        ytitle='Decl. POINTING OFFSET (arcmin)'
;;      oplot, [dr[num_points-1]], [dd[num_points-1]], psym=4, thick=3, color=240
      oplot, [dr[max(wcobj)]], [dd[max(wcobj)]], psym=4, thick=3, color=150
      oplot, [dr[max(wcobj)]], [dd[max(wcobj)]], psym=4, thick=1.5, symsize=1.5, color=0
      
      ;;  !p.position = [0.1,0.55,0.43,0.95]
      plot, [nstat[wcobj].temp], [nstat[wcobj].fwhm], psym=4, /ynozero, ytick_get=v,$
        ytitle='MEDIAN FWHM (pixels)', $
        xtitle='TEMPERATURE (F)'
      if (aresobj) then oplot, [nstat[wsobj].temp], [nstat[wsobj].fwhm], psym=2
      
      ;;  !p.position = [0.55,0.1,0.95,0.45]  
      plot, [nstat[wcobj].elev], [nstat[wcobj].fwhm], psym=5, /ynozero, $
        xtitle='ELEVATION (degrees)', $
        ytitle='MEDIAN FWHM (pixels)'
      if (aresobj) then oplot, [nstat[wsobj].elev], [nstat[wsobj].fwhm], psym=2
;;      oplot, [nstat[num_points-1].elev], [nstat[num_points-1].fwhm], psym=4, thick=3, color=240

      oplot, [nstat[maxplotind].elev], [nstat[maxplotind].fwhm], psym=4, thick=3, color=150
      oplot, [nstat[maxplotind].elev], [nstat[maxplotind].fwhm], psym=4, thick=1.5, color=0, symsize=1.5
      
      ;; Plot wind speed issues
      plot, [nstat[wcobj].wspd], [nstat[wcobj].fwhm], psym=4, symsize=0.7, /ynozero, $
        xtitle='WIND SPEED (mph)', ytitle='MEDIAN FWHM (pix)' 
      if (aresobj) then oplot, [nstat[wsobj].wspd], [nstat[wsobj].fwhm], psym=2
      
;      ;; take this one out in favor of ptg as f(t)
;      ;;      plot, nstat.wspd, ds, psym=4, symsize=0.7, /ynozero, $
;      ;;  xtitle='Wind Speed (mph)', ytitle='Pointing Offset (arcmin)' 
;      plot, [hour], [ds[wcobj[ts]]], psym=4, symsize=0.7, /ynozero, ytick_get = v, $
;        xtitle='Hours', ytitle='Pointing Offset (arcmin)'
;      if (aresobj) then oplot, [hour_s], fltarr(n_elements(wsobj))+v[0], psym=2
;      for i=0,nptgoff - 1 do begin
;          plots,offhrs[ptgoff[i]],v[0]
;          plots,offhrs[ptgoff[i]],v[1],/continue
;      endfor
;; plot instead the ZP offsets

      wherezp = where(nstat.zp_zpbest GT -99)
      if (min(wherezp) GT -1) then begin

          hrs = (nstat.mjd-tz)*24.

          if min(nstat[wherezp].zp_zpbest) EQ max(nstat[wherezp].zp_zpbest) then $
            yrange=[0.9*min(nstat[wherezp].zp_zpbest), 1.1*min(nstat[wherezp].zp_zpbest)]$
          else begin

              yrange=[min(nstat[wherezp].zp_zpbest),max(nstat[wherezp].zp_zpbest)]
          endelse

          plot, [min(hrs), max(hrs)], yrange, /nodata, xtitle='HOURS PAST '+tzstr, ytitle='ZP - BEST ZP'
; separate out 20-sec vs 60-sec, in case the difference shows?
          wherezp20 = where((nstat.zp_zpbest GT -99) and (abs(nstat.exptime - 20.0) lt 0.01))
          wherezp60 = where((nstat.zp_zpbest GT -99) and (abs(nstat.exptime - 60.0) lt 0.01))

          xx = [-1,-1,1,1,-1] & yy = [-1,1,1,-1,-1]
          usersym, xx, yy

          if (min(wherezp20) GT -1) then  oplot, [hrs[wherezp20]], [nstat[wherezp20].zp_zpbest], psym=8, symsize=0.7

          xx = [-1,-1,1,1,-1] & yy = [-1,1,1,-1,-1]
          usersym, xx, yy, /fill

          if (min(wherezp60) GT -1) then  oplot, [hrs[wherezp60]], [nstat[wherezp60].zp_zpbest], psym=8, symsize=0.7

      endif else begin

; plot a dummy
          plot, [0,1], [0,1], /nodata
          xyouts, 0.05, 0.6, "No images on the list", charsize=1.25
          xyouts, 0.05, 0.3, "to compare zeropts", charsize=1.25
          
      endelse


      ;; plot focus offset as f(t)
      if (nfocoff gt 0) then begin
          offsets = updates[focoff].nfocus-updates[focoff].ofocus
          cum_offsets = total([offsets],/cumulative)
          plot, offhrs[focoff], [offsets], psym=4, symsize=0.7, $
            yrange=[min([[offsets],[cum_offsets]]), max([[offsets],[cum_offsets]])], $
            xtitle='HOURS', ytitle='FOCUS UPDATE OFFSET (mm)'
          oplot, offhrs[focoff], [cum_offsets], psym=-5,symsize=0.7
      endif else begin
          plot, [0],[0],/nodata
          xyouts,0.5,0.5,'No Focus Updates', alignment=0.5, /data
      endelse

      ;; plot pointing offset as f(t)
      if (nptgoff gt 0) then begin
          udr = (updates[ptgoff].nra - updates[ptgoff].ora)*60.* $
            cos(updates[ptgoff].ndec*3.14159/180.0)-0.5
          udd = (updates[ptgoff].ndec - updates[ptgoff].odec)*60.
          uds = sqrt(udr^2. + udd^2.)

          cum_udr = total([udr], /cumulative)-udr[0]
          cum_udd = total([udd], /cumulative)-udd[0]
          cum_uds = sqrt(cum_udr^2. + cum_udd^2.)

          plot, offhrs[ptgoff], [uds], psym=4, symsize=0.7, $
            yrange=[min([[uds],[cum_uds]]),max([[uds],[cum_uds]])], $
            xtitle='HOURS', ytitle='POINTING UPDATE OFFSET (arcmin)'
          oplot, offhrs[ptgoff], [cum_uds], psym=-5, symsize=0.7
      endif else begin
          plot,[0],[0],/nodata
          xyouts,0.5,0.5,'No Pointing Updates', alignment=0.5, /data
      endelse

;; DONE PLOTTING

  endelse





      ;; Begin writing output files
      status_mon_name = strmid(h.fname,0,6) + '_' + c.statroot + '_mon.gif'
      lockname = status_mon_name + '.lock'
      
      lockf = findfile(lockname, count=count)
      IF count EQ 0 THEN BEGIN 
          openw, locklun, lockname, /get_lun
          printf, locklun, 'Locked'
          close, locklun
          free_lun, locklun
          
          if (float(!version.release) le 5.2) then begin
              write_gif, status_mon_name, tvrd()
          endif else begin
              write_png, status_mon_name, tvrd()
          endelse
          cmd = 'chmod 666 ' + status_mon_name + '; touch '+c.thumbfile
          spawn, cmd
          
          file_delete, lockname
      ENDIF 
  ENDIF ELSE BEGIN ;; for num_points =1, get dd/dr/ds

      if keyword_set(sobjonly) then begin
          nstat[num_points-1].offstra = -9999.
          nstat[num_points-1].offstdec = -9999.
          nstat[num_points-1].offsttot = -9999.
      endif else begin
          dr = (nstat[0].rra - nstat[0].pra)*60.*cos(nstat[0].rdec*3.14159/180.)
          dd = (nstat[0].rdec - nstat[0].pdec)*60.
          ds = sqrt(dd[0]^2+dr[0]^2)

          nstat[num_points-1].offstra = dr
          nstat[num_points-1].offstdec = dd
          nstat[num_points-1].offsttot = ds
      endelse

  ENDELSE



  slockname = statfile + '.lock'
  count = 1
  itr = 0
  while ((count eq 1) and (itr lt 10)) do begin
      slockf = findfile(slockname, count=count)
      itr=itr+1
      if (count eq 1) then wait,1   ;; wait 1 second if there's a file
  endwhile

  if (count eq 0) then begin
      ;; make the lockfile
      openw, slocklun, slockname, /get_lun
      printf, slocklun, 'Locked'
      close, slocklun
      free_lun, slocklun

      mwrfits, nstat, statfile, /create
      mwrfits, updates, statfile
      spawn, 'chmod 666 '+statfile

      ;; delete the lockfile
      file_delete, slockname
  endif

  !p.multi = save_multi
  !p.position = save_pos
  !p.charsize = save_csize 
  set_plot, save_device


END 
