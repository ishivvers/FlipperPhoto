PRO assign_sigma, ist
  g = where(ist.iflag EQ 1,ng)
  IF ng GT 0 THEN BEGIN 
      ix = sort(ist[g].mavg)
      ix = g[ix]
      
      n = 0
      nbin = 100
      WHILE n LT ng DO BEGIN 
          nmax = n+nbin
          IF nmax GE ng THEN nmax = ng
          ibin = ist[ix[n:nmax-1]].ival
          IF n_elements(ibin) GT 2 THEN $
            sig = stddev(ibin) $
          ELSE sig = 20000.0
          ist[ix[n:nmax-1]].siglim = sig
          n = n + nbin
      ENDWHILE 
  ENDIF 
END 
