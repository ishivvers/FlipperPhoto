pro check_focus_merger,m,radius_far,radius_near,obj,newobj

if n_params() eq 0 then begin
    print,'syntax-  check_focus_merger,m,radius_far,radius_near,obj,newobj'
    return
endif

if tag_exist(m,'nobs') then begin
    allobs = lindgen(m.nobs)
    nobs = m.nobs
    nobj = m.nobj
endif else begin
    allobs = lindgen(n_elements(m.jd))
    nobs = n_elements(m.jd)
    nobj = n_elements(m.ra)
endelse


newobj = obj

close_match_radec,m.ra[obj],m.dec[obj],m.ra,m.dec,m1,m2,radius_far,5,miss

if (m1[0] ne -1) then begin
    for i=0l,n_elements(obj)-1 do begin
        h=where(m1 eq i,count)
        if (count gt 2) then begin
            ; This is probably sufficient to rule it out, but just in case...
            mean_ra = mean(m.ra[m2[h]])
            mean_dec = mean(m.dec[m2[h]])
            close_match_radec,m.ra[obj[i]],m.dec[obj[i]],mean_ra,mean_dec,mm1,mm2, $
              radius_near,1,miss,/silent
            add_arrval,m1[i],to_remove
        endif else if (count eq 2) then begin
            ; check if the other guy disappeared
            h2=where(m2[h] ne obj[i],count2)
            if (count2 eq 1) then begin    ;; this better be the case
                compobj=m2[h[h2]]
                objobs=where(m.m[allobs,obj[i]] gt -1,nobs)
                if (nobs gt 0) then begin  ;; again, better be true!
                    test=min(m.m[objobs,compobj[0]])
                    if (test lt 0) then begin 
                        add_arrval,m1[i],to_remove
                    endif else begin
                        ;; check if the other object is > 1 mag brighter
                        if (m.mavg[compobj] < (m.mavg[m1[i]] - 1.0)) then begin
                            add_arrval,m1[i],to_remove
                        endif
                    endelse
                endif
            endif
        endif
    endfor
endif

if (n_elements(to_remove) gt 0) then begin
    if (n_elements(to_remove) eq n_elements(newobj)) then begin
        newobj = -1
    endif else remove,to_remove,newobj
endif

return
end
