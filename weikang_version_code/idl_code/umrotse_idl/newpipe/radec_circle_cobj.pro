pro radec_circle_cobj,struct,im,ra,dec,box=box,radius=radius,_extra=e,verbose=verbose,tcat=tcat

; Find an ra dec in it, display that chunk and circle it.

 if N_params() eq 0 then begin
	print,'Syntax: radec_circle,struct,im,ra,dec,box=box,radius=radius,,_extra=e,verbose=verbose,tcat=tcat'
 	return
 endif

; First find the ras and decs of objects which are in the image in
; question

 in=where(struct.m gt 0)
 ra_in=struct(in).ra
 dec_in=struct(in).dec

; Now find those in a box around the object

 if keyword_set(box) then begin
	size=box/2
 endif else begin
	size=0.4
 endelse
 if not keyword_set(radius) then begin
	radius=2.5
 endif

 decliml=dec-size
 declimh=dec+size
 raliml=ra-(size / cos(dec*0.01745))
 ralimh=ra+(size / cos(dec*0.01745))

 bin=where(ra_in gt raliml and ra_in lt ralimh and $
 	dec_in gt decliml and dec_in lt declimh)

 if((size(bin))(0) eq 0) then begin
	print,'Position not in this image!'
	print,size(bin)
	return
 endif

 help,bin
 bin=in(bin)

 rac=(max(struct(bin).ra)-min(struct(bin).ra))/2 + min(struct(bin).ra) 
 decc=(max(struct(bin).dec)-min(struct(bin).dec))/2 + min(struct(bin).dec)

 convert2xy,struct(bin).ra,struct(bin).dec,xc,yc,rac=rac,decc=decc
 polywarp,struct(bin).x,struct(bin).y,xc,yc,3,kx,ky

 convert2xy,ra,dec,xc,yc,rac=rac,decc=decc
 kmap,xc,yc,xa,ya,kx,ky

 if keyword_set(tcat) then begin
   in=where(tcat.ra gt raliml and tcat.dec lt ralimh and $
	tcat.dec gt decliml and tcat.dec lt declimh)
   t=tcat(in)
   convert2xy,t.ra,t.dec,tx,ty,rac=rac,decc=decc
   kmap,tx,ty,txa,tya,kx,ky
   print
 endif
 
 xx=struct(bin).x
 yy=struct(bin).y 
 x=xa(0)
 y=ya(0)

 xlow=min(xx) 
 xhigh=max(xx)
 ylow=min(yy)
 yhigh=max(yy)

 if keyword_set(verbose) then begin 
   print,rac,decc
   print,x,y,xlow,xhigh,ylow,yhigh
 endif

 if (x gt 2034) then begin
	print,'Position not in image!'
	return
 endif
 if (y gt 2067) then begin
	print,'Position not in image!'
	return
 endif
 if (x lt 1) then begin
	print,'Position not in image!'
	return
 endif
 if (y lt 1) then begin
	print,'Position not in image!'
	return
 endif

 if (xlow lt 0) then begin
	xlow=0
 endif
 if (ylow lt 0) then begin
	ylow=0
 endif
 if (xhigh gt 2034) then begin
	xhigh=2034
 endif
 if (yhigh gt 2067) then begin
	yhigh=2067
 endif

 sky,im(xlow:xhigh,ylow:yhigh),sky,skyerr
 slow=sky-skyerr
 shigh=sky+skyerr*5
 tvim2_scl,im,xlow,xhigh,ylow,yhigh,range=[slow,shigh],_extra=e
 tvcircle,radius,x,y,/data

 if keyword_set(tcat) then begin
    tvcircle,radius/2.0,txa,tya,/data,noclip=0
 endif

 return

 end





















