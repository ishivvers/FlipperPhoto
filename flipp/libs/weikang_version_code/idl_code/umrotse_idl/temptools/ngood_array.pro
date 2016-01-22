pro ngood_array,struct,index,hits,objarray=objarray

 if N_params() eq 0 then begin
	print,'Syntax: ngood_array,struct,index,hits,objarray=objarray'
 	return
 endif

 if keyword_set(obj_array) then begin
      nobj=(size(objarray))(1)
 endif else begin
      nobj=(size(struct.m(0,*)))(2)
 endelse
 
 print,'Nobj = '+string(nobj)
 hits=lindgen(nobj)
 for i=0l,nobj-1,1 do begin
	obs=where(struct.m(index,i) ne -1)
	s=size(obs)
	if (s(0) eq 1) then begin
	   hits(i)=s(1)
	endif else begin
	   hits(i)=0
	endelse
 endfor

 return
 end


