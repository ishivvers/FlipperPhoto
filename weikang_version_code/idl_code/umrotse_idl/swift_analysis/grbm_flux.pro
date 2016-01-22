pro grbm_flux,alpha,beta,epeak,a,alo,ahi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi,e_p=e_p

if n_params() eq 0 then begin
    print,'syntax- grbm_flux,alpha,beta,epeak,a,alo,ahi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi,e_p=e_p'
    return
endif

if n_elements(enlo) eq 0 then enlo=15.0
if n_elements(enhi) eq 0 then enhi=150.0

flux=grbm_flux_integration(alpha,beta,epeak,a,enlo,enhi,/fluxonly,e_p=e_p)
fluxlo=grbm_flux_integration(alpha,beta,epeak,alo,enlo,enhi,/fluxonly,e_p=e_p)
fluxhi=grbm_flux_integration(alpha,beta,epeak,ahi,enlo,enhi,/fluxonly,e_p=e_p)


return
end
