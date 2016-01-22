pro calculate_nux,beta,sigbeta,nu1,nu2,nux,signux

if n_params() eq 0 then begin
    print,'syntax- calculate_nux,beta,sigbeta,nu1,nu2,nux,signux'
    print,'  approximates the error dumbly'
    return
endif

;; not upgraded for beta = -1!!!
if (beta gt (-1-1e-5) and beta lt (-1+1e-5)) then begin
    print,'will not work with this beta yet'
    return
endif

betas=[beta-sigbeta,beta,beta+sigbeta]

nuxes=fltarr(n_elements(betas))

for i=0l,n_elements(nuxes)-1 do begin
    bp2 = double(betas[i]+2.)
    bp1 = double(betas[i]+1.)
    nuxes[i] = ((1./bp2) * (nu2^bp2 - nu1^bp2)) / $
      ((1./bp1) * (nu2^bp1 - nu1^bp1))
endfor

nux = nuxes[1]
signux = abs((nuxes[2]-nuxes[0])/2.)



return
end
