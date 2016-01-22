pro hist2d,x,y,hist,xrange,yrange,nxbins,nybins
;+
; NAME:
;    HIST2D
;
; PURPOSE:
;    like the IDL built in function hist_2d
;    but better since it can accept floats
;    output histogram is a longarray(nxbins,nybins)
;    uses only the relevent data in range
;
;  Dave Johnston
;-
if n_params() eq 0 then begin
	print,'-syntax hist2d,x,y,hist,xrange,yrange,nxbins,nybins'
	return
endif

xrange=float(xrange)
yrange=float(yrange)

xmin=xrange(0)
xmax=xrange(1)
ymin=yrange(0)
ymax=yrange(1)

w=where(x gt xmin and x lt xmax and y gt ymin and y lt ymax,count)
if count eq 0 then begin
	hist=-1
	return
endif

xind=floor((x(w)-xmin)*(nxbins/(xmax-xmin)))
yind=floor((y(w)-ymin)*(nybins/(ymax-ymin)))

ind=xind+nxbins*yind
h=histogram(ind,min=0l,max=long(nxbins*nybins)-1)

hist=lonarr(nxbins,nybins)
hist(*)=h

return
end



