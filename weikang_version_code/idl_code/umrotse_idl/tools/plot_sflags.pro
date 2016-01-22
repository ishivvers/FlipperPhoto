pro plot_sflags, match, obslist=obslist, objlist=objlist, log=log, hist=hist

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Plots sextractor flags for a set of objects 
; 
; Inputs:  match structure: must have .flags(obs,obj) tag
;
; Optional inputs:
;	   obslist: array of observation indices to use
;	   objlist: array of object indices to use
;	   log: make the plot on a log scale...
;
; Outputs: Plots flags for these objects....
;
; Author:  Tim McKay
; Date: 3/1/99
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Help message
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if n_params() eq 0 then begin
   print,'-syntax plot_sflags, match, obslist=obslist, objlist=objlist '
   return
endif

if not keyword_set(obslist) then begin
	obssize = (size(match.imagename))(1)
	obslist = indgen(obssize)
endif else begin
	obssize = n_elements(obslist)
endelse

if not keyword_set(objlist) then begin
	objsize = (size(match.ra))(1)
	objlist = lindgen(objsize)
endif

f=match.flags(obslist,*)
f=f(*,objlist)

help,f

hist=indgen(8)
hist(*)=0

for i=0,obssize-1,1 do begin
for j=0,7,1 do begin
  h=long(2L^j)
  k=where((f(i,*) and h) ne 0)
  s=size(k)
  if (s(0) eq 1) then hist(j)=s(1)
endfor
endfor

if keyword_set(log) then begin
	plot,hist,psym=10,/ylog,yrange=[0.1,10000]
endif else begin
	plot,hist,psym=10
endelse	

return

end