pro radec_circle,struct,obs,ra,dec,image=image,box=box,radius=radius,file=file,_extra=e

; Load the image, find an ra dec in it, display that chunk and circle it.

 if N_params() eq 0 then begin
	print,'Syntax: radec_circle,struct,obs,ra,dec,image=image,box=box,radius=radius, file = file'
 	return
 endif

; First find the ras and decs of objects which are in the image in
; question

 in=where(struct.m(obs,*) ne -1)
 ra_in=struct.ra(in)
 dec_in=struct.dec(in)

; Now find those in a box around the object

 if keyword_set(box) then begin
	size=box/2
 endif else begin
	size=0.4
 endelse
 if not keyword_set(radius) then begin
	radius=10
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

;Check if it is a new or old match structure...
info=n_elements(struct.rac)
if (info gt 1) then begin
  rac=struct.rac(obs)
  decc=struct.decc(obs)
endif else begin
  rac=struct.rac
  decc=struct.decc
endelse

;Now project the ras and decs of these to the plane:
  convert2xy,struct.ra(bin),struct.dec(bin),xc,yc,rac=rac,decc=decc
  kx=reform(struct.kx(obs,*,*))
  ky=reform(struct.ky(obs,*,*))
  kmap,xc,yc,xx,yy,kx,ky

;Now find the actual object position...
  convert2xy,ra,dec,xc,yc,rac=rac,decc=decc
  kmap,xc,yc,xa,ya,kx,ky
  x=xa(0)
  y=ya(0)


 xlow=min(xx) 
 xhigh=max(xx)
 ylow=min(yy)
 yhigh=max(yy)

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


 if keyword_set(image) then begin
    im=image
 endif else begin
    if keyword_set(file) then begin
        im=readfits(file,hdr)
    endif else begin
        info=str_sep(struct.imagename(obs)," ")
        name=info(0)
        narr=str_sep(name,'_')
        if (strmid(narr(2),5,4) eq '.fit') then begin
            imagename=narr(0)+'_'+narr(1)+'_'+strmid(narr(2),0,5)+'_c.fit'
        endif else begin
            imagename=struct.imagename(obs)
        endelse
        im=readfits(imagename,hdr)
    endelse
 endelse


 sky,im(xlow:xhigh,ylow:yhigh),sky,skyerr
 slow=sky-skyerr
 shigh=sky+skyerr*5
 !p.title='(RA,DEC)=('+string(ra)+','+string(dec)+') ; (X,Y)=('+string(x)+','+string(y)+')'
 tvim2_scl,im,xlow,xhigh,ylow,yhigh,range=[slow,shigh],_extra=e
 !p.title=''
 tvcircle,radius,x,y,/data

 ; Now find the peak value within a 5 pixel diameter box of the center
 peak_val = max(im((x-2.5):(x+2.5),(y-2.5):(y+2.5)))
 print,"The maximum value of the star is ", peak_val


 return

 end





















