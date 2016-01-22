pro ss_addto_list,output,outfile

;add output into outfile
;check if any line of output is already in outfile
;only add new lines

if n_params() ne 2 then begin
  print,'syntax- addto_list,output,outfile'
  return
endif

lockfile=outfile+".lock"

if output[0] ne '' then begin

    nout=n_elements(output)
    newout=bytarr(nout)

    tst=findfile(outfile,count=count)
    nlines=0
    if count gt 0 then begin 
        spawn,'wc '+outfile,wc_string
        nlines=long(strmid(wc_string(0),0,8))
    endif
    if nlines ge 1 then begin
        outfilecontent=strarr(nlines)

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
        openr,unit,outfile,/get_lun
        readf,unit,outfilecontent
        close,unit
        free_lun,unit
        ;close lock file
        close,lockun
        free_lun,lockun
        
        for i=0,nout-1 do begin
            if total(strmatch(outfilecontent,output[i]+'*')) eq 0 then newout[i]=1b
        endfor
        
    endif else begin
        newout[*]=1b
    endelse
        
    if total(newout) gt 0 then begin
        
        output=output[where(newout eq 1b,nout)]
;check lock file.
        openr,lockun,lockfile,/get_lun,error=err
        while (err eq 0) do begin
            close,lockun
            free_lun,lockun
            wait,5
            openr,lockun,lockfile,/get_lun,error=err
        endwhile
        
;open a lock file.
        openw,lockun,lockfile,/get_lun,/delete
        printf,lockun,'writing'
        
        openw,unit,outfile,/get_lun,/append
        for i=0,nout-1 do printf,unit,output[i]
        close,unit
        free_lun,unit
        
        close,lockun
        free_lun,lockun
        
        print,outfile+" updated"
    endif else begin
        print,outfile+" not updated (nothing new)"
    endelse
endif else begin
    print,outfile+" not updated (nothing to add)"
    
endelse

end
