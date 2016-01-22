pro idl_counterpart_plot2, output, lower=lower
;+
; NAME:
;       IDL_COUNTERPART_PLOT
; PURPOSE:
;	Make a plot with counterpart detections 
;
; CALLING SEQUENCE:
;       idl_counterpart_plot
;
; INPUTS:
;       output=output device
;
; OUTPUTS:
;
;
; INPUT KEYWORD PARAMETERS:
;
; PROCEDURE:
;	Plots data points from counterpart detections
;
; REVISION HISTORY:
;	Tim McKay	UM	1/24/97
;-

  On_error,2                    ;Return to caller
  
  if N_params() ne 1 then begin
      print,'Syntax - idl_counterpart_plot, output'
      return
  endif
  
  grbdate = 23.40759
  setupplot
                                ; ROTSE bare CCD calibrated to V
; date
  cVd = [23.407851, 23.408142, 23.408435, 23.409413, 23.410851, 23.412764, 23.414677]
; magnitude
  cVm = [    11.70,      8.86,     9.97,   11.86,     13.07,     13.81,     14.28]
; magnitude error
  cVe = [      0.07,       0.01,       0.02,  0.13,      0.04,       0.07,       0.12]
  
;ROTSE non-detections (limits)
;date
;cVLd = [ 23.315903, 23.43548589, 23.45975979, 23.46458894, 23.46941798, 23.47424713]
  cVLd = [ 23.43548589, 23.45975979, 23.46458894, 23.46941798, 23.47424713]
; limiting magnitude
;cVLl = [ 14.8, 15.6, 15.6, 15.6, 15.6 ]
  cVLl = [ 15.6, 15.6, 15.6, 15.6 ,15.6 ]
  cVLd = [ 23.43548589, 23.46941757]
  cVLexptime = [200,400]
; limiting magnitude
  cVLl = [ 15.6, 16.1 ]
  
  !x.style=1
  !y.style=1
  !x.title='log(Time from Burst in Hours)'
  !y.title='Burst Magnitude'
  !p.title='GRB counterparts and ROTSE-III sensitivity'
  
  thickness = 1
  
  if output eq 'eps' then BEGIN
      begplot, name='counterpart_plot.eps', /ENCAPSUL, /landscape,/color
      thickness = 3
      linthick=10
  ENDIF
  IF output EQ 'ps' THEN BEGIN 
      begplot, name='counterpart_plot.ps', /landscape,/color
      thickness = 3
      linthick=10
  ENDIF 
  IF output EQ 'x' OR output EQ 'z' THEN set_plot, output

  !x.thick = thickness
  !y.thick = thickness
  !p.thick = thickness
  !p.charthick = thickness

  if not keyword_set(lower) then begin
      lower=0.0
  endif

  gbi=findfile("grb_idl.dat",count=ct)
  if (ct eq 0) then begin
      gbi=findfile("/products/idltools/umrotse_idl/tools/grb_plots/grb_idl.dat",count=ct)
      if (ct eq 0) then begin
          print,'Cannot find grb_idl.dat'
          if (output eq 'ps') then endplot
          return
      endif
  endif
  print,'Using: ',gbi
  
  readcol, gbi, logt, mag, symbol,format='f,f,i'


  index=where(symbol eq 5)

  plot, alog10(logt(index)), mag(index)+lower, psym=2, yrange=[26,8],xrange=[-3.0,2.0],thick=thickness

  oplot, alog10(logt(index)), mag(index)+lower, thick=linthick,color=!yellow
  oplot, alog10(logt(index)), mag(index)+lower, psym=2



  index=where(symbol eq 9) 
  ;;plot, alog10(logt(index)), mag(index)+lower, psym=5, yrange=[26,8],xrange=[-3.0,2.0],thick=thickness

  oplot,alog10(logt(index)), mag(index)+lower, thick=linthick,color=!red
  oplot, alog10(logt(index)), mag(index)+lower, psym=5,thick=thickness


  index=where(symbol eq 2)

  oplot, alog10(logt(index)), mag(index)+lower, thick=linthick,color=!blue
  oplot, alog10(logt(index)), mag(index)+lower, psym=7

  index=where(symbol eq 3)

  oplot, alog10(logt(index)), mag(index)+lower, thick=linthick,color=!blue
  oplot, alog10(logt(index)), mag(index)+lower, psym=4

  index=where(symbol eq 6)
  
  oplot, alog10(logt(index)), mag(index)+lower, thick=linthick,color=!cyan
  oplot, alog10(logt(index)), mag(index)+lower, psym=6

  plotsym,0,/fill
  index=where(symbol eq 1)
  oplot, alog10(logt(index)), mag(index)+lower, thick=linthick,color=!green
  oplot, alog10(logt(index)), mag(index)+lower,psym=8

  plotsym,0   ;; psym=8 is now an open circle
  index=where(symbol eq 8)
  oplot, alog10(logt(index)), mag(index)+lower, thick=linthick,color=!magenta
  oplot, alog10(logt(index)), mag(index)+lower,psym=8


  xyouts, -2.5, 20.9, 'GRB041006 R Band', /data
  xyouts, -2.5, 21.4, 'GRB040924 R Band', /data
  xyouts, -2.5, 21.9, 'GRB990123 V Band', /data
  xyouts, -2.5, 22.4, 'GRB030723 R Band', /data
  xyouts, -2.5, 22.9, 'GRB030418 R Band', /data
  xyouts, -2.5, 23.4, 'GRB030329 R Band', /data
  xyouts, -2.5, 23.9, 'GRB021211 R Band', /data
  xyouts, -2.5, 24.4, 'GRB021004 R Band', /data
  plotsym,0,/fill
  oplot, [-2.6], [20.7], psym=8
  plotsym,0
  oplot, [-2.6], [21.2], psym=8
  oplot, [-2.6], [21.7], psym=1
  oplot, [-2.6], [22.2], psym=6
  oplot, [-2.6], [22.7], psym=2 
  oplot, [-2.6], [23.2], psym=7 
  oplot, [-2.6], [23.7], psym=5
  oplot, [-2.6], [24.2], psym=4
    
  oplot,alog10((cVd-grbdate)*24),cVm+lower,thick=linthick,color=!magenta
  oploterr,alog10((cVd-grbdate)*24),cVm+lower,cVe,1
  ;;oplot,alog10((cVld-grbdate)*24),cVLl+lower,psym=1
  ;;arrow,alog10((cVld-grbdate)*24),cVLl+lower,alog10((cVld-grbdate)*24),cVLl+1.0+lower,/data
  
;  legend,['GRB990123 ROTSE V'],psym=[1],/right
  
;  oplot,[-3.00,-2.38],[13,13],linestyle=1,thick=thickness
;  oplot,[-2.37,0],[13.0,16.0],linestyle=1,thick=thickness
;  oplot,[0,3],[16.0,16.0],linestyle=1,thick=thickness
  oplot,[-3,-1.55],[17,17],linestyle=2,thick=thickness
  oplot,[-1.54,-0],[17,19.5],linestyle=2,thick=thickness
  oplot,[-0,3],[19.5,19.5],linestyle=2,thick=thickness
; oplot,[-3,-0.62],[18,20.5],linestyle=3
; oplot,[-0.62,3.0],[20.5,20.5],linestyle=3
;  xyouts, -2.8, 12.5, 'ROTSE I', /data
  xyouts, -2.8, 16.5, 'ROTSE III', /data
; xyouts, -0.6, 19.9, 'ROTSE III', /data
  xyouts, -2.3, 25.2, '15 seconds', /data
  xyouts, -0.55, 25.2, '15 minutes', /data
  xyouts, 1.2, 25.2, '1 day', /data
  
  ;;xyouts, 1.2, 25.2, '1 day', /data
  
  !x.title=''
  !y.title=''
  !p.title=''
  !x.thick=1
  !y.thick=1
  
  IF output EQ 'ps' OR output EQ 'eps' THEN endplot

      
  set_plot, 'x'

end
