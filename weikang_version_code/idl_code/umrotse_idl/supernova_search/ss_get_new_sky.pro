function ss_get_new_sky,skylist,workdir=workdir

;get 8 sky files or whatever when the day is over
;get 4 files if the tla is sky

if n_elements(skylist) eq 0 then skylist='/rotse/data/sspipeline/skylist'
if n_elements(workdir) eq 0 then workdir='/rotse/data/sspipeline/'

lockfile=skylist+'.lock'
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
openr,unit,skylist,/get_lun,error=oerr
if (oerr eq 0) then begin
    close,unit
    free_lun,unit
    spawn,'wc '+skylist,wc_string
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
    
;get system time
    now=systime(/julian,/utc)
    
;open a lock file.
    openw,lockun,lockfile,/get_lun,/delete
    printf,lockun,'reading'
    
;read in the contents of skylist
    skyfiles=strarr(num_elems)
    openr,unit,skylist,/get_lun
    readf,unit,skyfiles
    close,unit
    free_lun,unit
    
    search_indx=0
    find=0
    while search_indx lt n_elements(skyfiles) and find eq 0 do begin
        
;find the files for the first field. 
        first_file=skyfiles[search_indx]
        dirparts=strsplit(first_file,'/',/extract)
        fullname=dirparts[n_elements(dirparts)-1]
        nameparts=strsplit(fullname,'_',/extract)
        first_name=nameparts[0]+'_'+nameparts[1]+'_'+strmid(nameparts[2],0,2)
        site=strmid(nameparts[2],0,2)
        first_comp=strmatch(skyfiles,'*'+first_name+'*')
        
        if strmatch(nameparts[1],'*sky*') then req=4 else req=8
        if strmatch(nameparts[1],'ic*') then req=30
        if nameparts[1] eq 'rqc0134+3040' then req=12
;check if all four (eight!) images are there or the day is over
        
        if total(first_comp) eq req then begin ;or total(strmatch(skyfiles[where(first_comp eq 1)],'*_'+site+'0*'+strtrim(string(req),2)+'*')) gt 0 then begin
            find=1
            print,'The set of images is complete.'
        endif else begin
            imf=findfile('/rotse/data/pipeline/image/'+first_name+'*_c.fit*',count=nimf)
            if nimf eq req then begin
                find=1
                print,'The set of images is complete, not all have cobj file.'
            endif else begin
                observatory=mrdfits(workdir+'observatory.fit',1,/silent)
                here=where(observatory.site eq site)
                sunpos,now,sra,sdec
                eq2hor,sra,sdec,now,alt,az,lat=observatory[here].lat,lon=observatory[here].lon,altitude=observatory[here].alt 
                if alt gt 0 then find=1 else begin
                    firstdate=sxpar(headfits(first_file),'mjd')
                    if (now-2400000.5-firstdate) gt 1. then find=1
                endelse
                if find eq 1 then print,'The night is over.'
            endelse
        endelse
        
        search_indx=search_indx+1
    endwhile

    if find eq 0 then begin
        first_comp=bytarr(n_elements(skyfiles))*0
        nfirst=0
        print,'Did not get any file.'
    endif else begin        
        outfile=skyfiles[where(first_comp eq 1,nfirst)]
        outfile=outfile(sort(outfile))
        print,'get sky files:'
        print,outfile
    endelse
    
    printf,lockun,'writing'
    
;write the rest list back to the skylist file.
    openw,unit,skylist,/get_lun
    if (num_elems gt nfirst) then begin
        backfile=skyfiles[where(first_comp eq 0)]
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

    
