pro transform,x1,y1,x2,y2,kx,ky
if n_params() eq 0 then begin
 print,'syntax- transform,x1,y1,x2,y2,kx,ky'
 return
endif
in=dblarr(n_elements(x1),2)
in(*,0)=x1
in(*,1)=y1
mat=[[kx(0,1),kx(1,0)],[ky(0,1),ky(1,0)]]
v=replicate(1,n_elements(x1))
add=[[kx(0,0)],[ky(0,0)]]##v
out=mat##in+add
x2=out(*,0)+kx(1,1)*x1*y1
y2=out(*,1)+ky(1,1)*x1*y1
return
end
