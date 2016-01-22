pro surf,im,sub,num,file=file,print=print
if n_params() eq 0 then begin
 print,'syntax- surf,im,sub,num,file=file,print=print'
 return
endif
oldwin=!d.window
if n_elements(num) eq 0 then num=1
cursor,x1,y1,/data,/down
print,x1,y1
cursor,x2,y2,/data,/down
print,x2,y2
im2=im((x1<x2):(x2>x1),(y1<y2):(y2>y1))
sub=im2
window,num
surface,im2,/lego
wset,oldwin
return
end
