pro calculate_subimage_tiling,ra,dec,err,tilesize,cal,im_hdr,ratiles,dectiles

if n_params() eq 0 then begin
    print,'syntax- calculate_subimage_tiling,ra,dec,err,cal,im_hdr,ratiles,dectiles'
    return
endif


decliml=dec-err
declimh=dec+err
raliml=ra-(err/cos(dec*0.01745))
ralimh=ra+(err/cos(dec*0.01745))

astr_struct_new,1.85,astr
astr.crval=[double(cal.rac),double(cal.decc)]
rd2xy,[raliml,ralimh],[decliml,declimh],astr,xc,yc
kmap,xc,yc,xx,yy,cal.kx,cal.ky

tscale = tilesize / astr.cdelt[0]

nxtiles = ceil((max(xx)-min(xx))/tscale)
nytiles = ceil((max(yy)-min(yy))/tscale)

;; new tscale
tscale_x = (max(xx)-min(xx))/nxtiles
tscale_y = (max(yy)-min(yy))/nytiles
if (tscale_x gt tscale_y) then tscale = tscale_x else tscale = tscale_y

if nxtiles eq 1 then begin
    xtiles=[(max(xx)+min(xx))/2.]
endif else begin
    xtiles=(findgen(nxtiles)/(nxtiles-1))*(max(xx)-min(xx)-tscale) + min(xx)+tscale/2.
endelse
if nytiles eq 1 then begin
    ytiles=[(max(yy)+min(yy))/2.]
endif else begin
    ytiles=(findgen(nytiles)/(nytiles-1))*(max(yy)-min(yy)-tscale) + min(yy)+tscale/2.
endelse
 
;; and back to ra/dec space
xyad,im_hdr,xtiles,ytiles,ratiles,dectiles ;; really approximate, especially with diagonal
tilesize = tscale * astr.cdelt[0]


return
end
