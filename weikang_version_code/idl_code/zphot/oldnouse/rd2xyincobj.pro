pro rd2xyincobj,cobjfilename,ra,dec,x,y,verbose=verbose

if N_params() eq 0 then begin
        print,'Syntax: rd2xyincobj,cobjfilename,ra,dec,x,y,verbose=verbose'
	return
endif

st1=mrdfits(cobjfilename,1,head,/silent)
st2=mrdfits(cobjfilename,2,head,/silent)

wcs_matrix_struct,st2.pixscale,astr
astr.crval = [st2.astr_crval1,st2.astr_crval2]

rd2xy,ra,dec,astr,xc,yc
kmap,xc,yc,x,y,st2.kx,st2.ky

if keyword_set(verbose) then begin
  print,ra,dec,x,y
endif

end
