pro read_usno1m_file,name,uucat

if n_params() eq 0 then begin
    print,'syntax- read_usno1m_file,name,uucat'
    return
endif

readcol,name,grb,cra,raerr,cdec,decerr,nobs,v,bmv,umb,vmr,rmi,e1,e2,e3,e4,e5,format='a,f,f,f,f,i,f,f,f,f,f,f,f,f,f,f,f'

elt=create_struct('ra',0d,'ra_err',0d,'dec',0d,'dec_err',0d, $
                  'nobs',0,'umag',0.,'umag_err',0.,'bmag',0.,'bmag_err',0., $
                  'vmag',0.,'vmag_err',0.,'rmag',0.,'rmag_err',0.,'imag',0.,'imag_err',0.)

;; errors: not sure

uucat=replicate(elt,n_elements(grb))

uucat.ra=cra
uucat.ra_err=raerr
uucat.dec=cdec
uucat.dec_err=decerr
uucat.nobs=nobs

uucat.vmag=v
uucat.vmag_err=abs(e1)

uucat.bmag=uucat.vmag+bmv
uucat.bmag_err = sqrt(e1^2.0 + e2^2.0)

uucat.umag=uucat.bmag+umb
uucat.umag_err = sqrt(uucat.bmag_err^2.0 + e3^2.0)

uucat.rmag=uucat.vmag-vmr
uucat.rmag_err = sqrt(e1^2.0 + e4^2.0)

uucat.imag=uucat.rmag-rmi
uucat.imag_err = sqrt(uucat.rmag_err^2.0 + e5^2.0)

h=where(v gt 50.0,ncnt)
if ncnt gt 0 then begin 
    uucat[h].vmag = -1.0
    uucat[h].vmag_err = -1.0
endif

h=where(umb gt 50.0,ncnt)
if ncnt gt 0 then begin
    uucat[h].umag = -1.0
    uucat[h].umag_err = -1.0
endif

h=where(bmv gt 50.0,ncnt)
if ncnt gt 0 then begin
    uucat[h].bmag = -1.0
    uucat[h].bmag_err = -1.0
endif

h=where(vmr gt 50.0,ncnt)
if ncnt gt 0 then begin
    uucat[h].rmag = -1.0
    uucat[h].rmag_err = -1.0
endif

h=where(rmi gt 50.0,ncnt)
if ncnt gt 0 then begin
    uucat[h].imag = -1.0
    uucat[h].imag_err = -1.0
endif

return
end
