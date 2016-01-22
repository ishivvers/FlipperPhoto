function ss_find_image_sobj, fname, fail=fail

;input image name or sobj name, including the path
;assume image dir is image/, sobj dir is prod/
;output both image file and sobj file

output=strarr(2)
fail=0

if strmatch(fname,'*sobj*') eq 1 then begin

    imname=repstr(fname,'prod/','image/')
    imname=repstr(imname,'_sobj.','_c.')
    cobjfile=findfile(fname,count=ncobj)
    imfile=findfile(imname,count=nim)
    if nim eq 0 then imfile=findfile(imname+'.gz',count=nim)

endif else begin

    if strmatch(fname,'*.gz') eq 1 then fname=strmid(fname,0,strlen(fname)-3)
    cobjname=repstr(fname,'image/','prod/')
    cobjname=repstr(cobjname,'_c.','_sobj.')
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
