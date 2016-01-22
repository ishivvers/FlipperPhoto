pro combine_structs,str1,str2,strsum
;+
; NAME:
;    COMBINE_STRUCTS
;
; PURPOSE:
;  takes two arrays of structures str1,str2 which have the
;  same number of elements but possibly different tags
;  and makes another structure which has the same number of elements
;  but the tags of both str1,str2 and has their respective tags 
;  values copied into it
;
; Author Dave Johnston UofM
;-

if n_params() LT 2 then begin 
	print,'-syntax combine_structs,str1,str2,strsum'
	return
endif

s1=size(str1)
s2=size(str2)

if s1(1) ne s2(1) then begin
	print,'structure sizes are different'
	return
endif

str=create_struct(str1(0),str2(0))
strsum=replicate(str,s1(1))
copy_struct,str1,strsum
copy_struct,str2,strsum

return
end
