function filter_cobjs,cobjlist,max_cobjs=max_cobjs,max_pos_sigma=max_pos_sigma,single=single,min_mlim=min_mlim

if n_params() lt 1 then begin
    print,'syntax- newlist=filter_cobjs(cobjlist,max_cobjs=max_cobjs,max_pos_sigma=max_pos_sigma,single=single,min_mlim=min_mlim)'
    print,'  default is for pairs'
    return,''
endif

if n_elements(max_pos_sigma) eq 0 then max_pos_sigma=0.3
if n_elements(min_mlim) eq 0 then min_mlim = 15.0
if n_elements(max_cobjs) eq 0 then max_cobjs = n_elements(cobjlist)+100

if (n_elements(cobjlist) mod 2) eq 1 and not keyword_set(single) then begin
    print,'We need an even number of cobjs unless /single is set.'
    return,''
endif

if ((max_cobjs mod 2) eq 1 and not keyword_set(single)) then begin
    max_cobjs=max_cobjs+1
endif


ncobj=n_elements(cobjlist)

pos_sigs=fltarr(ncobj)
mlims=fltarr(ncobj)
mjds=dblarr(ncobj)

for i=0l,ncobj-1 do begin
    fail = 0
    test=find_rotse3_cobj(cobjlist[i],fail=fail,path='prod')
    if (fail) then begin
        print,'Warning: could not find: ',cobjlist[i]
        pos_sigs[i] = 100.0
        mlims[i] = -1.0
        mjds[i] = -1.0
    endif else begin
        cal=mrdfits(cobjlist[i],2)
        pos_sigs[i] = cal.pos_sigma
        mlims[i] = cal.m_lim
        mjds[i] = cal.mjd
    endelse
endfor

if keyword_set(single) then begin
    ;; this one is easy...
    
    st=reverse(sort(mlims))
    cobjlist=cobjlist[st]
    pos_sigs=pos_sigs[st]
    mlims=mlims[st]
    mjds=mjds[st]

    use=where(pos_sigs lt max_pos_sigma and mlims gt min_mlim,nuse)
    if (nuse gt max_cobjs) then begin
        newlist=cobjlist[use[0:max_cobjs-1]]
        newmjds=mjds[use[0:max_cobjs-1]]
    endif else if nuse gt 0 then begin        
        newlist = cobjlist[use]
        newmjds=mjds[use]
    endif else begin
        newlist = ''
    endelse

    if (newlist[0] ne '') then begin
        st=sort(newmjds)
        newlist=newlist[st]
    endif
endif else begin
    ;; more difficult, need to watch pairs
    use_arr=bytarr(ncobj)
    mlimp=fltarr(ncobj)
;;    mjdp=dblarr(ncobj)

    for i=0l,ncobj-1,2 do begin
        if (pos_sigs[i] lt max_pos_sigma and $
            pos_sigs[i+1] lt max_pos_sigma and $
            mlims[i] gt min_mlim and $
            mlims[i+1] gt min_mlim) then begin            
            use_arr[i] = 1
            use_arr[i+1] = 1
            mlimp[i] = (mlims[i]+mlims[i+1])/2.
            mlimp[i+1] = mlimp[i]
;;            mjdp[i] = mjds[i]
;;            mjdp[i+1] = mjds[i]
        endif
    endfor

    use = where(use_arr eq 1,nuse)
    if (nuse gt max_cobjs) then begin
        st=reverse(sort(mlimp[use]))
        newlist = cobjlist[use[st[0:max_cobjs-1]]]
        newmjds = mjds[use[st[0:max_cobjs-1]]]
    endif else if nuse gt 0 then begin
        newlist = cobjlist[use]
        newmjds = mjds[use]
    endif else begin
        newlist=''
    endelse

    if (newlist[0] ne '') then begin
        ;; we're hoping that pairs stay pairs here, I'll probably have to work
        ;; on this later to be a little cleverer
        st=sort(newmjds)
        newlist=newlist[st]
    endif

endelse


return,newlist

end
