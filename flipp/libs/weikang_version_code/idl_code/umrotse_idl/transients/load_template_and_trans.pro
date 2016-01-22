pro load_template_and_trans,templatedir,mt,appendobs,checkobj,tstr,fail=fail,simtransdir=simtransdir

if n_params() lt 5 then begin
    print,'syntax- load_template_and_trans,templatedir,mt,appendobs,checkobj,tstr,fail=fail,simtransdir=simtransdir'
    return
endif

fail = 0

if ((n_elements(checkobj) eq 0) or (checkobj[0] eq -1)) then begin
    print,'no objects to check'
    fail = 1
    return
endif

;; load the templates into a templates structure
checkname=mt.imagename[appendobs[0]]
find_template_images,templatedir,checkname,imnames,cobjnames,count=tct

if (tct eq 0) then begin
    print,'error: no templates available'
    fail = 1
    return
endif

im=readfits(imnames[0])
cobj=mrdfits(cobjnames[0],1)
cal=mrdfits(cobjnames[0],2)

ctemp=create_struct(name='ctemp',cobj[0])
temp={ctemp}
temp.ra = -1.0
temp.dec = -100.0

elt=create_struct('name',imnames[0], $
                  'im',im, $
                  'c',replicate(temp,20000), $
                  'nobj',0l, $
                  'cal',cal)
templates=replicate(elt,tct)

templates[0].c[0:n_elements(cobj)-1] = cobj
templates[0].nobj = n_elements(cobj)

for i=1l,tct-1 do begin
    templates[i].name = imnames[i]
    templates[i].im = readfits(imnames[i])
    cobj=mrdfits(cobjnames[i],1)

    tc=templates[i].c
    struct_assign,cobj,tc
    templates[i].c = tc

    templates[i].nobj = n_elements(cobj)
    caltemp=mrdfits(cobjnames[i],2)
    struct_assign,caltemp,cal
    templates[i].cal = cal
endfor

;; now, look for the brightest and dimmest obs of each candidate

elt=create_struct('objind',0l, $
                  'obsind',lonarr(2), $
                  'iname',strarr(2), $
                  'cname',strarr(2), $
                  'sfwhm',fltarr(2), $
                  'mfwhm',fltarr(2))


checkstr = replicate(elt,n_elements(checkobj))

if (n_elements(simtransdir) ne 0) then begin
    cdir = simtransdir + '/prod/'
    idir = simtransdir + '/image/'
endif

for i=0l,n_elements(checkobj)-1 do begin
    obj=checkobj[i]

    checkstr[i].objind = obj

    h=where(mt.m[*,obj] gt 0, hcnt)
    minmag=min(mt.m[h,obj],subs)

    checkstr[i].obsind[0] = h[subs]
    f = 0
    temp = find_rotse3_image(mt.imagename[h[subs]],path=idir,fail=f)
    if (f) then fail = 1
    checkstr[i].iname[0] = temp
    temp = find_rotse3_cobj(mt.imagename[h[subs]],path=cdir,fail=f)
    if (f) then fail = 1
    checkstr[i].cname[0] = temp
    
    maxmag = max(mt.m[h,obj], subs)

    checkstr[i].obsind[1] = h[subs]

    temp = find_rotse3_image(mt.imagename[h[subs]],path=idir,fail=f)
    if (f) then fail = 1
    checkstr[i].iname[1] = temp
    temp = find_rotse3_cobj(mt.imagename[h[subs]],path=cdir,fail=f)
    if (f) then fail = 1
    checkstr[i].cname[1] = temp

endfor

;; and put it together

tstr=create_struct('templates',templates, $
                   'check',checkstr)

return
end
