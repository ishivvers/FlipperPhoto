pro combinations_of3,n,combos
if n gt 500 then begin
print,'too big-takes too long'
combos=-1
return
endif

n=long(n)
num=(n*(n-1)*(n-2))/6
combos=intarr(3,num)
count=0l
i=0l
while i lt n-2 do begin
j=i+1
	while j lt n-1 do begin
	k=j+1
		while k lt n do begin
 		combos(*,count)=[i,j,k]
		count=count+1
		k=k+1
		endwhile
	j=j+1
	endwhile
i=i+1
endwhile
return
end

