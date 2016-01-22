function ss_find_ref_files,newfile,reflist=reflist,refdir=refdir,fail=fail

;find reference image of the field
;from reflist

if n_params() eq 0 or n_elements(reflist) eq 0 then begin
  print,'syntax- result=ss_find_ref_files(newfile,reflist=reflist,refdir=refdir,fail=fail)'
  return,''
endif

fail=0

dirparts=strsplit(newfile,'/',/extract)
fullname=dirparts[n_elements(dirparts)-1]
nameparts=strsplit(fullname,'_',/extract)
if strmatch(nameparts[1],'fup-*') eq 1 or strmatch(nameparts[1],'nfp-*') eq 1 then nameparts[1]=strmid(nameparts[1],4)

test=findfile(reflist,count=ntest)
if ntest gt 0 then begin
    spawn,'wc '+reflist,wc_string
    num_elems=long(strmid(wc_string(0),0,8))
endif else begin
    print,'no reflist exist:',reflist
    num_elems=0
endelse

if num_elems ge 2 then begin
    all=strarr(num_elems)
    lockfile=reflist+".lock"
;check lock file.
    openr,lockun,lockfile,/get_lun,error=err
    while (err eq 0) do begin
        close,lockun
        free_lun,lockun
        wait,3
        openr,lockun,lockfile,/get_lun,error=err
    endwhile
    
;open a lock file.
    openw,lockun,lockfile,/get_lun,/delete
    printf,lockun,'reading'
    
    openr,unit,reflist,/get_lun
    readf,unit,all
    close,unit
    free_lun,unit
    
    close,lockun
    free_lun,lockun
    
    indfield=lindgen(num_elems/2)*2
    indref=lindgen(num_elems/2)*2+1
    
    match=where(strmatch(all[indfield],'*'+strmid(nameparts[1],3)+'*') eq 1,nm)
    
    if nm eq 1 then begin
        
        reffile=all[indref[match]]
        if keyword_set(refdir) then reffile=refdir+'/image/'+reffile
        reffiles=ss_find_image_cobj(reffile[0],fail=fail)
    endif else begin
        
        fail=1
        reffiles=['nothing','nothing']
    endelse
endif else begin
    fail=1
    reffiles=['nothing','nothing']
endelse  

return,reffiles

end
    
