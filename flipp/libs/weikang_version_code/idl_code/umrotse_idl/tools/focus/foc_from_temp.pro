pro foc_from_temp,bestfocs,elev,bestfit,elev_tol=elev_tol,noplot=noplot

if n_params() eq 0 then begin
    print,'syntax - foc_from_temp,bestfocs,elev,bestfit,elev_tol=elev_tol,noplot=noplot'
    return
endif

if n_elements(elev_tol) eq 0 then begin
    elev_tol = 2.0
endif

bestfit = create_struct('slope',0.0,'slope_err',0.0,'int',0.0,'int_err',0.0,'elev',0.0)


h = where(bestfocs.elev gt (elev - elev_tol) and $
          bestfocs.elev lt (elev + elev_tol))

bestsub = bestfocs(h)

numplot = n_elements(bestsub)

errs = bestsub.error

line = linfit(bestsub.temp,bestsub.best_focus,sdev=errs)

;now we have a line.  For erin's fxn, go steps...
step = 0.01
range = 1.0
numvals = range/step
normvals = findgen(numvals)*step + line[0] - range/2.
step2=0.00005
range2=0.03
numvals=range2/step2
powvals=findgen(numvals)*step2+line[1]-range2/2.

pow_chisq_conf,bestsub.temp,bestsub.best_focus,bestsub.error, $
  powvals, normvals,chisq_surf,pmin,nmin,powlow,powhigh,normlow,normhigh,/nodisplay

x0 = min(bestsub.temp)
x1 = max(bestsub.temp)
y0= nmin + pmin*x0
y1= nmin + pmin*x1

if not keyword_set(noplot) then begin

    !x.title = 'Temperature'
    !y.title = 'Best Focus (mm)'
    !p.title = 'Elev = '+string(mean(bestsub.elev),'(f5.2)')+' Foc = '+ $
      string(line[0],format='(f6.4)')+' + '+ $
      string(line[1],format='(f7.5)')+'*T'

    
    ploterror,bestsub.temp,bestsub.best_focus,errs,psym=1
    plots,x0,y0
    plots,x1,y1,/continue

    yintstr = string(nmin,format='(f5.3)')+ !tsym.plusminus + $
      string(nmin-normlow[0],format='(f8.5)')
    slopestr = string(pmin,format='(f8.5)')+ !tsym.plusminus + $
      string(pmin-powlow[0],format='(f8.6)')

    legend,[yintstr,slopestr],box=0

    !x.title=''
    !y.title=''
    !p.title=''

endif

bestfit.slope = pmin
bestfit.slope_err = pmin - powlow[0]
bestfit.int = nmin
bestfit.int_err = nmin - normlow[0]
bestfit.elev = mean(bestsub.elev)





return
end
