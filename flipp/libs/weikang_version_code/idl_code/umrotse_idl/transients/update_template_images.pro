pro update_template_images,templatedir,newimages

if n_params() eq 0 then begin
    print,'syntax- update_template_images,templatedir,newimages'
    return
endif

;; assumes that all the newimages are from the same tlaroot on the same day

nnew=n_elements(newimages)
if (nnew eq 0) then begin
    print,'no new images to check'
    return
endif

mlims = fltarr(nnew)
possigs = fltarr(nnew)
ncobjnames=strarr(nnew)
nimnames=strarr(nnew)


for i=0l,nnew-1 do begin
    fail = 0
    ;; find the cobj
    ncobjnames[i]=find_rotse3_cobj(newimages[i],fail=fail)
    if (fail eq 0) then begin
        ;; make sure the image is there!
        nimnames[i]=find_rotse3_image(newimages[i],fail=fail)
        if (fail eq 0) then begin
            cal=mrdfits(ncobjnames[i],2)
            mlims[i] = cal.m_lim
            possigs[i] = cal.pos_sigma
        endif
    endif
endfor

;; now we can get the best limiting magnitude & corresponding pos_sigma
maxlim = max(mlims,msub)
maxlimpos = possigs[msub]

;;dirparts=strsplit(nimnames[msub],'/',/extract)
;;parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
;;ndate=parts[0]

;; next, we need to look at the limiting magnitudes of the templates
find_template_images,templatedir,newimages[msub],timnames,tcobjnames,count=tct

new_to_copy = -1
old_to_move = -1

if (tct lt 2) then begin
    ;; we want to copy the images over, but not move to old
    new_to_copy = msub
    old_to_move = -1
endif else begin
    tmlims=fltarr(tct)+100.0
    tpossigs=fltarr(tct)

    for i=0l,tct-1 do begin
        cal=mrdfits(tcobjnames[i],2)
        tmlims[i]=cal.m_lim
        tpossigs[i] = cal.pos_sigma
    endfor

    ;; compare to the worse/t image
    minlim=min(tmlims,mnsub)
    minlimpos=tpossigs[mnsub]

;;    dirparts=strsplit(timnames[mnsub],'/',/extract)
;;    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
;;    tdate=parts[0]

    if ((maxlim gt minlim) and (maxlimpos lt minlimpos)) then begin
        ;; we want to replace
        new_to_copy = msub[0]
        old_to_move = mnsub[0]
    endif
endelse

if (new_to_copy ne -1) then print,'Update templates...'

if (old_to_move ne -1) then begin
    cmd='mv '+timnames[old_to_move]+' '+templatedir+'/image/old/'
    spawn,cmd

    cmd='mv '+tcobjnames[old_to_move]+' '+templatedir+'/prod/old/'
    spawn,cmd
endif

if (new_to_copy ne -1) then begin
    cmd='cp '+nimnames[new_to_copy]+' '+templatedir+'/image/'
    spawn,cmd

    cmd='cp '+ncobjnames[new_to_copy]+' '+templatedir+'/prod/'
    spawn,cmd
endif


return
end
