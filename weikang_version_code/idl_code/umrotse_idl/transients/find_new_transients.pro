pro find_new_transients,m,st,trans,obj=obj,nconsec=nconsec,appendobs=appendobs,magcut=magcut,conf=conf,output=output,flagusno=flagusno,count=count,simtransdir=simtransdir,maxtrans=maxtrans

if n_params() eq 0 then begin
    print,'syntax- find_new_transients,m,st,trans,obj=obj,nconsec=nconsec,appendobs=appendobs,magcut=magcut,conf=conf,output=output,flagusno=flagusno,count=count,simtransdir=simtransdir'
    return
endif

if (n_elements(maxtrans) eq 0) then maxtrans = 5

;; initialize the transients, for a return
trans=-1
count=0


if n_elements(conf) gt 0 then begin
    templatedir = conf.templatedir
endif else begin
;;    templatedir = '/rotse/data/pipeline/templates'
    templatedir = '.'
endelse

if (n_elements(nconsec)) eq 0 then begin
    nconsec = 4
endif

if n_elements(magcut) eq 0 then begin
    ;; want to update
    magcut = 17.5  
endif


if keyword_set(flagusno) then begin
    flag_usno_objects,m
endif


if n_elements(obj) eq 0 then begin
    limit_consec,m,nconsec,obj,appendobs=appendobs,magcut=magcut
endif

nobj=n_elements(obj)
if obj[0] eq -1 then nobj = 0

if (nobj gt 0) then begin

    pix=0.0009d

    h=where((check_flags3('USNOCAT',m.rflags[0,obj],type='RFLAGS') eq 0) $
            and m.ngood(obj) ge 2,ucount)
    if (ucount gt 0) then begin 
        gdobj = obj[h]
        
        ;; check for saturation and bad images
        satarr = bytarr(n_elements(gdobj))
        for i=0l,n_elements(gdobj)-1 do begin
            k=where(m.m[*,gdobj[i]] gt 0,nk)
            if (nk eq 0) then satarr[i] = 1 else begin
                test=max(check_flags3('SATURATED',m.flags[k,gdobj[i]],type='EFLAGS') gt 0)
                if (test) then satarr[i] = 1
;;                test2=where(st[k].pos_sigma gt 0.3,bcnt)
;;                if (bcnt gt 0) then satarr[i] = 1
            endelse
        endfor
        stillgd=where(satarr eq 0,nstillgd)
        if (nstillgd eq 0) then begin
            trans = -1
            count = 0
        endif else begin
            gdobj = gdobj[stillgd]

            ;; check for focus mergers
            check_focus_merger,m,5*pix,2*pix,gdobj,missing1

            if (missing1[0] ne -1) then begin
                ;; check if they were real non-detections

                fail = 0
                load_template_and_trans,templatedir,m,appendobs,missing1,tstr,fail=fail,simtransdir=simtransdir
                print,missing1


                if (fail eq 1) then begin
                    print,'error with load_template_and_trans'
                    trans = -1
                    count = 0
                endif else begin
                    ;; this is the real output
                    print,'Checking true non-detection'
                    check_true_nondetection,tstr,m,appendobs,trans,count=count
                endelse                
            endif else begin
                trans = -1
                count = 0
            endelse
        endelse
    endif else begin
        print,'No good objects'
        trans = -1
        count = 0
    endelse
endif else begin
    print,'No consec'
    trans = -1
    count = 0
endelse

;; now, output them if desired
if (keyword_set(output) and (count gt 0)) then begin
    ;; we should output some transients
    if (count gt maxtrans) then begin
        print,'Too many transients!  Bad images???'
    endif else begin
        output_transients,tstr,m,st,appendobs,conf=conf
    endelse

endif



return
end
