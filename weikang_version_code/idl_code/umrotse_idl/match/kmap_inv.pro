pro kmap_inv,x2,y2,x,y,kx,ky,kxi=kxi,kyi=kyi,npoints=npoints
;this find the inverse map for kx and ky (any order)
;and applies it to x2,y2 to output x,y
;note that kx,ky does not in general have an inverse
;this procedure only works when the the map kx,ky is
;approximately a nonsingular linear transformation
;ie. the higher order terms do not dominate the map
;it works by first linearizing the map
;and finding the inverse matrix and using this to generate
;the approximate inverse map range (ie. the domain for kx,ky)
;using this range it maps test points to the x2,y2 neighborhood
;with kx,ky and uses polwarp on their image under the map kx,ky
;to find the right tranformation from x2,y2 to x,y
;it then applies this to x2,y2 to get x,y
;it then checks for accuracy
;then it returns kxi,kyi so that kmap can be used with these 
;for the inverse map in the future
;npoints is the number of points used to find the transformation
;if absent it will be set to the smaller of size(x2) or 10,000

if n_params() eq 0 then begin 
print,'-syntax kmap_inv,x2,y2,x,y,kx,ky,kxi=kxi,kyi=kyi,npoints=npoints'
return
endif
common seed,seed
num=n_elements(x2)
siz=size(kx)
order=siz(1)-1
kx=double(kx)
ky=double(ky)
x2=double(x2)
y2=double(y2)

if n_elements(npoints) eq 0 then begin
npoints= num < 10000l
endif

if npoints lt num then begin
	ind=num*randomu(seed,npoints)
	x3=x2(ind)
	y3=y2(ind)
	x3=x3-kx(0,0)
	y3=y3-ky(0,0)
endif else begin
	x3=x2-kx(0,0)
	y3=y2-ky(0,0)
endelse

mat=dblarr(2,2)		;the linearized matrix of kx,ky to be
mat(0,0)=kx(0,1)
mat(1,0)=kx(1,0)
mat(0,1)=ky(0,1)
mat(1,1)=ky(1,0)

mati=invert(mat,status,/double)
if status ne 0 then begin
	print,'inversion unsuccessful'
	print,'linearized map is singular or unstable'
	return
endif

u=dblarr(npoints,2)
u(*,0)=x3
u(*,1)=y3

v=mati##u

x=v(*,0)
y=v(*,1)

kmap,x,y,x3,y3,kx,ky

polywarp,x,y,x3,y3,order,kxi,kyi
kxi=double(kxi)
kyi=double(kyi)
;plot,x,y,psym=1
kmap,x2,y2,x,y,kxi,kyi

return
end






