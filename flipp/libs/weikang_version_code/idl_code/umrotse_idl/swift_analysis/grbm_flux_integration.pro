function grbm_flux_integration,alpha,beta,epeak,a,enlo,enhi,fluxonly=fluxonly,e_p=e_p

if n_params() eq 0 then begin
    print,'syntax - [ph,erg] = grbm_flux_integration(alpha,beta,epeak,a,enlo,enhi,fluxonly=fluxonly,e_p=e_p)'
    return,[-1.0,-1.0]
endif

if n_elements(e_p) eq 0 then e_p=100.0   ;; this has nothing to do with e_peak.  great.

;; I think my terminology is all wrong.  I have E_0 (not E_p) and I want E_cut.

;; however, these numbers agree with xspec, so it's correct, just the wrong names

xvals=(findgen(10000)/10000.)*(enhi-enlo)+enlo
yvals=xvals

e0=(alpha-beta)*epeak

lo=where(xvals le e0,nlo)

if (nlo gt 0) then $
  yvals[lo] = a*((xvals[lo]/e_p)^alpha)*exp(-1.0*xvals[lo]/epeak)

;; high end norm
aprime=(a*((e0/e_p)^alpha)*exp(-1.0*e0/epeak))/((e0/e_p)^beta)

hi=where(xvals gt e0,nhi)
if (nhi gt 0) then $
  yvals[hi] = aprime*((xvals[hi]/e_p)^beta)

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
