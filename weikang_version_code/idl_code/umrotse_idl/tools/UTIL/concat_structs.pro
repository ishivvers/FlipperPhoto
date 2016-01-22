pro concat_structs,str1,str2,str_out
;+
; NAME:
;    CONCAT_STRUCTS
; 
; PURPOSE:
;  for concatenating two arrays of structures of the same type
;  it looks a little cludgy but it works (got a better idea?)
;  str_out will have the sum of the first two
;
; Author: Dave Johnston  UofM
;-
if n_params() LT 2 then begin 
	print,'-syntax concat_structs,str1,str2,str_out'
	return
endif

s1=size(str1)
s2=size(str2)
l1=s1(1)
l2=s2(1)
tot=l1+l2

st=str1(0)

str_out=replicate(st,tot)

str_out(0:l1-1)=str1

ntags=n_tags(str1)
tags=tag_names(str1)

for i=0,ntags-1 do begin
tag=tags(i)
ph1='str_out('+string(l1)+':'+string(tot-1)+').'+tag+'=str2.'+tag
ph1=strcompress(ph1,/remove_all)
bbb=execute(ph1)
endfor

return
end


 
