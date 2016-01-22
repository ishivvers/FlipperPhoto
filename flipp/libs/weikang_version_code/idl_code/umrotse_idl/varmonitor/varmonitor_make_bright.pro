pro varmonitor_make_bright,vm,brightindex,dimindex

; Created Novermber 11, 2005 Michael Claus
; Version 1.1.2
; Purpose: To find significantly brighter or dimmer objects in monitored
; variables and accent them on their light curve.

if n_params() lt 3 then begin
    print,'syntax- varmonitor_make_bright,vm,brightindex,dimindex'
    return
endif

magnitude=where(vm.m gt 0, count1)
limit=where(vm.m lt 0, count2)
if count1 gt 0 and count2 eq 0 then begin
    realmag = vm.m[magnitude]
    average=mean(realmag)
    sig=stddev(realmag)
    newmagindex=where(vm.m lt average+(3*sig) and vm.m gt average-(1.8*sig))
    newmag=vm.m[newmagindex]
    newaverage=mean(newmag)
    newsig=stddev(newmag)

    dimmag=where(realmag gt newaverage+(3*newsig) and realmag gt (newaverage+1.2), count3)
    brightmag=where(realmag lt newaverage-(2.5*newsig) and realmag lt (newaverage-1.2), count4)
endif

if count2 gt 0 and count1 eq 0 then begin
    brightindex=[-1]
    dimindex=[-1]
endif

if count1 gt 0 and count2 gt 0 then begin
    realmag = vm.m[magnitude]
    reallimit=vm.m_lim[limit]

    realnum=[realmag,reallimit]
    average=mean(realnum)
    sig=stddev(realnum)
    newmagindex=where(vm.m lt average+(3*sig) and vm.m gt average-(1.8*sig))
    newmag=vm.m[newmagindex]
    realnum=[newmag,reallimit]
    newaverage=mean(realnum)
    newsig=stddev(newmag)

    dimmag=where(realmag gt newaverage+(3*newsig) and realmag gt (newaverage+1.2), count3)
    brightmag=where(realmag lt newaverage-(2.5*newsig) and realmag lt (newaverage-1.2), count4)    
endif

if count1 gt 0 then begin
    if count4 eq 0 then begin
        bright=[-1]
    endif
    if count4 gt 0 then begin
        bright=realmag[brightmag]
    endif
    if count3 eq 0 then begin
        dim=[-1]
    endif
    if count3 gt 0 then begin
        dim=realmag[dimmag]
    endif

    brightindex=where(vm.m lt newaverage-(2.5*newsig) and vm.m gt 0 and vm.m lt (newaverage-1.2))
    dimindex=where(vm.m gt newaverage+(3*newsig) and vm.m gt (newaverage+1.2))
endif

return
end
