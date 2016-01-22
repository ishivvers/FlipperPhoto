pro plot_ipnarc,arc,color=color
;overplots the ipnarc on the image

if n_params() eq 0 then begin
print,'-syntax plot_ipnarc,arc,color=color'
return
endif

num=n_elements(arc.x)
xmax=max(arc.x)
xmin=min(arc.x)
ymin=min(arc.y)
ymax=max(arc.y)

derx=shift(arc.x,1)-arc.x
dery=shift(arc.y,1)-arc.y
derx(0)=derx(1)
dery(0)=dery(1)

w1=where(derx eq 0,wif1)
w2=where(dery eq 0,wif2)
w3=where(derx ne 0 and dery ne 0,wif3)

a=findgen(num)
b=findgen(num)

if wif1 ne 0 then begin
b(w1)=0.0
a(w1)=1.0
endif

if wif2 ne 0 then begin
b(w2)=1.0
a(w2)=0.0
endif

if wif3 ne 0 then begin
b(w3)=sqrt(1.0/(1.0+(dery(w3)/derx(w3))^2))
a(w3)=-b(w3)*dery(w3)/derx(w3)
endif

c=sqrt(a^2+b^2)
w4=where(c gt 0)
a(w4)=a(w4)*arc.width*.5/c(w4)
b(w4)=b(w4)*arc.width*.5/c(w4)

oplot,arc.x+a,arc.y+b,color=color
oplot,arc.x-a,arc.y-b,color=color

ma=max(arc.y,m)
arrow,arc(m).x+a(m),arc(m).y+b(m),arc(m).x-a(m),arc(m).y-b(m),/data,hsize=1e-6,color=color
ma=min(arc.y,m)
arrow,arc(m).x+a(m),arc(m).y+b(m),arc(m).x-a(m),arc(m).y-b(m),/data,hsize=1e-6,color=color
return
end



