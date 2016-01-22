function find_rotse3_files,root=root,ra=ra,dec=dec,pair=pair,filter=filter, $
                           tel=tel, min_mlim=min_mlim, $
                           max_pos_sigma=max_pos_sigma,max_count=max_count, $
                           mjd_start=mjd_start,mjd_end=mjd_end,count=count

if n_elements(root) eq 0 and n_elements(ra) eq 0 and n_elements(dec) eq 0 then begin

    print,'syntax- cobjs = find_rotse3_files(root=root,ra=ra,dec=dec,pair=pair,filter=filter,'
    print,'                                  tel=tel,min_mlim=min_mlim,max_pos_sigma=max_pos_sigma,'
    print,'                                  max_count=max_count,mjd_start=mjd_start,'
    print,'                                  mjd_end=mjd_end,count=count)'
    print,'   if /filter is set, then min_mlim and max_pos_sigma are set to default filter values (17.0/0.3)'
    count = 0
    return,['']
endif


;; right now ignores coadds

file_dir = '/products/database/rotse_files'
radius = 1.9/2.

if keyword_set(filter) then begin
    if n_elements(min_mlim) eq 0 then min_mlim = 17.0
    if n_elements(max_pos_sigma) eq 0 then max_pos_sigma = 0.3
endif

if n_elements(min_mlim) eq 0 then min_mlim = 0.0
if n_elements(max_pos_sigma) eq 0 then max_pos_sigma = 100.0
if n_elements(mjd_start) eq 0 then mjd_start = 0.0
if n_elements(mjd_end) eq 0 then mjd_end = 1e10
if n_elements(max_count) eq 0 then max_count = 1e10

use_radec = 0
if n_elements(root) eq 0 then begin
    if n_elements(ra) eq 0 and n_elements(dec) eq 0 then begin
        print,'Must specify root or ra/dec'
        count = 0
        return,['']
    endif

    use_radec = 1;
    ;; we need to find which tlaroots might fit the bill
    datfiles = findfile(file_dir ,count=ct)
    if (ct eq 0) then begin
        print,'Error!  No datfiles found?'
        count = 0
        return,['']
    endif

    for i=0l,n_elements(datfiles)-1 do begin
        datfile = file_dir + '/' + datfiles[i]
        if (strpos(datfiles[i],'.dat') gt 0) then begin
            readcol,datfile,rac,decc,format='d,d',numline=1,/silent

            if ((ra gt (rac - radius / cos(dec*0.01745))) and $
                (ra lt (rac + radius / cos(dec*0.01745))) and $
                (dec gt (decc - radius)) and $
                (dec lt (decc + radius))) then begin
                add_arrval,datfile,use_datfiles
            endif
        endif
    endfor
    

endif else begin
    ;; make sure we have the root recorded

    datfile = findfile(file_dir + '/' + root + '.dat',count=ct)
    if (ct eq 1) then add_arrval,datfile,use_datfiles

endelse

if n_elements(use_datfiles) eq 0 then begin
    print,'No datfiles found that matches requested root or position'
    count = 0
    return,['']
endif


cobjs = ['']
dirs = ['']
mjds = [0d]
mlims = [0.0]
psigs = [0.0]

for i=0l,n_elements(use_datfiles)-1 do begin
    readcol,use_datfiles[i],fname,fdir,mjd,mlim,psig,ral,rah,decl,dech, $
      format='a,a,d,f,f,f,f,f,f',/silent

    useit_arr = bytarr(n_elements(fname)) + 1
    
    if (use_radec) then begin
        test=where(ra lt ral or ra gt rah or dec lt decl or dec gt dech,ntest)
        if (ntest gt 0) then useit_arr[test] = 0
    endif

    ;; coadd/tel filtering
    for j=0l,n_elements(useit_arr)-1 do begin
        parts=strsplit(fname[j],'_',/extract)
        if (n_elements(tel) ne 0) then begin
            if (strpos(parts[2],tel) ne 0) then useit_arr[j] = 0
        endif
        if (strpos(parts[2],'-') ne -1) then useit_arr[j] = 0
    endfor

    test=where(mlim lt min_mlim or psig gt max_pos_sigma or mjd lt mjd_start or mjd gt mjd_end,ntest)
    if (ntest gt 0) then useit_arr[test] = 0

    use=where(useit_arr eq 1,nuse)
    if (nuse gt 0) then begin
        cobjs=[cobjs,fname[use]]
        dirs=[dirs,fdir[use]]
        mjds=[mjds,mjd[use]]
        mlims=[mlims,mlim[use]]
        psigs=[psigs,psig[use]]
    endif
endfor

if n_elements(cobjs) eq 1 then begin
    print, 'No cobjs found'
    count = 0
    return,['']
endif

cobjs = cobjs[1:n_elements(cobjs)-1]
dirs = dirs[1:n_elements(dirs)-1]
mjds = mjds[1:n_elements(mjds)-1]
mlims = mlims[1:n_elements(mlims)-1]
psigs = psigs[1:n_elements(psigs)-1]


st=sort(cobjs)
cobjs=cobjs[st]
dirs=dirs[st]
mjds=mjds[st]
mlims=mlims[st]
psigs=psigs[st]


if keyword_set(pair) then begin
    p_arr=bytarr(n_elements(cobjs))
    mlimp=fltarr(n_elements(cobjs))
    for i=0l,n_elements(cobjs)-2 do begin
        parts=strsplit(cobjs[i],'_',/extract)
        framenum=long(strmid(parts[2],2,3))
        if ((framenum mod 2) eq 1) then begin
            pairname=parts[0]+'_'+parts[1]+'_'+strmid(parts[2],0,2) + $
              string(framenum+1,format='(i3.3)')+'_'+parts[3]
            if (cobjs[i+1] eq pairname) then begin
                p_arr[i] = 1
                p_arr[i+1] = 1
                mlimp[i] = (mlims[i]+mlims[i+1])/2.
                mlimp[i+1] = mlimp[i]
            endif
        endif
    endfor
        
    ps=where(p_arr eq 1,np)
    if (np eq 0) then begin
        count = 0
        return,['']
    endif

    if (np gt max_count) then begin
        st=reverse(sort(mlimp[ps]))
        newcobjs=cobjs[ps[st[0:max_count-1]]]
        newmjds=mjds[ps[st[0:max_count-1]]]
        newdirs=dirs[ps[st[0:max_count-1]]]
        count=n_elements(newcobjs)
    endif else if np gt 0 then begin
        newcobjs=cobjs[ps]
        newmjds=mjds[ps]
        newdirs=dirs[ps]
        count = n_elements(newcobjs)
    endif else begin       
        count = 0
        return,['']
    endelse

    st=sort(newmjds)
    fullcobjs = newdirs[st] + '/prod/' + newcobjs[st]

endif else begin
    ;; not for pairs

    nuse=n_elements(newcobjs)
    if (nuse gt max_count) then begin
        st=reverse(sort(mlims))
        newcobjs=cobjs[st[0:max_count-1]]
        newdirs=dirs[st[0:max_count-1]]
        newmjds=mjds[st[0:max_count-1]]
        count=n_elements(newcobjs)
    endif else begin
        newcobjs=cobjs
        newmjds=mjds
        newdirs=dirs
        count=n_elements(newcobjs)
    endelse

    st=sort(newmjds)
    fullcobjs = newdirs[st] + '/prod/'+newcobjs[st]

endelse

return,fullcobjs

end


