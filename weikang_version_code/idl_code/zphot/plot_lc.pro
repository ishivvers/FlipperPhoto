pro plot_lc,x,ex,mag,emag,filters,outname=outname,xtitle=xtitle,ytitle=ytitle,title=title,overplot=overplot,color=color,symsize=symsize,xsize=xsize,ysize=ysize

if n_params() eq 0 then begin
  print,'Syntax- plot_lc,x,ex,mag,emag,filters,outname=outname,xtitle=xtitle,ytitle=ytitle,title=title,overplot=overplot,color=color,symsize=symsize,xsize=xsize,ysize=ysize'
  return
endif

filters=strtrim(filters)
;filter=filters[UNIQ(filters, SORT(filters))]
filter=phot_filter_unique(filters,/reversesort)
print,'filters : ',filter

tfnb=n_elements(filter)

offsetfilters=['U',   'B',  'V', 'R',  'I', 'SDSS-u', 'SDSS-g', 'SDSS-r', 'SDSS-i', 'SDSS-z','CLEAR','UW1','UM2','UW2','','','','','','','']
offsetmags   =[ 3.0,  2.0,  1.0, 0.0, -1.0,  3.0,  2.0,  0.0, -2.0, -3.0, 0.0, 4.0, 5.0, 6.0]
offmag=fltarr(tfnb)
for i=0,tfnb-1 do begin
  ind=where(offsetfilters eq filter[i],nf)
  if nf gt 0 then begin
    offmag[i]=offsetmags[ind[0]] 
  endif else begin
    offmag[i]=0.0
  endelse
  ;print,i,offmag[i]
endfor

colors=[0,2,3,4,6,7, 0,2,3,4,6,7, 0,2,3,4,6,7, 0,2,3,4,6,7, 0,2,3,4,6,7, 0,2,3,4,6,7, 0,2,3,4,6,7]
if keyword_set(color) then colors=intarr(45)+color
usecirclesym
psys=[8,8,8,8,8,8, 4,4,4,4,4,4, 5,5,5,5,5,5, 6,6,6,6,6,6, 7,7,7,7,7,7, 2,2,2,2,2,2, 1,1,1,1,1,1]

if not keyword_set(xtitle) then xtitle='Time (mjd)'
if not keyword_set(ytitle) then ytitle='Mag'
if not keyword_set(title) then title='Target'
if not keyword_set(outname) then outname='tmp.ps'
if not keyword_set(symsize) then symsize=1.0
if not keyword_set(xsize) then xsize=8.0
if not keyword_set(ysize) then ysize=8.0

if not keyword_set (overplot) then begin
  minx=min(x)
  maxx=max(x)
  xrange=maxx-minx
  minx=minx-0.1*xrange
  maxx=maxx+0.3*xrange
  miny=min(mag)
  maxy=max(mag)
  yrange=maxy-miny
  miny=miny-0.3*yrange+min(offmag)
  maxy=maxy+0.3*yrange+max(offmag)
  
  begplot,name=outname,xsize=xsize,ysize=ysize,/color
  ;begplot,name=outname,xsize=8,ysize=6,/color
  
  labelstep=1.0
  plot,[0],[0],/nodata,xrange=[minx,maxx],yrange=[maxy,miny],xstyle=1,ystyle=1,xtitle=xtitle,ytitle=ytitle,title=title
endif

for i=0,tfnb-1 do begin
  ;find good filter data
  ind1=where(filters eq filter[i],nf1)
  if nf1 eq 0 then continue

  if offmag[i] ge 0 then begin
    outtxt=string(filter[i],'+',abs(offmag[i]),format='(a6,a1,f3.1)')
  endif else begin
    outtxt=string(filter[i],'-',abs(offmag[i]),format='(a6,a1,f3.1)')
  endelse
  if not keyword_set (overplot) then xyouts,maxx-0.25*xrange,miny+float((i+1)*labelstep),outtxt,color=colors[i]
  ;find good data points, not upperlimit
  ind2=where(emag[ind1] le 10,nf2)
  oplot,[x[ind1[ind2]]],[mag[ind1[ind2]]+offmag[i]],psy=psys[i],color=colors[i],symsize=symsize
  if nf2 gt 0 then oplotmyerr,[x[ind1[ind2]]],[mag[ind1[ind2]]+offmag[i]],xerr=ex[ind1[ind2]],yerr=emag[ind1[ind2]],color=colors[i]
  ;find upperlimit
  ind3=where(emag[ind1] ge 80,nf3)
  oplot,[x[ind1[ind3]]],[mag[ind1[ind3]]+offmag[i]],psy=psys[i],color=colors[i],symsize=symsize
  if nf3 gt 0 then oplotmyerr,[x[ind1[ind3]]],[mag[ind1[ind3]]+offmag[i]],xerr=ex[ind1[ind3]],yerr=emag[ind1[ind3]],color=colors[i],ul=2,arrullength=0.019
endfor

if not keyword_set (overplot) then begin
  endplot
endif

end
