pro find_trans,x1,y1,x2,y2,kx,ky,order,show=show
if n_params() eq 0 then begin
  print,' syntax- find_trans,x1,y1,x2,y2,kx,ky,order'
  return
endif
if n_elements(order) eq 0 then order=1
polywarp,x1,y1,x2,y2,order,kx,ky
if keyword_set(show) then begin
	print,'kx is:'
	print,kx
	print,'ky is:'
	print,ky
endif
return
end
