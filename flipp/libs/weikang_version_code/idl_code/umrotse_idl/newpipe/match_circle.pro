pro match_circle,struct,obs,obj_index=obj_index,radius=radius

; Circle anything available in the current image from the structure. 
; Pick all objects found in "obs"
; If optional obj_index array is provided, then circle those positions....

 if N_params() eq 0 then begin
	print,'Syntax: match_circle,struct,obs,obj_index=obj_index,radius=radius'
 	return
 endif

 if not keyword_set(radius) then begin
	radius=2.5
 endif

; First find the ras and decs of objects which are in the image in
; question

 if (keyword_set(obj_index)) then begin
	in=obj_index
 endif else begin
  	in=where(struct.m(obs,*) ne -1)
 endelse

;Now project the ras and decs of these to the plane:
 rac=struct.rac
 decc=struct.decc
 convert2xy,struct.ra(in),struct.dec(in),xc,yc,rac=rac,decc=decc
 kx=reform(struct.kx(obs,*,*))
 ky=reform(struct.ky(obs,*,*))
 kmap,xc,yc,xx,yy,kx,ky

 tvcircle,radius,xx,yy,/data,noclip=0

 return

 end





















