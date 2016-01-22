pro lcplot,struct,index,obj,good=good,err=err,syserr=syserr,oplot=oplot,offset=offset,wait=wait,_extra=e

 if N_params() eq 0 then begin
	print,'Syntax: lcplot,struct,index,obj,good=good,err=err,syserr=syserr,oplot=oplot,offset=offset,wait=wait'
	print,'If you specify /offset (or offset=1), then struct.jd(0) is used.' 
 	return
 endif

 n=size(obj)
 if (n(0) eq 0) then begin
	n=2
 endif else begin
	n=n(1)
 	print,'Examining light curves for ',n,' objects'
 endelse

 o=lindgen(n)
 o(*)=obj

 if not keyword_set(offset) then begin
	offset=0.0
 endif

 if not keyword_set(wait) then begin
	twait=1.0
 endif else begin
	twait=wait
 endelse

 if (offset eq 1) then begin
	offset=struct.jd(0)
 endif

 if keyword_set(syserr) then begin
   the_err = sqrt(struct.merr^2 + (struct.msys/200.)^2)
   err=1
 endif else begin
   the_err = struct.merr
 endelse


 for k=0,n-1,1 do begin 

   i=index

   !p.title='object='+string(o(k))

   if keyword_set(good) then begin
     j=where(struct.m(i,o(k)) gt 0 and struct.m(i,o(k)) lt 30)
     i=i(j)
   endif

   if keyword_set(err) then begin
	if not keyword_set(oplot) then begin
	  ploterr,struct.jd(i)-offset,struct.m(i,o(k)),$
		the_err(i,o(k)),psym=1,_extra=e
	  wait,twait
	endif else begin
	  oploterr,struct.jd(i)-offset,struct.m(i,o(k)),$
		the_err(i,o(k)),7
	  wait,twait
	endelse
	print,'Done with '+string(k)
   endif else begin
	if not keyword_set(oplot) then begin
	   plot,struct.jd(i)-offset,struct.m(i,o(k)),psym=1,/ynozero,_extra=e
	   wait,twait
	endif else begin
	   oplot,struct.jd(i)-offset,struct.m(i,o(k)),psym=7,_extra=e
	   wait,twait
	endelse
   endelse

 endfor

 !p.title=''

 return
 end

 




