pro rotse_match,rac,decc,sexcat,usnocat,xc,yc,kx=kx,ky=ky,time=time,sqsize=sqsize
;for matching a rotse catalog
;matches the center first and then works out from there
;make a 'square' from usno catalog and read into usnocat structure
;sexcat is the sextractor structure
;rac is ra center in degrees ie. 123.97177
;decc is dec center in degrees 
;sqsize is the size in pixels of the center square that 
;is matched first (150 is good)

if n_params() eq 0 then begin
print,'-syntax rotse_match,rac,decc,sexcat,usnocat,xc,yc,kx=kx,ky=ky,time=time,sqsize=sqsize'
return
endif

if n_elements(sqsize) eq 0 then sqsize=150
t0=systime(1)
pscl=.0038888 	;approximate pixel scale degrees per pixel


ra=usnocat.ra
dec=usnocat.dec
rmag=usnocat.rmag
convert2xy,ra,dec,xc,yc,rac=rac,decc=decc
ax=xc
ay=yc

x=sexcat.x_image
y=sexcat.y_image
mag=sexcat.mag_best


s1=sort(mag)
s1=s1(0:1000)
s2=sort(rmag)
s2=s2(0:5000)
x=x(s1)
y=y(s1)
mag=mag(s1)
xc=xc(s2)
yc=yc(s2)
ra=ra(s2)
dec=dec(s2)
rmag=rmag(s2)



wi1=where(x gt 1023-sqsize and x lt 1023+sqsize and y gt $
 1023-sqsize  and y lt 1023+sqsize)
decmin=decc-sqsize*pscl
decmax=decc+sqsize*pscl
ramin=rac-sqsize*pscl/cos(decc*!pi/180.0)
ramax=rac+sqsize*pscl/cos(decc*!pi/180.0)
wc1=where(ra gt ramin and ra lt ramax and dec gt decmin and dec lt decmax)   

x1=x(wi1)
y1=y(wi1)
mag1=mag(wi1)
s=sort(mag1)
x1=x1(s)
y1=y1(s)
mag1=mag1(s)


xc1=xc(wc1)
yc1=yc(wc1)
rmag1=rmag(wc1)
ra1=ra(wc1)
dec1=dec(wc1)
s=sort(rmag1)
xc1=xc1(s)
yc1=yc1(s)
rmag1=rmag1(s)
ra1=ra1(s)
dec1=dec1(s)

triangle_match,x1(0:23),y1(0:23),xc1(0:23),yc1(0:23),.002,1,trans,kx=kx,ky=ky,order=1
kx(1,1)=0.0
ky(1,1)=0.0

kmap,xc,yc,xx,yy,kx,ky

close_match,x,y,xx,yy,m1,m2,1.0,1,miss1
print,'misses plotted after linear transformation'
plot,x(miss1),y(miss1),psym=1

polywarp,x(m1),y(m1),xc(m2),yc(m2),3,kx,ky
kmap,xc,yc,xcc,ycc,kx,ky
xc=xcc
yc=ycc

close_match,x,y,xc,yc,m1,m2,1,1,miss1
print,'misses plotted after 3rd order transformation'
plot,x(miss1),y(miss1),psym=1
kmap,ax,ay,xc,yc,kx,ky

;this wont work because of memory
;strf=usnocat(0)
;strf2=create_struct(strf,'x',0.0,'y',0.0)
;str2=replicate(strf2,n_elements(ra))
;copy_struct,usnocat,str2
;usnocat=str2
;usnocat.x=xc
;usnocat.y=yc

if keyword_set(time) then begin
	print,systime(1)-t0,' seconds'
endif
return
end






