pro plot_sn,t0=t0

f=findfile('lightcurve_*.dat')
for i=0,n_elements(f)-1 do begin
  outpsname=f[i]
  strreplace,outpsname,'.dat','.ps'
  objectname=f[i]
  strreplace,objectname,'lightcurve_',''
  strreplace,objectname,'.dat',''

  zphot_dat_res_format,f[i],outst
  tzero=min(outst.TIME)
  if keyword_set(t0) then tzero=t0
  plot_lc,outst.TIME-tzero,outst.ETIME,outst.MAG,outst.EMAG,outst.FILTER,title=objectname,outname=outpsname
endfor

end
