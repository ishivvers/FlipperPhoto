function logspace,first,last,n

first=float(first)
last=float(last)

xmin=alog(first)/alog(2)
xmax=alog(last)/alog(2)
x=linespace(xmin,xmax,n)

y=2^x
return,y

end
