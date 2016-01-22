pro limit_consec,m,nconsec,obj,maxtime=maxtime,magcut=magcut,appendobs=appendobs, above_m_lim = above_m_lim

if n_params() eq 0 then begin
    print,'syntax- limit_consec,m,nconsec,obj,maxtime=maxtime, magcut=magcut, appendobs=appendobs, above_m_lim=above_m_lim'
    return
endif

if (n_elements(maxtime) eq 0) then begin
    maxtime = 12./24.
endif

if (n_elements(magcut) eq 0) then begin
    magcut = 17.5
endif

if n_elements(above_m_lim) eq 0 then begin
    above_m_lim = 0.5
endif

if n_elements(appendobs) eq 0 then begin
    appendobs = indgen(n_elements(m.jd))
endif


for i=0l,n_elements(m.ra)-1 do begin
    h=where((m.m(*,i) gt 0.0) and (m.m(*,i) lt 30.0), nobs)

    ; Need to count no_obs by using the m_lim
    mavg = 30.0
    if (nobs ge 2) then mavg = mean(m.m[h,i])
    j=where((m.m[*,i] eq -1) and (mavg lt (m.m_lim - above_m_lim)), no_obs)

    if ((nobs eq nconsec) and (no_obs ge 6)) then begin
        if min(h eq (indgen(nobs) + min(h))) then begin
            match,appendobs,h,suba,subb,count=count
            if (count gt 0) then begin
                                ; we have the requisite # of consecutive observations
                delta_t = max(m.jd(h)) - min(m.jd(h))
                bright = min(m.m(h,i))
                if (delta_t lt maxtime) and (bright lt magcut) then begin
                                ; we found one!
                    add_arrval,i,obj_arr
                endif
            endif
        endif
    endif
endfor

if n_elements(obj_arr) eq 0 then obj_arr = -1

obj=obj_arr




return
end
