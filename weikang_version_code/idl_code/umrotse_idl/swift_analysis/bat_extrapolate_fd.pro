pro bat_extrapolate_fd,gamma,egamma,normenlo,normenhi,norm,normlo,normhi,fd,fdlo,fdhi,en=en

if n_params() eq 0 then begin
    print,'syntax- bat_extrapolate_fd,gamma,egamma,normenlo,normenhi,norm,normlo,normhi,fd,fdlo,fdhi,en=en'
    return
endif

if n_elements(en) eq 0 then en=70.0

h=4.136d-15 ;; eV-s

;; first calculate the expectation value of E/nu
ex=xray_ex(gamma,normenlo,normenhi)
nux=ex*1000./h
beta=1.-gamma
betap1=beta+1.

;; conversion to get from 10^-12 erg/cm^2/s to microJy at <E_x>
conv=(betap1/(normenhi^betap1-normenlo^betap1))*(1./1.6d3)*(ex^beta/1.509e-3)

a=norm*conv*1d-6
ahi=normhi*conv*1d-6
alo=normlo*conv*1d-6

nu1=en*1000./h

fd=a*(nu1/nux)^(beta)
fdlo=alo*(nu1/nux)^(beta)
fdhi=ahi*(nu1/nux)^(beta)


return
end
