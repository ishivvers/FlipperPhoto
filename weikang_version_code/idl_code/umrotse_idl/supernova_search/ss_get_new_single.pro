function ss_get_new_single,file_list

;;get a single file from file_list

if n_params() ne 1 then begin
  print,'syntax- result=ss_get_new_single(file_list)'
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
    
;read in the first file.
    outfile=all_files[0]
    
    printf,lockun,'writing'
    
;write the rest list back to the file_list file.
    openw,unit,file_list,/get_lun
    if (num_elems gt 1) then begin
        for i=1,num_elems-1 do printf,unit,all_files[i]
    endif
    
    close,unit
    free_lun,unit
    
    close,lockun
    free_lun,lockun
    
endif
return,outfile

end

    
