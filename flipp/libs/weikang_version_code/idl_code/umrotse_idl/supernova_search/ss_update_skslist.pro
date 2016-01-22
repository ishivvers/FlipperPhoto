pro ss_update_skslist,skydir=skydir,skylist=skylist,workdir=workdir,site=site

;monitor the skydir for new sky images
;update skylist

if n_elements(skydir) ne 1 then skydir='/rotse/data/pipeline/'
if n_elements(skylist) ne 1 then skylist='/rotse/data/sspipeline/skylist'
if n_elements(workdir) ne 1 then workdir='/rotse/data/sspipeline/'

path=skydir+"/prod/"
filenames="*_sk*_cobj.fit"
if n_elements(site) eq 1 then filenames="*_sk*_"+site+"*_cobj.fit"

outfile=skylist
lockfile=outfile+".lock"

markerfile=workdir+"last_update_skylist.txt"
tst=findfile(markerfile,count=count)

if count eq 0 then begin
    
    openw,markerun,markerfile,/get_lun
    close,markerun
    free_lun,markerun
 
    cmd="find "+path+" -name '"+filenames+"' -print "
    spawn,cmd,output

endif else begin

    cmd="find "+path+" -name '"+filenames+"' -newer "+markerfile+" -print "
    spawn,cmd,output

    cmd="touch "+markerfile
    spawn,cmd

endelse


if output[0] ne '' then begin
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
    for i=0,n_elements(output)-1 do begin
        if (not strmatch(output[i],'*_sky*')) then printf,unit,output[i]
    endfor
    close,unit
    free_lun,unit

    close,lockun
    free_lun,lockun
    
    print,outfile+" updated"
endif else begin
    print,outfile+" not updated"

endelse

end
