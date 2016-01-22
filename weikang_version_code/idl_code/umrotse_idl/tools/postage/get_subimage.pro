pro get_subimage,imname,ra,dec,rac,decc,kx,ky,subim,boxwidth=boxwidth,pathname=pathname,fail=fail

if n_params() eq 0 then begin
    print,'syntax- get_subimage,imname,ra,dec,rac,decc,kx,ky,subim,boxwidth=boxwidth,pathname=pathname,fail=fail'
    return
endif

if n_elements(boxwidth) eq 0 then begin
    boxwidth = 30
endif

fail = 0

;;First, we need the xrange and yrange

astr_struct_new,1.85,astr
astr.crval=[double(rac),double(decc)]
rd2xy,ra,dec,astr,xc,yc
kmap,xc,yc,xa,ya,kx,ky

x_obj = xa[0]
y_obj = ya[0]

xmin = round(x_obj - boxwidth/2)
xmax = xmin + boxwidth-1
ymin = round(y_obj - boxwidth/2)
ymax = ymin + boxwidth-1

;;Next, we need the image
info=str_sep(imname," ")
name=info[0]
info=str_sep(name,".fit")
name=info[0]
narr=str_sep(name,"/")
name=narr[n_elements(narr)-1]
narr=str_sep(name,"_")

imagename = narr[0]+'_'+narr[1]+'_'+narr[2]+'_c.fit'

if n_elements(pathname) ne 0 then begin
    imagename = pathname + '/' + imagename
endif else begin
    imagename = '/rotse4/data1/rotse3/'+narr[0]+'/image/'+imagename
endelse

fn=findfile(imagename,count=count)
if (count eq 1) then begin
    print,'Reading image file: '+imagename
endif else begin
    print,'Failed to find image file: '+imagename
    fail = 1
    return
endelse

im=readfits(imagename,hdr)

extract_subregion,im,xmin,xmax,ymin,ymax,subim


return
end
