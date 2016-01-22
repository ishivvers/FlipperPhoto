pro convert2rd,x,y,ra,dec,rac=rac,decc=decc
if n_params() eq 0 then begin
  	print, 'syntax- convert2rd,x,y,ra,dec,rac=rac,decc=decc'
  	return
endif

astr_struct,astr
astr.crval=[double(rac),double(decc)]
xy2rd,x,y,astr,ra,dec
return
end
