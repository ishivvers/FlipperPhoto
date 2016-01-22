pro ss_update_candref,newcoadd,refdir=refdir,reflist=reflist

if n_params() eq 0 then begin
    print,'syntax - ss_update_candref,newcoadd,refdir=refdir,reflist=reflist'
    return
endif

if n_elements(refdir) eq 0 then refdir='/rotse/data/sspipeline/reference/'
if n_elements(reflist) eq 0 then reflist='/rotse/data/sspipeline/reflist'

goodmlim=18.0
goodpossig=0.3
goodncoadd=8
goodfwhm=3.

if newcoadd[0] ne 'nothing' then begin
    newcoaddfiles=ss_find_image_cobj(newcoadd[0])
        
    dirparts=strsplit(newcoaddfiles[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    
    if strmatch(parts[1],'*sky*') then goodncoadd=4

    newstat=mrdfits(newcoaddfiles[1],2,/silent)
    newpossig=newstat.pos_sigma
    newmlim=newstat.m_lim
    newncoadd=newstat.ncoadd
    newfwhm=newstat.fwhm
    
    move=0b
    if newmlim ge goodmlim and newpossig le goodpossig and newncoadd ge goodncoadd and newfwhm le goodfwhm then begin
        
        ;is there an existing candidate?
        candfile=findfile(refdir+'/prod/*'+strmid(parts[1],3)+'*cobj*',count=ncand)
        nolder=0
        if ncand ge 1 then begin
                                ;compare the new coadd with the existing candidate
                                ;a new candidate should be better than old ones
            
            newmjd=newstat.mjd
            
            mjds=dblarr(ncand)
            possigs=fltarr(ncand)
            mlims=fltarr(ncand)
            fwhms=fltarr(ncand)
            for i=0,ncand-1 do begin
                candstat=mrdfits(candfile[i],2,/silent)
                mjds[i]=candstat.mjd
                possigs[i]=candstat.pos_sigma
                mlims[i]=candstat.m_lim
                fwhms[i]=candstat.fwhm
            endfor
            mjds=long((mjds-54102)/7)
            newmjd=long((newmjd-54102)/7)
            
            older=where(mjds le newmjd,nolder)
            if nolder ge 1 then begin
                pts=(newmlim-mlims[older])/3.0+(possigs[older]-newpossig)/0.3+(fwhms[older]-newfwhm)/15.0
                if min(pts) gt 0 then begin
                                ;the newcoadd is better than all old
                    move=1b
                                ;if there is a old file for the same week,delete
                    samew=where(mjds eq newmjd,nsame)
                    if nsame eq 1 then begin
                        cdirparts=strsplit(candfile[samew],'/',/extract)
                        cparts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
                        cbasename = parts[0] + '_' + parts[1]
                        spawn,'rm -f '+refdir+'/*/'+cbasename+'*'
                    endif
                endif else begin
                    print,newcoadd+' is not better than existing candidate'
                endelse
            endif  
        endif
        if nolder lt 1 then begin
            
                                ;is there a reference?
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
            
            skyind=where(strmatch(skyrefs,'*'+parts[1]+'*'),nmatch)
            if nmatch ge 1 then begin
                if skyrefs[skyind[0]+1] ne 'nothing' then begin
                                ;compare the new coadd with the existing reference
                                ;a candidate should be better than the old reference
                    reffiles=ss_find_image_cobj(skyrefs[skyind[0]+1],fail=fail)
                    if fail then reffiles=ss_find_image_cobj(refdir+'/image/'+skyrefs[skyind[0]+1],fail=fail)
                    refstat=mrdfits(reffiles[1],2,/silent)
                    pts=(newmlim-refstat.m_lim)/3.0+(refstat.pos_sigma-newpossig)/0.3+(refstat.fwhm-newfwhm)/15.0
                    if pts gt 0 then begin
                        move=1b
                    endif else begin
                        print,newcoadd+' is not better than the current reference'
                    endelse
                    
                endif else begin
                                ;put in the new coadd, note that it can't be used until 3 weeks later
                    move=1b
                endelse
            endif else print,'cannot find a  matching field in ',reflist
        endif
        
    endif else begin
        print,newcoadd+' is not good enough to be a reference.'
        
    endelse
    
    if move eq 1b then begin
        spawn,'cp '+newcoaddfiles[0]+' '+refdir+'/image/'
        allprod=repstr(newcoaddfiles[1],'cobj','*')
        spawn,'cp '+allprod+' '+refdir+'/prod/'
    endif

endif else begin
    print,'nothing new found in the coaddall_list'
endelse
    
end
