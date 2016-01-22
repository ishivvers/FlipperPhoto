pro radec_mcirc,struct,obs,ra,dec,image=image,box=box,obj=obj,big=big

; Created:  ???
; Updated:  99-11-12  Bob Kehoe

; Load the image, find an ra dec in it, display that chunk and circle it.

 if N_params() eq 0 then begin
	print,'Syntax: radec_mcirc,struct,obs,ra,dec,image=image,box=box,obj=obj,big=big'
 	return
 endif

; First find the ras and decs of objects which are in the image in
; question

 in=where(struct.x(obs,*) ne -1)
 ra_in=struct.ra(in)
 dec_in=struct.dec(in)

; Now find those in a box around the object

 if keyword_set(box) then begin
	size=box/2
 endif else begin
	size=0.4
 endelse

 decliml=dec-size
 declimh=dec+size
 raliml=ra-(size / cos(dec*0.01745))
 ralimh=ra+(size / cos(dec*0.01745))

 bin=where(ra_in gt raliml and ra_in lt ralimh and $
 	dec_in gt decliml and dec_in lt declimh)

 if((size(bin))(0) eq 0) then begin
	print,'Position not in this image!'
	return
 endif

 print,raliml,ralimh,decliml,declimh

 help,bin
 bin=in(bin)

 xlow=min(struct.x(obs,bin)) 
 xhigh=max(struct.x(obs,bin))
 ylow=min(struct.y(obs,bin))
 yhigh=max(struct.y(obs,bin))

 x=0.5*(xlow+xhigh)
 y=0.5*(ylow+yhigh)

 xbig = 2032
 ybig = 2032
 if keyword_set(big) then begin
    xbig = 2034
    ybig = 2068
 endif

 if (x gt xbig) then begin
	print,'Position not in image!'
	return
 endif
 if (y gt ybig) then begin
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

 print,x,y

 if (xlow lt 0) then begin
	xlow=0
 endif
 if (ylow lt 0) then begin
	ylow=0
 endif
 if (xhigh gt xbig) then begin
	xhigh=xbig
 endif
 if (yhigh lt 0) then begin
	yhigh=ybig
 endif

 print,xlow,xhigh
 print,ylow,yhigh

 if keyword_set(image) then begin
    im=image
 endif else begin
    im=mrdfits(struct.imagename(obs),0,hdr)
 endelse
 sky,im(xlow:xhigh,ylow:yhigh),sky,skyerr
 slow=sky-skyerr
 shigh=sky+skyerr*5
 tvim2_scl,im,xlow,xhigh,ylow,yhigh,range=[slow,shigh]
 tvcircle,2.5,x,y,/data

 if (keyword_set(obj)) then begin
    tvcircle,5.0,struct.x(obs,obj),struct.y(obs,obj),/data
 endif

 return

 end





















