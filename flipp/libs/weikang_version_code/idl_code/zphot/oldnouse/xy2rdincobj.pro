pro xy2rdincobj,filename,x,y,ra,dec,verbose=verbose

 if N_params() eq 0 then begin
	print,'Syntax: xy2radecincobj,filename,x,y,ra,dec'
 	return
 endif

struct=mrdfits(filename,2,head,/silent)
st=mrdfits(filename,1,head,/silent)

wcs_matrix_struct,struct.pixelscale,astr
astr.crval=[double(struct.astr_crval1),double(struct.astr_crval2)]

kmap,x,y,cand_x,cand_y,struct.kxi,struct.kyi
xy2rd,cand_x,cand_y,astr,cand_ra,cand_dec
ra=cand_ra
dec=cand_dec

 if keyword_set(verbose) then begin
    print,x,y,ra,dec
 endif
end
