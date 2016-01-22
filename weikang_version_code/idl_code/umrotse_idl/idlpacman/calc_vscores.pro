function vscore,m,merr

if n_params() eq 0 then begin
    print,'syntax- vscore(m, merr)'
    return,-1
endif

score = 0.0

nm = n_elements(m)
if (nm eq 0) then return,score
if (m[0] eq -1) then return,score

mavg = mean(m)

score = total((m - mavg)^2./(merr^2))/(nm-1)

return,score
end


pro calc_vscores,mat,obj_arr,goodim_arr,vscore_arr,rmask=rmask,emask=emask,syserr=syserr

if n_params() lt 3 then begin
    print,'syntax- calc_vscores,mat,obj_arr,goodim_arr,vscore_arr,rmask=rmask,emask=emask,syserr=syserr'
    return
endif

if (n_elements(emask) eq 0) then begin
    emask = 28
endif
if (n_elements(rmask) eq 0) then begin
    rmask = 9
endif
if (n_elements(syserr) eq 0) then begin
    syserr = 0.05
endif

if tag_exist(mat,'nobs') then begin
    allobs = lindgen(mat.nobs)
endif else begin
    allobs = lindgen(n_elements(mat.jd))
endelse

nobj = n_elements(obj_arr)

vscore_arr=fltarr(nobj)

;;goodims=fltarr(n_elements(mat.m[*,0]))
goodims=intarr(n_elements(allobs))
goodims[goodim_arr] = 1

for i=0l,nobj-1 do begin
    index=obj_arr[i]

    h=where(((mat.flags[allobs,index] and emask) eq 0) and $
            ((mat.rflags[allobs,index] and rmask) eq 0) and $
            (mat.m[allobs,index] gt 0) and (mat.m[allobs,index] lt 25) and $
            (goodims eq 1) , count)

    if (count ge 3) then begin
        m=mat.m[h,index]
        merr=sqrt((mat.merr[h,index])^2. + (syserr^2.))
        vscore_arr[i] = vscore(m,merr)
    endif else begin
        vscore_arr[i] = 0.0
    endelse
endfor

return
end
