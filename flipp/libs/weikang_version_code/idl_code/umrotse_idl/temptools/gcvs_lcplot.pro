pro gcvs_lcplot,struct,index,obj,good=good,err=err,oplot=oplot,offset=offset,wait=wait,gcvs_cat=gcvs_cat,gcvs_index=gcvs_index

 if N_params() eq 0 then begin
	print,'Syntax: lcplot,struct,index,obj,good=good,err=err,oplot=oplot,offset=offset,wait=wait'
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
 help,o
 print,o

 if not keyword_set(offset) then begin
	offset=0.0
 endif

 if not keyword_set(wait) then begin
	twait=1.0
 endif else begin
	twait=wait
 endelse

 i=index

 for k=0,n-1,1 do begin 

   !p.title='object='+string(o(k))

   if keyword_set(good) then begin
     j=where(struct.m(i,o(k)) gt 0 and struct.m(i,o(k)) lt 30)
     i=i(j)
   endif

   if keyword_set(err) then begin
	if not keyword_set(oplot) then begin
	  ploterr,struct.jd(i)-offset,struct.m(i,o(k)),$
		struct.merr(i,o(k)),psym=1
	  if (keyword_set(gcvs_cat) and keyword_set(gcvs_index)) then begin 
		print,gcvs_index(k)
		print,gcvs_cat.type(gcvs_index(k))
		type='type: '+gcvs_cat.type(gcvs_index(k))
		min='min: '+strtrim(string(gcvs_cat.min(gcvs_index(k))),2)
		max='max: '+strtrim(string(gcvs_cat.max(gcvs_index(k))),2)
		index='index: '+strtrim(string(gcvs_index(k)),2)
		period='period: '$
			+strtrim(string(gcvs_cat.period(gcvs_index(k))),2)
		legend,[type,min,max,index,period],/right
	  endif
	  wait,twait
	endif else begin
	  oploterr,struct.jd(i)-offset,struct.m(i,o(k)),$
		struct.merr(i,o(k)),psym=7
	  wait,twait
	endelse
	print,'Done with '+string(k)
   endif else begin
	if not keyword_set(oplot) then begin
	   plot,struct.jd(i)-offset,struct.m(i,o(k)),psym=1,/ynozero
	   if (keyword_set(gcvs_cat) and keyword_set(gcvs_index)) then begin
		type='type: '+gcvs_cat.type(gcvs_index(k))
		min='min: '+strtrim(string(gcvs_cat.min(gcvs_index(k))),2)
		max='max: '+strtrim(string(gcvs_cat.max(gcvs_index(k))),2)
		index='index: '+strtrim(string(gcvs_index(k)),2)
		period='period: '$
			+strtrim(string(gcvs_cat.period(gcvs_index(k))),2)
		legend,[type,min,max,inde,period],/right
	   endif
	   wait,twait
	endif else begin
	   oplot,struct.jd(i)-offset,struct.m(i,o(k)),psym=7
	   wait,twait
	endelse
   endelse

 endfor

 !p.title=''

 return
 end

 




