pro one_search,array1,array2,m1,m2,no1,no2
;+
; NAME: ONE_SEARCH
;
; PURPOSE: To find common elements in array1 and array2.
;
; CALLING SEQUENCE: one_search,array1,array2,m1,m2,no1,no2
;
; INPUTS: array1, array2 - arrays to find common elements in.
;
; OPTIONAL INPUTS:
;
; OUTPUTS: m1 - indicies of array1 common to array2
;          m2 - indicies of array2 common to array1
;      (i.e. array1(m1)=array2(m2))
;
; OPTIONAL OUTPUTS: no1 - indicies to array2 of elements 
;           IN array2 and NOT in array1.
;                   no2 - indicies to array1 of elements 
;           IN array1 and NOT in array2.
;
; NOTES:
;
; EXAMPLE: To find common elements in array1=[1,5,2,7] and array2=[3,4,1,2] do:
;  IDL> one_search,array1,array2,m1,m2,no1,no2 
;  IDL> print,m1                              
;           0           2
;  IDL> print,m2                              
;           2           3
;  IDL> print,no1                             
;           0           1
;  IDL> print,no2                             
;           1           3
;
; PROCEDURES CALLED: BINARY_SEARCH2
;
; REVISION HISTORY:
;          Susan Amrose     UM   3/23/99
;-
 On_error,2                                      ;Return to caller

if n_params() eq 0 then begin
	print,'syntax-oned_search,array1,array2,m1,m2,no1,no2'
	return
endif

n1=long(n_elements(array1))
n2=long(n_elements(array2))
m1=replicate(long(-1),n1)
m2=replicate(long(-1),n2)
no1=lindgen(n2)
no2=lindgen(n1)
sor1=sort(array1)
sor2=sort(array2)

n=0
for i=long(0),long(n2)-1 do begin
  binary_search2,array1(sor1),array2(i),index
  if index ne -1 then begin
	m1(n)=sor1(index)
	m2(n)=i
        n=n+1
  endif
endfor

test1=where(m1 eq -1)
test2=where(m2 eq -1)
if test1(0) gt 0 then begin
  remove,test1,m1
  remove,m1,no2
endif else if test1(0) ne -1 then m1=-1 else no2=-1
if test2(0) gt 0 then begin
  remove,test2,m2  
  remove,m2,no1
endif else if test2(0) ne -1 then m2=-1 else no1=-1

return
end