function ss_find_image_cobj, fname, fail=fail

;input image name or cobj name, including the path
;assume image dir is image/, cobj dir is prod/
;output both image file and cobj file

output=strarr(2)
fail=0

if strmatch(fname,'*cobj*') eq 1 then begin

    imname=repstr(fname,'prod/','image/')
    imname=repstr(imname,'_cobj.','_c.')
    cobjfile=findfile(fname,count=ncobj)
    imfile=findfile(imname,count=nim)
    if nim eq 0 then imfile=findfile(imname+'.gz',count=nim)

endif else begin
    if strmatch(fname,'*.gz') eq 1 then fname=strmid(fname,0,strlen(fname)-3)
    cobjname=repstr(fname,'image/','prod/')
    cobjname=repstr(cobjname,'_c.','_cobj.')
    cobjfile=findfile(cobjname,count=ncobj)
    imfile=findfile(fname,count=nim)
    if nim eq 0 then imfile=findfile(fname+'.gz',count=nim)
endelse

if nim eq 1 then output[0]=imfile else begin 
    output[0]='nothing'
    fail=1
endelse
if ncobj eq 1 then output[1]=cobjfile else begin
    output[1]='nothing'
    fail=1
endelse

return,output

end
