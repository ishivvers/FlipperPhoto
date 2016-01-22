pro calculate_xray_jansky2,flux,fluxlo,fluxhi,gamma,gamma_err,e1,e2,fnu,fnulo,fnuhi,ex=ex

if n_params() eq 0 then begin
    print,'syntax- calculate_xray_jansky2,flux,fluxlo,fluxhi,gamma,gamma_err,e1,e2,fnu,fnulo,fnuhi,ex=ex'
    print,'  flux in erg/cm^2/s, gamma positive photon index, '
    print,'  all Energies in keV, Ex to skip <v> calculation'
    print,'   -- stupid error calculations...'
    return
endif

h=4.136d-15 ;; eV-s
jy=1d-23 ;; erg/cm^2/s/Hz

nu1=double(e1)*1000./h
nu2=double(e2)*1000./h
beta = -1.*(double(gamma)-1)
beta_err = double(gamma_err)

if n_elements(ex) gt 0 then begin
    nux = double(Ex)*1000./h
    nux_err = 0.0
endif else begin
    calculate_nux,beta,beta_err,nu1,nu2,nux,nux_err
endelse

print,nux

bp1=beta+1.
temp=bp1/(nu2^bp1 - nu1^bp1)
a = flux*temp
alo=fluxlo*temp
ahi=fluxhi*temp

fnu = (a * nux^beta)/jy
fnulo = (alo * nux^beta)/jy
fnuhi = (ahi * nux^beta)/jy

return
end
