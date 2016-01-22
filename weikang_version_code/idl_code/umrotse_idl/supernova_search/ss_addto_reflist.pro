pro ss_addto_reflist,output,outfile,replaceold=replaceold

;add output into outfile
;check if any line of output is already in outfile
;replace the old reffile if necessary

if n_params() ne 2 then begin
  print,'syntax- ss_addto_reflist,output,outfile,replaceold=replaceold'
  return
endif

lockfile=outfile+".lock"

if output[0] ne '' then begin

    nout=n_elements(output)
    newout=bytarr(nout)+1b
    
    reffile=strarr(nout)
    refcent=strarr(nout)
    for i=0,nout-1 do begin
        parts=strsplit(output[i],'/',/extract)
        reffile[i]=repstr(parts[n_elements(parts)-1],'.gz','')
        refcent[i]=(strsplit(reffile[i],'_',/extract))[1]
    endfor

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

        goodold=bytarr(nlines)+1b
        for j=0,nlines-1 do begin 
            for i=0,nout-1 do begin
                if strmatch(refcent[i],'fup-*') or strmatch(refcent[i],'nfp-*') then $
                  cent=strmid(refcent[i],7) else cent=strmid(refcent[i],3)
                
                if strmatch(outfilecontent[j],'*'+cent+'*') eq 1 then begin
                    goodold[j]=0b
                    if not keyword_set(replaceold) then newout[i]=0b
                endif
            endfor
        endfor
        
        nold=total(goodold)
        if nold lt nlines and keyword_set(replaceold) then begin
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
            
            openw,unit,outfile,/get_lun
            if nold ge 1 then begin
                outfilecontent=outfilecontent(where(goodold eq 1))
                for j=0,nold-1 do printf,unit,outfilecontent[j]
            endif
            close,unit
            free_lun,unit
            
            close,lockun
            free_lun,lockun
            
            print,outfile+" old reffile removed"
        endif else if nold lt nlines then print," kept old reffile"
        
    endif else begin
        newout[*]=1b
    endelse
        
    if total(newout) gt 0 then begin
        
        reffile=reffile[where(newout eq 1b,nout)]
        refcent=refcent[where(newout eq 1b)]
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
        for i=0,nout-1 do begin
            printf,unit,refcent[i]
            printf,unit,reffile[i]
        endfor
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
