pro sobjclean,sobjfile

if n_params() eq 0 then begin
  print,'syntax- sobjclean,sobjfile'
  return
endif

st0=mrdfits(sobjfile,0,head0)
st1=mrdfits(sobjfile,1,head1)
;help,st0,st1
print,'original stars number: ',n_elements(st1)


ind=where(st1.FWHM_IMAGE gt 0.5 and st1.FLAGS lt 3)
st1=st1[ind]
print,'after cleaning number: ',n_elements(st1)
writefits,sobjfile,st0,head0
mwrfits,st1,sobjfile,head1


end
