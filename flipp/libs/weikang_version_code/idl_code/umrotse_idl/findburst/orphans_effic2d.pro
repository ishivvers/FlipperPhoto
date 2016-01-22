pro orphans_effic2d,mc,frac,err,xbins,ybins

; Created:  12-11-00  Bob Kehoe

  xbin = 0.025
  ybin = 0.1
  x1 = -3.0
  dx = 3.0
  nx = fix(dx/xbin)
  rx = dx/xbin - nx
  if (rx gt 0) then nx = nx + 1
  y1 = 5.0
  dy = 10.0
  ny = fix(dy/ybin)
  ry = dy/ybin - ny
  if (ry gt 0) then ny = ny + 1
  xbins = xbin*findgen(nx) + x1 + xbin/2.0
  ybins = ybin*findgen(ny) + y1 + ybin/2.0

;  Determine fraction array

  tot = fltarr(nx,ny)
  left = fltarr(nx,ny)
  for k = 0,ny-1 do begin		; the Y coordinate
     i = where(mc.peak ge (ybins[k]-ybin/2.0) and $
	       mc.peak lt (ybins[k]+ybin/2.0), count)
     tot[*,k] = histogram(mc.index[i], binsize=xbin, min=x1, max=(x1+dx))
     j = where(mc.pass[i] eq 1, count)
     if (count gt 1) then left[*,k] = histogram(mc.index[i[j]], binsize=xbin, $
						min=x1, max=(x1+dx))
  endfor
  frac = left/tot
  i = where(tot eq 0.0, count)
  if (count gt 0) then frac[i] = 0.0
  err = fltarr(nx,ny)

end
