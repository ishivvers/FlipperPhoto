pro read_ipnarc,file,arc,rac,decc,kx,ky,width
;reads the ascii file that has the IPN arc ra and dec
;as they are reported from INP email (whoever that is)
;exports a 'arc' structure that can be plotted
;with plot_ipnarc,arc
;make sure that you comment out all text (from IPN) 
;from the ascii file
;rac,decc is the center of the image 
;kx,ky is the transformation found by matching the 
;image to catalog
;width is the width of the arc in degrees (also in IPN email)

if n_params() eq 0 then begin
print,'-syntax read_ipnarc,file,arc,rac,decc,kx,ky,width'
return
endif
readcol,file,ra,dec,dist
num=n_elements(ra)
a={ra:0.0,dec:0.0,x:0.0,y:0.0,dist:0.0,width:0.0}
arc=replicate(a,num)
arc.ra=ra
arc.dec=dec
arc.dist=dist

convert2xy,ra,dec,xx,yy,rac=rac,decc=decc
kmap,xx,yy,x,y,kx,ky
arc.x=x
arc.y=y
arc.width=width/.003888	;in pixels

return
end


