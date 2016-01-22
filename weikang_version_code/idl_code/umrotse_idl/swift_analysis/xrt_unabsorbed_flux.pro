pro xrt_unabsorbed_flux,gamma,a,alo,ahi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi

if n_params() eq 0 then begin
    print,'syntax- xrt_unabsorbed_flux,gamma,a,alo,ahi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi'
    return
endif

if n_elements(enlo) eq 0 then enlo=0.3
if n_elements(enhi) eq 0 then enhi=10.0

flux=xrt_flux_integration(gamma,a,enlo,enhi,/fluxonly)
fluxlo=xrt_flux_integration(gamma,alo,enlo,enhi,/fluxonly)
fluxhi=xrt_flux_integration(gamma,ahi,enlo,enhi,/fluxonly)



return
end
