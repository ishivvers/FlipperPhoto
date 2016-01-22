function check_gaussfit,x,y

if n_params() lt 2 then begin
    print,'syntax- okay=check_gaussfit(x,y)'
    return,0
endif

ny = n_elements(y)
nx = n_elements(x)

if (nx ne ny) then begin
    print,'x and y arrays must have the same number of elements.'
    return,0
endif

if (nx lt 3) then begin
    print,'arrays must have at least 3 elements'
    return,0
endif

yd=y
n=ny

ymax=max(yd, imax)
xmax=x[imax]
ymin=min(yd, imin)
xmin=x[imin]
if abs(ymax) gt abs(ymin) then i0=imax else i0=imin ;emiss or absorp?

i0 = i0 > 1 < (n-2)		;never take edges
dy=yd[i0]			;diff between extreme and mean
del = dy/exp(1.)		;1/e value
i=0
while ((i0+i+1) lt n) and $	;guess at 1/2 width.
  ((i0-i) gt 0) and $
  (abs(yd[i0+i]) gt abs(del)) and $
  (abs(yd[i0-i]) gt abs(del)) do i=i+1

check = abs(x[i0]-x[i0+i])

if (check eq 0.0) then begin
    print,'Key value is 0.  Do Not Use gaussfit!'
    return,0
endif

return,1

end
