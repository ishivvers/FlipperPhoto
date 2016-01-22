pro convert2xy,ra,dec,xout,yout,rac=rac,decc=decc
if n_params() eq 0 then begin
  	print, 'syntax- convert2xy,ra,dec,xout,yout,rac=rac,decc=decc'
  	return
endif

if n_elements(rac) eq 0 then begin
	rac=(max(ra)+min(ra))/2.0
	decc=(max(dec)+min(dec))/2.0
endif

astr_struct,astr
astr.crval=[double(rac),double(decc)]
rd2xy,ra,dec,astr,xout,yout
return
end
