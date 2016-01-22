pro indexmag,struct,index,mags,hits,objarray=objarray,hitlimit=hitlimit

;Selects objects from a match structure, finds the average magnitude
;of them for the chosen observations (supplied by index). It can also
;report only those beyond a certain "hitlimit"


 if N_params() eq 0 then begin
	print,'Syntax: indexmag,struct,index,mags,hits,objarray=objarray,hitlimit=hitlimit'
 	return
 endif

 if keyword_set(obj_array) then begin
      nobj=(size(objarray))(1)
 endif else begin
      nobj=(size(struct.m(0,*)))(2)
 endelse
 
 print,'Nobj = '+string(nobj)
 mags=findgen(nobj)
 hits=lindgen(nobj)
 for i=long(0),nobj-1,1 do begin
	obs=where(struct.m(index,i) ne -1 and struct.m(index,i) lt 30)
	info=size(obs)
	if (info(0) ne 0) then begin
	   hits(i)=info(1)
	   obs=index(obs)
	   if keyword_set(hitlimit) then begin
		if (hits(i) ge hitlimit) then begin
	       	  mags(i)=total(struct.m(obs,i))/hits(i)
		endif else begin
		  mags(i)=0
		endelse
	   endif else begin
		mags(i)=total(struct.m(obs,i))/hits(i)
	   endelse
        endif else begin
	   mags(i)=-1
	   hits(i)=0
	endelse
 endfor

 return
 end


