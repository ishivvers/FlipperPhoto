PRO ivalplot2, ivl, idx=idx, name=name

  IF NOT keyword_set(name) THEN name = ' '
  IF datatype(ivl) EQ 'STR' THEN iv = mrdfits(ivl) ELSE iv = ivl
  IF NOT keyword_set(idx) THEN idx = where(iv.tophase GT 1)
    
  imx = n_elements(idx)
  FOR i=0,imx-1 DO BEGIN 
      j = idx[i]
      IF datatype(ivl) EQ 'STR' THEN idlabel = 'File '+ivl ELSE idlabel = name+' '
      IF iv[j].tophase LE 1 THEN $
        print, 'Object number ', iv[j].index, ' not phased.  Skipping...' $
      ELSE BEGIN 
          !p.multi = [0,1,2]
          period = 1.0 / iv[j].freq
          t = (double(iv[j].n) + iv[j].phase) * period
          g = where(iv[j].good EQ 1,ng)
          IF ng LE 0 THEN print, 'No good observations.' ELSE BEGIN 
              idlabel = idlabel + 'Object number '+string(iv[j].index, format="(i5.5)")
              xt = t[g]
              tmax = max(xt)
              tmin = min(xt)
              tspan = tmax - tmin
              trange = [tmin-tspan*0.1,tmax+tspan*0.1]
              mags = iv[j].m[g] - iv[j].mavg
              merr = iv[j].mwholerr[g]
              
              write_lightcurve, xt, mags, merr, filename='templc.dat', /nomean
              comm = 'format_freq templc '+string(iv[j].freq,format="(f10.6)")+' 4'
              spawn, comm, junk
              read_freq_func, 'templc', xmp, mp, mpe, xp, yp

              fphas = where(xp LE 1.0, nphas)
              myp = min(yp[fphas], maxphi)
              maxph = xp[fphas[maxphi]]

              mmin = min(mags-merr)
              mmax = max(mags+merr)
              mspan = max(mags+merr)
              mrange = [mmax+0.1*mspan, mmin-0.1*mspan]
              
              plot, xt, mags, psym=4, ytitle='Mag - <Mag>', $
                xtitle='Time from '+string(iv[j].tzero,format="(f12.6)")+' (Days)', $
                xrange=trange, xstyle=1, yrange=mrange, ystyle=1, title=idlabel
              errplot, xt, mags+merr, mags-merr
              oplot, [-200.,2000.], [0.0,0.0], linestyle=3
              
              label = 'Mean Mag = '+string(iv[j].mavg, format="(f6.2)")+' : '
              label = label + 'Ivalue = '+string(iv[j].ival,format="(f8.4)")+' : '
              label = label + 'Signif = '+string(iv[j].ival/iv[j].siglim,format="(f4.1)")
              label = label + ' MaxPhase = '+string(maxph,format="(f4.2)")

              plot, xmp, mp, xrange=[0.,2.], psym=4, ytitle='Mag - <Mag>', $
                xtitle='Phase (Period = '+string(period,format="(f8.4)")+' d)', $
                title=label, xstyle=1, yrange=mrange, ystyle=1
              oplot, [-2.,4.], [0.0,0.0], linestyle=3
              errplot, xmp, mp-mpe, mp+mpe
              oplot, xp, yp, linestyle=0
          ENDELSE 
      ENDELSE 
  ENDFOR 
  idx = 0
  !p.multi = [0,1,1]
;  print, 'Finished plotting'
END
