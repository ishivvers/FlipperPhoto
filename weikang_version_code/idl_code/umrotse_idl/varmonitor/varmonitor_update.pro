pro varmonitor_update,basedir

if n_params() eq 0 then begin
    print,'syntax- varmonitor_update,basedir'
    return
endif

subdirs = ['3a','3b','3c','3d']

roots=['']
for i=0l,n_elements(subdirs)-1 do begin
    foundnew = 0
    markerfile = basedir + "/" + subdirs[i] + "/last_update.txt"
    cmd = "stat -c %Y " + markerfile
    spawn,cmd,output
    last_update_time = long(output[0])

    files=findfile(basedir+'/'+subdirs[i]+'/vm_*.fit',count=ct)

    for j=0l,ct-1 do begin
        cmd = "stat -c %Y " + files[j]
        spawn,cmd,output
        if (long(output[0]) gt last_update_time) then begin
            dirparts=strsplit(files[j],'/',/extract)
            parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
            roots=[roots,parts[1]]
            foundnew = 1
        endif
    endfor

    if (foundnew) then begin
        cmd = "touch " + markerfile
        spawn,cmd
    endif
endfor

if n_elements(roots) eq 1 then begin
    print,'No updates to be made'
    return
endif

;; now extract the roots to be updated

roots=roots[1:n_elements(roots)-1]

sroots=roots[sort(roots)]
uroots=sroots[uniq(sroots)]

;; now we have the unique roots.  Do the updating
for i=0l,n_elements(uroots)-1 do begin
    vfiles=findfile(basedir+'/3?/vm_'+uroots[i]+'*.fit',count=ct)

    if (ct eq 0) then begin
        print,'No files found?  Should not be possible.'
    endif else begin
        ;; we'll read in each of them, and remake the merged one every time.
        ;; In the future, this might be streamlined to append/rebuild the
        ;; merged one, but there will always be the sorting issue...
        varstr = mrdfits(vfiles[0],1)
        for j=1l,ct-1 do begin
            svarstr=mrdfits(vfiles[j],1)
            old_n = n_elements(varstr.jd)
            new_n = old_n + n_elements(svarstr.jd)
            varstr=varmonitor_make_struct(new_n,old=varstr)
            varstr.jd[old_n:new_n-1] = svarstr.jd
            varstr.iobj[old_n:new_n-1] = svarstr.iobj
            varstr.imagename[old_n:new_n-1] = svarstr.imagename
            varstr.m[old_n:new_n-1] = svarstr.m
            varstr.merr[old_n:new_n-1] = svarstr.merr
            varstr.flags[old_n:new_n-1] = svarstr.flags
            varstr.rflags[old_n:new_n-1] = svarstr.rflags
            varstr.msys[old_n:new_n-1] = svarstr.msys
            varstr.m_lim[old_n:new_n-1] = svarstr.m_lim           
        endfor

        ;; if we had a merger, sort it...
        if (ct gt 1) then begin
            st=sort(varstr.jd)
            varstr.jd = varstr.jd[st]
            varstr.imagename = varstr.imagename[st]
            varstr.iobj = varstr.iobj[st]
            varstr.m = varstr.m[st]
            varstr.merr = varstr.merr[st]
            varstr.flags = varstr.flags[st]
            varstr.rflags = varstr.rflags[st]
            varstr.msys = varstr.msys[st]
            varstr.m_lim = varstr.m_lim[st]
        endif

        ;; write it out
        outfname = basedir + '/' + 'vm_' + uroots[i] + '_merge.fit'
        mwrfits,varstr,outfname,/create

        ;; finally, we do the output
        varmonitor_make_pngs,basedir,uroots[i],varstr        

    endelse
endfor




return
end
