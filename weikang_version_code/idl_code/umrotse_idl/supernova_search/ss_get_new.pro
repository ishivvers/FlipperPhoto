function ss_get_new,file_list,n_new,discard_less=discard_less

;;get n_new files from file_list

if n_params() ne 2 then begin
  print,'syntax- result=ss_get_new(file_list,n_new,discard_less=discard_less)'
  return,''
endif


lockfile=file_list+'.lock'
outfile='nothing'

;check lock file.
openr,lockun,lockfile,/get_lun,error=err
while (err eq 0) do begin
    close,lockun
    free_lun,lockun
    wait,5
    openr,lockun,lockfile,/get_lun,error=err
endwhile

num_elems=0
openr,unit,file_list,/get_lun,error=oerr
if (oerr eq 0) then begin
    close,unit
    free_lun,unit
    spawn,'wc '+file_list,wc_string
    num_elems=long(strmid(wc_string(0),0,8))
endif

if (num_elems gt 0) then begin

;check lock file.
    err=0
    openr,lockun,lockfile,/get_lun,error=err
    while (err eq 0) do begin
        print,'Lock file present,waiting.'
        close,lockun
        free_lun,lockun
        wait,5
        openr,lockun,lockfile,/get_lun,error=err
    endwhile
                                
;open a lock file.
    openw,lockun,lockfile,/get_lun,/delete
    printf,lockun,'reading'
    
;read in the contents of file_list
    all_files=strarr(num_elems)
    openr,unit,file_list,/get_lun
    readf,unit,all_files
    close,unit
    free_lun,unit
                                    
    search_indx=0
    find=0
    while search_indx lt n_elements(all_files) and find eq 0 do begin
        
;find the files for the first field.
        first_file=all_files[search_indx]
        dirparts=strsplit(first_file,'/',/extract)
        fullname=dirparts[n_elements(dirparts)-1]
        nameparts=strsplit(fullname,'_',/extract)
        first_name=nameparts[0]+'_'+nameparts[1]+'_'+strmid(nameparts[2],0,2)
        first_comp=strmatch(all_files,'*'+first_name+'*')
        
;check if both images are there
        
        if total(first_comp) eq n_new then find=1
        if total(first_comp) lt n_new and total(first_comp) gt 0 and keyword_set(discard_less) then find=1
        
        search_indx=search_indx+1
    endwhile

    if find eq 0 then begin
        first_comp=bytarr(n_elements(all_files))*0
        nfirst=0
    endif else begin        
        outfile=all_files[where(first_comp eq 1,nfirst)]
        outfile=outfile(sort(outfile))
        if nfirst lt n_new and nfirst gt 0 and keyword_set(discard_less) then outfile='nothing'
    endelse
    
    printf,lockun,'writing'
    
;write the rest list back to the skylist file.
    openw,unit,file_list,/get_lun
    if (num_elems gt nfirst) then begin
        backfile=all_files[where(first_comp eq 0)]
        for i=0,num_elems-nfirst-1 do begin
            printf,unit,backfile[i]
        endfor
    endif

    close,unit
    free_lun,unit
    
    close,lockun
    free_lun,lockun
  
endif
return,outfile

end

    
