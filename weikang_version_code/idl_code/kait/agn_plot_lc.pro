pro agn_plot_lc,datafilename

if n_params() eq 0 then begin
  print,'syntax - agn_plot_lc,datafilename'
  return
endif

alldatapath='/kait/web/agn/lightcurve_all/'

objname=datafilename
strreplace,objname,'.dat',''
outnameps=alldatapath+objname+'_kait.ps'
outnamepng=alldatapath+objname+'_kait.png'

alldatafile=alldatapath+datafilename
readcol,alldatafile,jd,mag1,mag1err,mag,emag,mag2err,format='d,f,f,f,f,f'

x=jd-double(2450000)

;prepare before plot
minx=min(x)
maxx=max(x)
xrange=maxx-minx
minx=minx-0.1*xrange
maxx=maxx+0.1*xrange
miny=min(mag)
maxy=max(mag)
yrange=maxy-miny
miny=miny-0.2*yrange
maxy=maxy+0.2*yrange

;plot
usecirclesym
begplot,name=outnameps,xsize=8,ysize=6,/color
plot,[0],[0],/nodata,xrange=[minx,maxx],yrange=[maxy,miny],xstyle=1,ystyle=1,xtitle='JD-2450000 (day)',ytitle='Mag'

oplot,x,mag,psy=8
oplotmyerr,x,mag,xerr=0,yerr=emag
xyouts,minx+0.05*xrange,miny+0.15*yrange,objname,charsize=2.0
;;plot last point
lastind=n_elements(x)-1
oplot,[x[lastind]],[mag[lastind]],psy=8,color=2
oplotmyerr,[x[lastind]],[mag[lastind]],xerr=0,yerr=[emag[lastind]],color=2
usecirclesym,/open
oplot,[x[lastind]],[mag[lastind]],psy=8,color=2,symsize=2.5,thick=2
;;find last point date
daycnv,jd[lastind],yr, mn, day, hr
newday=float(day)+hr/24.0
lastdate=string(yr,'-',mn,'-',newday,format='(i4,a1,i2,a1,f05.2)')
xyouts,maxx-0.53*xrange,maxy-0.10*yrange,'Last obs: '+lastdate,color=2,charsize=1.5

endplot

cmd = "convert -density 70 " + outnameps + " " +outnamepng
spawn,cmd

end
