pro rphot_rd2xy,crval,kx,ky,ra,dec,x,y,cobjfn=cobjfn

;; a helper routine to conver RA and DEC values to x,y positions using
;; the given cobj file.

if keyword_set(cobjfn) then begin
    astr_struct_new,1.85,astr
    s = mrdfits(cobjfn,2,/silent)
    astr.crval = [s.crval1, s.crval2]
    rd2xy,ra,dec,astr,xc,yc
    kmap,xc,yc,x,y,s.kx,s.ky
endif else begin
    astr_struct_new,1.85,astr
    astr.crval = crval
    rd2xy,ra,dec,astr,xc,yc
    kmap,xc,yc,x,y,kx,ky
endelse


end
