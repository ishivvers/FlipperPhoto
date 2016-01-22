pro count_postage,mat,obj,fitname,indices,matname=matname,path=path,fail=fail

if n_params() eq 0 then begin
    print,'syntax- count_postage,m,obj,fitname,indices,matname=matname,fail=fail,path=path'
    fail = 1
    return
endif

fail = 0

if n_elements(matname) gt 0 then begin
    mat = mrdfits(matname,1)
    if datatype(mat) eq 'INT' then begin
        print,'Error: file not found'
        fail = 1
        return
    endif
endif

name=make_rotse3_name(mat.ra[obj],mat.dec[obj])
fitname = name + '.fit'

if n_elements(path) gt 0 then fitname = path + fitname

fn=findfile(fitname,count=count)

h=where(mat.m[*,obj] gt 0, numobs)

if (count eq 0) then begin
    ;; New file.  Use all appropriate actions
    if (numobs gt 0) then begin
        indices = h
    endif else begin
        print,'No observations of the object!'
        indices = -1
        fail = 1
    endelse
endif else begin
    ;; file is found
    fits_info,fitname,/silent,n_ext=n_ext
    mjds=dblarr(n_ext+1)
    for i=0,n_ext do begin
        hdr=headfits(fitname,exten=i)
        mjds[i] = sxpar(hdr,'MJD')
    endfor
    matjds = mat.jd[h]

    zeropt = min([mjds,matjds])

    lon_mjds = long((mjds-zeropt) * 100000.)
    lon_matjds = long((matjds-zeropt) * 100000.)

    match,lon_mjds,lon_matjds,suba,subb,count=mcount
    if (mcount eq 0) then begin
        indices = h
    endif else begin
        junk=replicate(1,numobs)
        junk[subb] = 0
        k=where(junk eq 1, jcount)
        if (jcount eq 0) then begin
            ;; no new observations
            indices = -1
        endif else indices = h[k]
    endelse
endelse

return
end
