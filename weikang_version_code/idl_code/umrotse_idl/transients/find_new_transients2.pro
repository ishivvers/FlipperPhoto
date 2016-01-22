pro find_new_transients2,mt,st,trans,obj=obj,nconsec=nconsec,appendobs=appendobs,magcut=magcut,conf=conf,output=output,count=count,simtransdir=simtransdir,maxtrans=maxtrans

if n_params() eq 0 then begin
    print,'syntax- find_new_transients2,mt,st,trans,obj=obj,nconsec=nconsec,appendobs=appendobs,magcut=magcut,conf=conf,output=output,count=count,simtransdir=simtransdir,maxtrans=maxtrans'
    return
endif

if n_elements(maxtrans) eq 0 then maxtrans = 5

;; initialize the transients, for an early return
trans=-1
count = 0

if n_elements(conf) gt 0 then begin
    templatedir = conf.templatedir
    if (tag_exist(conf,'MATCHDIR')) then matchdir=conf.matchdir else $
        matchdir=!match_archive_path
endif else begin
    templatedir = '.'
    matchdir=!match_archive_path
endelse



if n_elements(nconsec) eq 0 then nconsec = 4
if n_elements(magcut) eq 0 then magcut = 18.0

if n_elements(obj) eq 0 then begin
    find_new_objects,templatedir,mt,nconsec,obj,appendobs=appendobs,magcut=magcut
endif

nobj=n_elements(obj)
if obj[0] eq -1 then begin
    print,'No new objects found.'
    nobj = 0
    return
endif

allobs = lindgen(mt.nobs)

;; check for saturated objects
satarr=bytarr(nobj)
for i=0l,n_elements(obj)-1 do begin
    k=where(mt.m[allobs,obj[i]] gt 0, nk)
    if (nk eq 0) then satarr[i] = 1 else begin
        test=max(check_flags3('SATURATED',mt.flags[k,obj[i]],type='EFLAGS') gt 0)
        if (test) then satarr[i] = 1
    endelse
endfor

gdobj = where(satarr eq 0,ngd)
if (ngd eq 0) then begin
    print,'All objects failed saturation test.'
    return
endif

obj = obj[gdobj]

;; now we can check if they are real non-detections
fail = 0
load_template_and_trans,templatedir,mt,appendobs,obj,tstr,fail=fail,simtransdir=simtransdir

if (n_elements(tstr.templates) lt 2) then begin
    print,'Not enough template images to compare'
    return
endif

if (fail eq 1) then begin
    print,'Error with load_template_and_trans'
    return
endif

print,'Checking true non-detection...'
;; tstr contains all the obj information
check_true_nondetection,tstr,mt,appendobs,trans,count=count

;; now, do the output if desired
if (keyword_set(output) and (count gt 0)) then begin
    if (count gt maxtrans) then begin
        print,'Too many transients!  Bad images?',count
    endif else begin
        output_transients,tstr,mt,st,appendobs,conf=conf

        ;; mark these transients and save the structure
        inds=tstr.check.objind
        for i=0l,n_elements(inds)-1 do begin
            mt.rflags[0,inds[i]]=set_flags3('CROPJPG',type='RFLAGS',old=mt.rflags[0,inds[i]])
        endfor

        regmatch3_list,mt,st,/archive,archdir=matchdir,/over,/append

    endelse
endif



return
end
