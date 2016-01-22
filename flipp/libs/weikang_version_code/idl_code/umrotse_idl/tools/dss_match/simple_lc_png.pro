pro simple_lc_png,pngname,times,mags,magerrs,dim=dim,xtitle=xtitle,xrange=xrange,colorindex1=colorindex1,colorindex2=colorindex2

if n_params() eq 0 then begin
    print,'syntax- simple_lc_png,pngname,times,mags,magerrs,dim=dim,xtitle=xtitle,xrange=xrange,colorindex1=colorindex1,colorindex2=colorindex2'
    return
endif

if n_elements(dim) ne 2 then dim=[600,300]
if n_elements(xtitle) eq 0 then xtitle='Seconds from Burst'

set_plot,'z'
device,set_resolution=dim

temperr=magerrs
h=where(temperr lt 0,nt)
if (nt gt 0) then temperr[h] = 0.2

usecolor=0
if ((n_elements(colorindex1) gt 0) or (n_elements(colorindex2) gt 0)) then $
  usecolor=1

if (usecolor) then begin
    loadct,2
    tvlct,r,g,b,/get
endif


yrange=[max(mags + temperr+0.1),min(mags - temperr-0.1)]

if n_elements(xrange) eq 2 then xstyle=1 else xstyle=0

plot,times,mags,yrange=yrange,/nodata,/ystyle,xtitle=xtitle,ytitle='Magnitude',charsize=1.0,xrange=xrange,xstyle=xstyle

;; plot the points
in=where(magerrs gt 0,nin)
if (nin gt 0) then begin
    oploterror,times[in],mags[in],magerrs[in],psym=1
endif

;; and plot the limits
notin=where(magerrs lt 0,nnot)
if (nnot gt 0) then begin
    arrow,times[notin],mags[notin],times[notin],mags[notin]+0.2,/data,/solid
endif

;; and plot the colors...
if (usecolor and (n_elements(colorindex1) gt 0)) then begin
    if (colorindex1[0] ge 0) then begin
        oploterror,times[colorindex1],mags[colorindex1],magerrs[colorindex1],psym=1,color=80,errcolor=80
    endif
endif

if (usecolor and (n_elements(colorindex2) gt 0)) then begin
    if (colorindex2[0] ge 0) then begin
        oploterror,times[colorindex2],mags[colorindex2],magerrs[colorindex2],psym=1,color=200,errcolor=200
    endif
endif

if (usecolor) then begin
    write_png,pngname,tvrd(),r,g,b
endif else begin
    write_png,pngname,tvrd()
endelse

set_plot,'x'

return
end
