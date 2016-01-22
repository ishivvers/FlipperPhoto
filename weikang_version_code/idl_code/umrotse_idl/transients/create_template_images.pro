pro create_template_images,templatedir,matchlist

if n_params() eq 0 then begin
    print,'syntax- create_template_images,templatedir,matchlist'
    return
endif

nmat=n_elements(matchlist)

for i=0l,nmat-1 do begin
    st=mrdfits(matchlist[i],2)
    nst=n_elements(st)

    ims=lonarr(2)-1
    count = 0
    m_lims = st.m_lim
    ;; make sure we have the image (no reason we shouldn't, except on 3c right
    ;; now due to the silliness
    while ((ims[0] eq -1) and (count lt 50)) do begin
        maxlim=max(m_lims,msub)
        if (maxlim eq -1) then count=50 else begin
            ims[0] = msub
        
            fail = 0
            fname=find_rotse3_image(st[ims[0]].fname,fail=fail)
            if (fail) then begin
                print,'could not find '+st[ims[0]].fname
                m_lims[ims[0]] = -1
                ims[0] = -1
            endif
        endelse
        count=count+1
    endwhile

    if (ims[0] ne -1) then begin
        ;; the next one
        testdate=(str_sep(st[ims[0]].fname,'_'))[0]
        otherdates=bytarr(nst)
        for j=0l,nst-1 do $
          if (testdate eq (str_sep(st[j].fname,'_'))[0]) then otherdates[j] = 1
        
        h=where(otherdates eq 0, hcnt)
        if (hcnt gt 0) then begin
            count = 0
            while ((ims[1] eq -1) and (count lt 50)) do begin
                maxlim = max(m_lims[h],msub)
                if (maxlim eq -1) then count=50 else begin
                    ims[1] = h[msub]

                    fail = 0
                    fname=find_rotse3_image(st[ims[1]].fname,fail=fail)
                    if (fail) then begin
                        print,'could not find '+st[ims[1]].fname
                        m_lims[ims[1]] = -1
                        ims[1] = -1
                    endif
                endelse
                count=count+1
            endwhile


        endif
    endif


    for j=0l,1 do begin
        if (ims[j] ne -1) then begin
            fail = 0
            fname=find_rotse3_image(st[ims[j]].fname,fail=fail)
            if (fail) then begin
                print,'what the fuck?'
            endif else begin
                cobjname=find_rotse3_cobj(st[ims[j]].fname,fail=fail)
                if (fail) then begin
                    print,'still, what the fuck???'
                endif else begin
                    cmd = 'cp '+fname+' '+templatedir+'/image/'
                    print,cmd
                    spawn,cmd
                    cmd = 'cp '+cobjname+' '+templatedir+'/prod/'
                    print,cmd
                    spawn,cmd
                endelse
            endelse
        endif
    endfor
endfor


return
end
