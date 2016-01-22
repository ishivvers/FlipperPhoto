function xrt_flux_integration,gamma,a,enlo,enhi,fluxonly=fluxonly,nh=nh

if n_params() eq 0 then begin
    print,'syntax- [ph,erg] = xrt_flux_integration(gamma,a,enlo,enhi,fluxonly=fluxonly,nh=nh)'
    return,[-1.0,-1.0]
endif

xvals=(findgen(10000)/10000.)*(enhi-enlo)+enlo
yvals=a*xvals^(-1.0*gamma)

if n_elements(nh) gt 0 then begin
    wabs0,xvals,nh,photar
    yvals=yvals*photar
endif


if not keyword_set(fluxonly) then begin
    int1=int_tabulated(xvals,yvals,/double,/sort)
endif


xvshft=shift(xvals,-1)
xvshft[n_elements(xvshft)-1] = enhi ;; cheat here
test=(xvshft^2.-xvals^2.)/(xvshft-xvals)
int2=int_tabulated(xvals,yvals*test,/double,/sort)

if keyword_set(fluxonly) then begin
    return,0.801096e-9*int2
endif else begin
    return,[int1,0.801096e-9*int2]
endelse

end
