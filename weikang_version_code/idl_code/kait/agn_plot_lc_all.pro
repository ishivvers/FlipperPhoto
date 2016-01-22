pro agn_plot_lc_all

;if n_params() eq 0 then begin
;  print,'syntax - agn_plot_lc,datafilename'
;  return
;endif

newdatapath='/kait/web/agn/lightcurve_new/'
;newdatapath='/kait/web/agn/lightcurve_all/'

cd,newdatapath

f=findfile('J*.dat')
for i=0,n_elements(f)-1 do begin
  print,i,' working on:',f[i]
  agn_plot_lc,f[i]
endfor

end
