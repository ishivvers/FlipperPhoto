pro percentile,arr,perc,index,num
if n_params() eq 0 then begin
 print,'syntax- percentile,arr,perc,index,num'
 return
endif
asort=sort(arr)
n=n_elements(arr)-1
ind=fix(perc*n)
index=asort(ind)
num=arr(index)
return
end
