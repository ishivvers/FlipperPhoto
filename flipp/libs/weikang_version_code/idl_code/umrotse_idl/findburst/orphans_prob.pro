pro orphans_prob,efftot,xbins,ybins

; Created:  12-12-00  Bob Kehoe

  seed = 997.0
  for z = 0,29 do begin
     mc = orphans_fakedata('data_sens_summary.dat',seed)
     orphans_effic2d,mc,eff,err,xbins,ybins
     if (z eq 0) then begin
        efftot = eff
     endif else begin
        efftot = efftot + eff
     endelse
  endfor
  efftot = efftot/float(z)

; Make analysis plot

  contour, efftot, xbins, ybins, c_labels=[0,0,0,0], levels=[0.1,0.3,0.75,0.95],$
	xtitle='Power-law Index', ytitle='Peak Magnitude', yrange=[6.0,15.0],$
	c_charsize=1.2,xcharsize=1.2,ycharsize=1.2
  set_plot, 'ps'
  device, file='peak_vs_index_all_fin2.ps'
  contour, efftot, xbins, ybins, c_labels=[0,0,0,0], levels=[0.1,0.3,0.75,0.95],$
	xtitle='Power-law Index', ytitle='Peak Magnitude', yrange=[6.0,15.0],$
	c_charsize=1.2,xcharsize=1.2,ycharsize=1.2
  device, /close
  set_plot, 'X'
  save, efftot,xbins,ybins,file='peak_vs_index_all_fin2.dat'

end
