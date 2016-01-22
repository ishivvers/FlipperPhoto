PRO lcplot3, m,iobj,iobs=iobs,gdobj=gdobj,good=good,err=err,syserr=syserr,nooffset=nooffset, $
             emask=emask,rmask=rmask,flagbadobs=flagbadobs,nowait=nowait,oplot=oplot, $
             charsize=charsize, trange=trange, tstyle=tstyle
;+ 
; NAME: LCPLOT3
;
; SYNTAX: lcplot3, m,iobj,iobs=iobs,gdobj=gdobj,good=good,err=err,syserr=syserr,nooffset=nooffset,
;             emask=emask,rmask=rmask,flagbadobs=flagbadobs,nowait=nowait,oplot=oplot
;
; INPUTS: m: a match structure
;         iobj: the indices of the objects to include
;         
; INPUT KEYWORDS:
;          iobs: if set, use just these obs.  Else use all.
;         gdobj: array of good objects, marked by a 'y' keypress.
;          good: plot "good" observations (don't plot -1's)
;           err: plot the statistical error on the observations
;        syserr: plot the statistical + systematic error (in quadrature)
;      nooffset: default is to subtract time of first obs.  Set this to override.
;         oplot: plot over a previous plot
;         emask: a mask for which SExtractor flags are "bad". Default = 0
;         rmask: a mask for which rotse rflags are "bad". Default = 0
;                rmask is not useful at this point
;                To filter out all bad rflags and eflags use emask=28, rmask=63
;    flagbadobs: plot all observations but put x's on bad ones.
;        nowait: plot all, without waiting for a keypress.
;        trange: specify a time range
;
; OUTPUTS: 
;                       
; PROCEDURE:    Plots the light curves of many objects.  Adapted
;               from LCPLOT2.
;
; REVISION HISTORY:
;    Created:        Don Smith       UM   10/29/01
;                    Eli Rykoff           02/23/04 -- works with new/old match
;                                                     strs      
;==============================================================
;-



;;  IF N_params() LT 2 THEN doc_library,'lcplot3' $
if n_params() lt 2 then begin
    print,'syntax- lcplot3, m,iobj,iobs=iobs,gdobj=gdobj,good=good,err=err,syserr=syserr,nooffset=nooffset,emask=emask,rmask=rmask,flagbadobs=flagbadobs,nowait=nowait,oplot=oplot,charsize=charsize,tstyle=tstyle'
    return
endif

  if tag_exist(m,'nobs') then begin
      allobs = lindgen(m.nobs)
      allobj = lindgen(m.nobj)
      nobs = m.nobs
      nobj = m.nobj
  endif else begin
      allobs = lindgen(n_elements(m.jd))
      allobj = lindgen(n_elements(m.ra))
      nobs = n_elements(m.jd)
      nobj = n_elements(m.ra)
  endelse

 ;; ELSE BEGIN 
      twait = 1.0
      gdobj = 1

      n=size(iobj)
      IF (n[0] EQ 0) THEN n=1 ELSE n=n[1]
      IF n GT 1 THEN print,'Examining light curves for ',n,' objects' $
      ELSE print, 'Examining light curves for one object' 
      o=lindgen(n)
      o[*]=iobj

      IF NOT keyword_set(iobs) THEN begin
          iobs = allobs
      endif
;;iobs = lindgen(n_elements(m.jd))

      offset=m.jd[0] 
      IF keyword_set(nooffset) THEN offset=0.0

;;    IF keyword_set(syserr) THEN BEGIN 
          ;; only calculate the ones we need
          


 ;;       the_err = sqrt(m.merr[0:nobs-1,0:nobj-1]^2 + (float(m.msys[0:nobs-1,0:nobj-1])/200.)^2)
 ;;       err = 1
 ;;   ENDIF ELSE the_err = m.merr[0:nobs-1,0:nobj-1]
      the_err = fltarr(nobs,nobj)
      if keyword_set(syserr) then begin
          for i=0l,n-1 do begin
              the_err[allobs,iobj[i]] = sqrt(m.merr[allobs,iobj[i]]^2. + $
                                             (float(m.msys[allobs,iobj[i]])/200.)^2.)             
          endfor
      endif else begin
          for i=0l,n-1 do begin
              the_err[allobs,iobj[i]] = m.merr[allobs,iobj[i]]
          endfor

      endelse


      IF NOT keyword_set(rmask) THEN rmask = 0
      IF NOT keyword_set(emask) THEN emask = 0

; Note: for later, it should take into account that exptime may be different      
      exp_time=m.exptime[0]
      bar_width=(float(exp_time)/(24.*60.*60.))/2.
      nbad = 0

      FOR k=0,n-1 DO BEGIN 
          i = iobs
          the_name = make_rotse3_name(m.ra[o[k]],m.dec[o[k]])

          if (n_elements(tstyle) eq 0) then tstyle = 1
          
          case tstyle of
              0: !p.title = ''
              1: !p.title='Object = '+string(o[k],format='(i6)')+' of '+$
            string(nobj,format="(i6)")+', Designation: '+the_name
              2: !p.title='Object = '+string(o[k],format='(i6)')+' of '+$
                string(nobj,format="(i6)")
          endcase

;;          !p.title='Object = '+string(o[k],format='(i6)')+' of '+$
;;            string(n_elements(m.m[0,*]),format="(i6)")+', Designation: '+the_name
          xlab = 'Days from MJD '+string(offset, format="(f13.6)")
          IF keyword_set(nooffset) THEN  xlab = 'Time in MJD'
          ylab = 'ROTSE Calibrated Magnitude'

          xsize = 0.5
          IF keyword_set(good) THEN BEGIN
              j=where(m.m[i,o[k]] GT 0 AND m.m[i,o[k]] LT 30 AND $
                      ((m.rflags[i,o[k]] AND rmask) EQ 0) AND $
                      ((m.flags[i,o[k]] AND emask) EQ 0), ngood)
              IF (ngood LE 1) THEN BEGIN 
                  print,"********No good observations!!!!!"
                  print,"Plotting all observations with nonnegative magnitudes..."
                  j = where(m.m[i,o[k]] GT 0 AND m.m[i,o[k]] LT 30,ngood)
                  xsym = 7
                  xsize = 1.0
              ENDIF ELSE xsym = 4
              IF ngood GT 0 THEN i = i[j]
              print, 'Plotting ',ngood,' out of ',n_elements(iobs),' observations.'
          ENDIF 

          IF keyword_set(flagbadobs) THEN $
            badobs=where(((m.rflags[iobs,o[k]] AND rmask) NE 0) $
                         OR ((m.flags[iobs,o[k]] AND emask) NE 0),nbad)
          
          minmag = min(m.m[i,o[k]]-the_err[i,o[k]])
          maxmag = max(m.m[i,o[k]]+the_err[i,o[k]])
          IF keyword_set(flagbadobs) THEN BEGIN 
              intobs = where(m.m[iobs,o[k]] GT 0)
              minmag = min(m.m[iobs[intobs],o[k]]-the_err[iobs[intobs],o[k]])
              maxmag = max(m.m[iobs[intobs],o[k]]+the_err[iobs[intobs],o[k]])
          ENDIF

          time = m.jd[i]-offset
          xspan = max(time) - min(time)
          mintim = min(time) - 0.1*xspan
          maxtim = max(time) + 0.1*xspan
          IF keyword_set(trange) THEN BEGIN 
              IF (size(trange))[0] EQ 1 AND (size(trange))[1] EQ 2 THEN BEGIN 
                  mintim = trange[0]
                  maxtim = trange[1]
              ENDIF 
          ENDIF 

          IF keyword_set(oplot) THEN $
            oplot,m.jd[i]-offset,m.m[i,o[k]],psym=7 $
          ELSE plot,m.jd[i]-offset,m.m[i,o[k]],psym=xsym,yrange=[maxmag,minmag],$
            xtitle=xlab,ytitle=ylab, symsize=xsize, xrange=[mintim,maxtim], $
            xstyle=1,charsize=charsize
              
          IF (keyword_set(flagbadobs) AND (nbad GT 0)) THEN BEGIN
              oplot,m.jd[iobs[badobs]]-offset,m.m[iobs[badobs],o[k]],psym=7,charsize=charsize
              IF keyword_set(err) OR keyword_set(syserr) THEN $
                plotbars,m.jd[iobs[badobs]]-offset,0,m.m[iobs[badobs],o[k]], $
                         the_err[iobs[badobs],o[k]]
          ENDIF 
          
          IF keyword_set(err) OR keyword_set(syserr) THEN $
            plotbars,m.jd[i]-offset,bar_width,m.m[i,o[k]],the_err[i,o[k]]

          IF NOT keyword_set(nowait) THEN BEGIN 
              print,'Press "y" to mark this object or press any key to continue.'
              r = get_kbrd(10)
              IF ((r EQ 'y') OR (r EQ 'Y')) THEN gdobj=[gdobj,o[k]]
          ENDIF ELSE wait, twait
          
          print,'Done with object number '+string(k,format="(i6)")
      ENDFOR
      IF (n_elements(gdobj) GT 1) THEN gdobj = gdobj[1:(n_elements(gdobj)-1)]
      !p.title = ''
;;  ENDELSE 
END
