pro focus_fixed_elevs,best,elev_arr,mean_slope,mean_int,elev_tol=elev_tol

if n_params() eq 0 then begin
    print,'syntax- focus_fixed_elevs,best,elev_arr,mean_slope,mean_int,elev_tol=elev_tol'
    return
endif


if n_elements(elev_tol) eq 0 then begin
    elev_tol = 2.0
endif

elt = create_struct('slope',0.0,'slope_err',0.0,'int',0.0,'int_err',0.0,'elev',0.0)

bestfits = replicate(elt,n_elements(elev_arr))


for i=0,n_elements(elev_arr)-1 do begin
    foc_from_temp,best,elev_arr[i],bestfit,elev_tol=elev_tol,/noplot

    bestfits[i].slope = bestfit.slope
    bestfits[i].slope_err = bestfit.slope_err
    bestfits[i].int = bestfit.int
    bestfits[i].int_err = bestfit.int_err
    bestfits[i].elev = bestfit.elev
    
endfor


!p.multi=[0,0,2]
mean_slope = total(bestfits.slope / (bestfits.slope_err^2)) / total(1./bestfits.slope_err^2)

ploterror,bestfits.elev,bestfits.slope,bestfits.slope_err,psym=1, $
  xtitle='Elevation',ytitle='Slope',title='Slope of focus(temp) as f(elev)'

line1=linfit(bestfits.elev,bestfits.slope,sdev=bestfits.slope_err)
x0=min(bestfits.elev)
x1=max(bestfits.elev)
y0=line1[0] + line1[1]*x0
y1=line1[0] + line1[1]*x1
plots,x0,y0
plots,x1,y1,/continue


leg=string(line1[0],format='(f8.5)')+' + '+$
  string(line1[1],format='(f10.7)')+' * Elev'

legend,[leg],box=0

mean_int = total(bestfits.int / (bestfits.int_err^2)) / total(1./bestfits.int_err^2)

ploterror,bestfits.elev,bestfits.int,bestfits.int_err,psym=1, $
  xtitle='Elevation',ytitle='Intercept',title='Intercept focus(temp) as f(elev)'


line2=linfit(bestfits.elev,bestfits.int,sdev=bestfits.int_err)
x0=min(bestfits.elev)
x1=max(bestfits.elev)
y0=line2[0] + line2[1]*x0
y1=line2[0] + line2[1]*x1
plots,x0,y0
plots,x1,y1,/continue

leg=string(line2[0],format='(f8.5)')+' + '+$
  string(line2[1],format='(f10.7)')+' * Elev'

legend,[leg],box=0

!p.multi = 0


print,'Constant = ' + string(line2[0],format='(f8.5)')
print,'Elev. Const = ' + string(line2[1],format='(f10.7)')
print,'Temp. Const = ' + string(line1[0],format='(f8.5)')
print,'Temp/Elev Const = ' + string(line1[1],format='(f10.7)')

return
end
