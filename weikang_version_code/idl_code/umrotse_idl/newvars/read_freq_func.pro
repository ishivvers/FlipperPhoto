pro read_freq_func,fname,px,py,pdy,x,y


filename=fname+'.txt'
openr,lun,filename,/get_lun
n=0


;; Read in data for unphased light curve

readf,lun,n
rx=fltarr(n)
ry=fltarr(n)
rdy=fltarr(n)

xlo = 0.0
xhi = 1.0
ylo = 0.0
yhi = 1.0

readf,lun,xlo,xhi,ylo,yhi
tmp=fltarr(3)
for i=0,n-1 do begin
    readf,lun,tmp
    rx[i] = tmp[0]
    ry[i] = tmp[1]
    rdy[i] = tmp[2]
endfor

;; Read in data for phased light curve

readf,lun,n
px=fltarr(n)
py=fltarr(n)
pdy=fltarr(n)
readf,lun,xlo,xhi,ylo,yhi
readf,lun,f,knot
tmp=fltarr(3)
for i=0,n-1 do begin
    readf,lun,tmp
    px[i]=tmp[0]
    py[i]=tmp[1]
    pdy[i]=tmp[2]
endfor

;; Read in function data
readf,lun,n
x=fltarr(n)
y=fltarr(n)
tmp=fltarr(2)
for i=0,n-1 do begin
    readf,lun,tmp
    x[i]=tmp[0]
    y[i]=tmp[1]
endfor


free_lun,lun


;x=x+px[0]-rx[0]

return
end
