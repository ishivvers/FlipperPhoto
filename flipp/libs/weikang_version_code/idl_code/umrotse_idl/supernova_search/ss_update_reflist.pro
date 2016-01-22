pro ss_update_reflist,reflist=reflist,refdir=refdir

if n_elements(reflist) eq 0 then begin
    print,'syntax - ss_update_reflist,reflist=reflist,refdir=refdir'
    return
endif

;for now, this should be run every week on Monday

if n_elements(reflist) ne 1 then reflist='/rotse/data/sspipeline/reflist'
if n_elements(refdir) ne 1 then refdir='/rotse/data/sspipeline/reference'

;read in the reflist
spawn,'wc '+reflist,wc_string
nlines=long(strmid(wc_string(0),0,8))
skyrefs=strarr(nlines)
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
;read reflist
openr,unit,reflist,/get_lun
readf,unit,skyrefs
close,unit
free_lun,unit
;close lock file
close,lockun
free_lun,lockun
        
;for every field, check if there is a newer reference
for i=0,nlines-2,2 do begin
    candfiles=findfile(refdir+'/prod/*'+strmid(skyrefs[i],3)+'*cobj*',count=ncand)
    if ncand ge 1 then begin
        now=systime(/julian,/utc)-2400000.5
        mjds=dblarr(ncand)
        for j=0,ncand-1 do begin
            mjds[j]=(mrdfits(candfiles[j],2,/silent)).mjd
        endfor
        sortmjd=sort(mjds)
        candfiles=candfiles(sortmjd)
        mjds=mjds(sortmjd)

        currentref=ss_find_image_cobj(refdir+'/image/'+skyrefs[i+1],fail=fail)
        if (not fail) then begin
            currentrefmjd=(mrdfits(currentref[1],2,/silent)).mjd
        endif else begin
            currentrefmjd=0
        endelse
        
        new=where(mjds lt now-21 and mjds gt currentrefmjd,nnew)
        if nnew ge 1 then begin
            newref=ss_find_image_cobj(candfiles[new[nnew-1]])
            dirparts=strsplit(newref[0],'/',/extract)
            newrefname=dirparts[n_elements(dirparts)-1]
            skyrefs[i+1]=newrefname
             
            old=where(mjds lt mjds[new[nnew-1]],nold)
            if nold ge 1 then begin
                for j=0,nold-1 do begin
                    dirparts=strsplit(candfiles[old[j]],'/',/extract)
                    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
                    basename = parts[0] + '_' + parts[1]
    
                    spawn,'rm -f '+refdir+'/*/'+basename+'*'
                endfor
            endif
        endif else begin
            print,'no new reference found for field: '+skyrefs[i]
        endelse
    endif else begin
        print,'no reference candidate found for field: '+skyrefs[i]
    endelse
endfor

;write back the reflist
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
printf,lockun,'writing'
;read reflist
openw,unit,reflist,/get_lun
for i=0,n_elements(skyrefs)-1 do printf,unit,skyrefs[i]
close,unit
free_lun,unit
;close lock file
close,lockun
free_lun,lockun

end        
        
            
