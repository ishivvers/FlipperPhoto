PRO testsearch, cat, tree, ra, dec, angle, depth

  ;; convert angle from arcsec to radians
  ang = angle/3600d*!dpi/180.

  print,'angle = ',angle
  
  htmIntersectradec, ra, dec, ang, depth, idlist

  help,idlist

  htmGetObj, idlist, tree, depth, outind

  help,outind

  gcirc, 0, cat[outind].ra*!dpi/180d, cat[outind].dec*!dpi/180d, $
            ra*!dpi/180d, dec*!dpi/180d, dis

  ;; also find in crude way
  gcirc, 0, cat.ra*!dpi/180d, cat.dec*!dpi/180d, $
            ra*!dpi/180d, dec*!dpi/180d, dis2

  disarc = dis*180d/!dpi*3600.

  print
  print,'Distances:'
  forprint,disarc

  w=where(disarc LE angle,nw)
  disarc = disarc[w]
  disarc = disarc[sort(disarc)]
  print,'# within search radius',nw
  forprint,disarc

  disarc2 = dis2*180d/!dpi*3600.
  w=where(disarc2 LE angle,nw)
  print
  print,'Other way',nw
  disarc2 = disarc2[w]
  disarc2 = disarc2[sort(disarc2)]
  forprint,disarc2

END 
