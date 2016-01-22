pro pagecircle,struct,obslist,objlist,title=title

; This is intended to circle an object in a bunch of observations.....

 if N_params() eq 0 then begin
	print,'Syntax: pagecircle,struct,obslist,objlist'
	return
 endif

 nobs=(size(obslist))(1)
 nobj=(size(objlist))(1)
 print,'Number of objects is:',nobj
 print,'Number of observations is:',nobs

 pmultiold=!p.multi
 !p.multi=[0,2,2]

 if (keyword_set(title)) then begin
     !p.title=title
 endif else begin
     title=''
 endelse

 for i=0,nobj-1,1 do begin
     print,''
     print,'Doing object ',i+1,'           of ',nobj
     print,''
     for j=0,nobs-1,1 do begin 
      ;k=where(struct.m(obslist,objlist(i)) ne -1)
      ;t=string(k,/print,format='(i3)')
      ;help,t
      ;print,t
      ;!p.title=title+' '+string(t,/print)
      !p.title=title+struct.imagename(j)
      radec_circle,struct,obslist(j),struct.ra(objlist(i)),$
	struct.dec(objlist(i)),obj=objlist(i),box=0.2
      text='mag='+strmid(strtrim(string(struct.m(j,objlist(i))),2),0,5)
      legend,[text],/right
     endfor
 endfor

 !p.multi=pmultiold
 !p.title='' 

 return
 end
