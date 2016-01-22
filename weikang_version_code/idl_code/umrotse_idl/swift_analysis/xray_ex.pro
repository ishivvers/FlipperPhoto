function xray_ex,gamma,e1,e2

if n_params() eq 0 then begin
    print,'syntax- ex=xray_ex(gamma,e1,e2)'
    return,-1
endif

beta=1.-gamma
bp1=double(beta+1.0)
bp2=double(beta+2.0)

ex=((1./bp2)*(e2^bp2-e1^bp2)) / $
  ((1./bp1)*(e2^bp1-e1^bp1))

return,ex









end
