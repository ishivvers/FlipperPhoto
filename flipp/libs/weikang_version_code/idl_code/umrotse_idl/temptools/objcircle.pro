pro objcircle,struct,obslist,object,title=title,box=box

; This is intended to circle an individual object in a bunch of
; observations

 if N_params() eq 0 then begin
	print,'Syntax: objcircle,struct,obslist,object'
	return
 endif

 nobs=(size(obslist))(1)
 print,'Number of observations is:',nobs

 print,'Available observations are:',obslist

 pmultiold=!p.multi
 !p.multi=[0,2,2]

 if (keyword_set(title)) then begin
     !p.title=title
 endif else begin
     title=''
 endelse

 if not keyword_set(box) then begin
     box=0.4
 endif

 for i=0,nobs-1,1 do begin
     print,''
     print,'Doing observation ',i+1,'           of ',nobs
     print,'' 
     !p.title=title+' '+struct.imagename(obslist(i))
     radec_mcirc,struct,obslist(i),struct.ra(object),$
	struct.dec(object),obj=object,box=box
     wait,3
 endfor

 !p.multi=[0,1,1]
 !p.title='' 

 return
 end








