pro plot_compare,files

nf=n_elements(files)
if nf le 1 then begin
  print,'Number of files less than 1, doing nothing'
  return
endif
zphot_dat_res_format,files[0],outst0

;;First of all, get the minimum of X, Y and get range
tzero=min(outst0.TIME)
tmax=max(outst0.TIME)
magmin=min(outst0.mag)
magmax=max(outst0.mag)
for i=1,nf-1 do begin
  zphot_dat_res_format,files[i],outsttmp
  tzero=min([tzero,min(outsttmp.TIME)])
  tmax=max([tmax,max(outsttmp.TIME)])
  magmin=min([magmin,min(outsttmp.mag)])
  magmax=max([magmax,max(outsttmp.mag)])
endfor
;print,'tzero:',tzero

minx=0d0
maxx=tmax-tzero
xrange=maxx
minx=-0.1*xrange
maxx=maxx+0.2*xrange
miny=magmin
maxy=magmax
yrange=maxy-miny
miny=miny-0.3*yrange-0.3
maxy=maxy+0.3*yrange+0.3


colors=[2,3,4,6,7,0,2,3,4,6,7,0]
symsizes=[1.2,1.0,0.8,0.6,0.4,0.2,0.5,0.3,0.1]
outname='lightcurve_compare_tmp.ps'
xtitle='Time (mjd)'
ytitle='Mag'
title='Compare'
begplot,name=outname,xsize=8,ysize=8,/color

plot,[0],[0],/nodata,xrange=[minx,maxx],yrange=[maxy,miny],xstyle=1,ystyle=1,xtitle=xtitle,ytitle=ytitle,title=title

plot_lc,outst0.TIME-tzero,outst0.ETIME,outst0.MAG,outst0.EMAG,outst0.FILTER,/overplot,color=colors[0],symsize=symsizes[0]
for i=1,nf-1 do begin
  zphot_dat_res_format,files[i],outsttmp
  plot_lc,outsttmp.TIME-tzero,outsttmp.ETIME,outsttmp.MAG,outsttmp.EMAG,outsttmp.FILTER,/overplot,color=colors[i],symsize=symsizes[i]
endfor
endplot


end
