PRO pow_chisq_conf, datax, data, dataerr, powvals, normvals, $
                    chisq_surf, pmin, nmin, powlow, powhigh, $
                    normlow, normhigh, $
                    powallow = powallow, normallow=normallow, $
                    plot_sig=plot_sig,$
                    chisq_diff=chisq_diff, noplotmin=noplotmin, $
                    plot_both=plot_both, aspect=aspect, center=center, $
                    _extra=extra, xtick_get=xtick_get, ytick_get=ytick_get, $
                    nodisplay=nodisplay

  IF n_params() LT 5 THEN BEGIN
      print,'-Syntax: pow_chisq_conf, datax, data, dataerr, powvals, normvals, '
      print,'        chisq_surf, pmin, nmin, powlow, powhigh, '
      print,'        normlow, normhigh, '
      print,'       powallow = powallow, normallow=normallow, '
      print,'       plot_sig=plot_sig,'
      print,'       chisq_diff=chisq_diff, noplotmin=noplotmin, '
      print,'        plot_both=plot_both, aspect=aspect, center=center, '
      print,'       _extra=extra, xtick_get=xtick_get, ytick_get=ytick_get, '
      print,'        nodisplay=nodisplay'
      print,'If /plot_sig then contours project to the 1-, 2-, 3-sig limits'
      print,'for the individual probability distribution.  If /plot_both, then'
      print,'both are plotted'
      return
  ENDIF 
                                ;68, 95, 99%
  levels1 = [1.00, 4.00, 6.63]   ;levels for single parameters
  levels2 = [2.30, 6.17, 9.21]   ;levels for joint probability
  IF NOT keyword_set(plot_sig) THEN plot_sig=0
  IF plot_sig THEN clevels = levels1 ELSE clevels=levels2
  IF keyword_set(plot_both) THEN BEGIN
      clevels=[1.00, 2.30, 4.00, 6.17, 6.63, 9.21]
      c_line= [1,    0,    1,    0,    1,    0   ]
  ENDIF ELSE c_line=[0,0,0]
  nlevels = n_elements(levels1)

  default = 1.e10
  powlow = replicate(default,nlevels)
  powhigh = replicate(default,nlevels)
  normlow = replicate(default,nlevels)
  normhigh = replicate(default,nlevels)

  w=where(dataerr EQ 0., nw)
  IF nw NE 0 THEN BEGIN
      print,'Some zero error vals'
      return
  ENDIF 

  nnorm = n_elements(normvals)
  npow  = n_elements(powvals)

  index = lindgen(npow*nnorm)
  x = index MOD npow
  y = index/npow

  chisq_surf = fltarr( npow, nnorm )
  modfunc = data

  errsquared=dataerr^2
  FOR in=0L, nnorm-1 DO BEGIN
      norm = normvals[in]
      FOR ip=0L, npow-1 DO BEGIN
          pow = powvals[ip]

     ;     modfunc[*] = norm*(datax)^pow
          modfunc[*] = norm + datax * pow
          
          ff= (data-modfunc)^2/errsquared
          chisq_surf[ip, in] = total(ff)

      ENDFOR 
  ENDFOR 

  minchisq = min(chisq_surf)
  
  chisq_diff = chisq_surf - minchisq

  IF NOT keyword_set(nodisplay) THEN BEGIN 
      IF n_elements(aspect) EQ 0 THEN BEGIN 
          contour, chisq_diff, powvals, normvals, $
            levels=clevels,c_line=c_line, $
            _extra=extra, xtick_get=xtick_get, ytick_get=ytick_get
      ENDIF ELSE BEGIN 
          acontour, aspect, chisq_diff, powvals, normvals, $
            levels=clevels,c_line=c_line, $
            _extra=extra, center=center, xtick_get=xtick_get, ytick_get=ytick_get
      ENDELSE 
  ENDIF 
  w=where(chisq_surf EQ minchisq, nw)

  pmin = (powvals[x[w]])[0]
  nmin = (normvals[y[w]])[0]
  IF NOT keyword_set(noplotmin) THEN oplot,[pmin],[nmin],psym=7

  ndata = n_elements(data)
  degfree = ndata-2

  print,'Min Chisq: ',minchisq,'/',ntostr(long(degfree)),' = ',ntostr(minchisq/degfree)

  FOR i=0L, nlevels-1 DO BEGIN

      IF plot_sig THEN w = where(chisq_diff LE levels1[i], nw) $
      ELSE w = where(chisq_diff LE levels2[i], nw)

      IF nw NE 0 THEN BEGIN 
          powlow[i] = min( powvals[ x[w] ] )
          powhigh[i] = max( powvals[ x[w] ] )

          normlow[i] = min( normvals[ y[w] ] )
          normhigh[i] = max( normvals[ y[w] ] )
      ENDIF 
      IF i EQ 0 THEN BEGIN ;; save 1-sigma region
          powallow = powvals[ x[w] ]
          normallow = normvals[ y[w] ]
      ENDIF 
  ENDFOR 

  return
END 
