pro bat_extrapolate_flux,gamma,egamma,normenlo,normenhi,norm,normlo,normhi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi

if n_params() eq 0 then begin
    print,'syntax- bat_extrapolate_flux,gamma,egamma,normenlo,normenhi,norm,normlo,normhi,flux,fluxlo,fluxhi,enlo=enlo,enhi=enhi'
    return
endif

if n_elements(enlo) eq 0 then enlo=0.3
if n_elements(enhi) eq 0 then enhi=10.0


h=4.136d-15 ;; eV-s

;; first calculate the expectation value of E/nu
ex=xray_ex(gamma,normenlo,normenhi)
nux=ex*1000./h
beta=1.-gamma
betap1=beta+1.

;; conversion to get from 10^-12 erg/cm^2/s to microJy at <E_x>
conv=(betap1/(normenhi^betap1-normenlo^betap1))*(1./1.6d3)*(ex^beta/1.509e-3)

;; now we need stuff for the extrapolation
ebeta=1.-egamma
ebetap1=ebeta+1.

a=norm*conv*1d-29/(nux^ebeta)
ahi=normhi*conv*1d-29/(nux^ebeta)
alo=normlo*conv*1d-29/(nux^ebeta)

nu1=enlo*1000./h
nu2=enhi*1000./h

flux=(a/ebetap1)*(nu2^ebetap1-nu1^ebetap1)
fluxlo=(alo/ebetap1)*(nu2^ebetap1-nu1^ebetap1)
fluxhi=(ahi/ebetap1)*(nu2^ebetap1-nu1^ebetap1)



return
end
