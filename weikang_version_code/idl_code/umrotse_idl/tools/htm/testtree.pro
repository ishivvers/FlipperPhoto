PRO testtree, cat, tree, depth, sdss2=sdss2

  ttot = systime(1)

  depth = 9

  time=systime(1)
  IF NOT tag_exist(cat, 'ra') THEN BEGIN 
      survey2eq, cat.lambda, cat.eta, ra, dec
      print,'Time for converting (lambda,eta) to (ra,dec)'
      ptime,systime(1)-time
      print
  ENDIF ELSE BEGIN 
      ra = cat.ra
      dec = cat.dec
  ENDELSE 

  htmBuildTree, depth, ra, dec, tree, uniqleafid=uniqleafid
  print,'Time to build tree'
  ptime,systime(1)-time
  print

  ;; free the memory
  ra=0
  dec=0

  ;; now try to extract the objects back out of tree
  indices = lindgen(n_elements(cat))
  time=systime(1)
  htmGetObj, uniqleafid, tree, depth, newindices, count
  print,'Time for getting objects from tree'
  ptime,systime(1)-time
  print
  print,'Total time'
  ptime,systime(1)-ttot

  print
  print,'Old # = '+ntostr(n_elements(indices))+'  New # = '+ntostr(count)
  
  match, indices, newindices, mold, mnew, /sort

  nmatch = n_elements(mold)
  print,'# of matches = '+ntostr(nmatch)

END

