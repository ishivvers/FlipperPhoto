pro ss_update_skylist,skydir=skydir,skylist=skylist,workdir=workdir,site=site,tla=tla

;monitor the skydir for new sky images
;update skylist

if n_elements(skydir) ne 1 then skydir='/rotse/data/pipeline/'
if n_elements(skylist) ne 1 then skylist='/rotse/data/sspipeline/skylist'
if n_elements(workdir) ne 1 then workdir='/rotse/data/sspipeline/'

path=skydir+"/prod/"

ntla=n_elements(tla)
filenames='*_'+tla+'*_3????_cobj.fit'
if n_elements(site) eq 1 then filenames='*_'+tla+'*_'+site+'???_cobj.fit'
    
outfile=skylist
lockfile=outfile+".lock"

markerfile=workdir+"last_update_skylist.txt"
tst=findfile(markerfile,count=count)
    
if count eq 0 then begin
        
    openw,markerun,markerfile,/get_lun
    close,markerun
    free_lun,markerun
        
    output=''
    for indx=0,ntla-1 do begin
        cmd="find "+path+" -name '"+filenames[indx]+"' -print "
        spawn,cmd,output0
        if output0[0] ne '' then output=[output,output0]
    endfor
        
endif else begin
    
    output=''    
    for indx=0,ntla-1 do begin
        cmd="find "+path+" -name '"+filenames[indx]+"' -newer "+markerfile+" -print "
        spawn,cmd,output0
        if output0[0] ne '' then output=[output,output0]
    endfor

    cmd="touch "+markerfile
    spawn,cmd
    
endelse

if n_elements(output) gt 1 then begin
    output=output[1:n_elements(output)-1]
    output=output[sort(output)]
        
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
    for i=0,n_elements(output)-1 do printf,unit,output[i]
    close,unit
    free_lun,unit
    
    close,lockun
    free_lun,lockun
    print,outfile+' is updated'
endif else begin
    print,outfile+' is not update'
endelse

end
