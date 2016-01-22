function ss_add_tag,old,tag,value

if n_params() lt 3 then begin
    print,'syntax- new=ss_add_tag(old,tag,value)'
    return,''
endif

nold=n_elements(old)
if nold ne n_elements(value) then begin
    print,'The length of value doesnot match that of the old structure.'
    return,''
endif

if nold gt 1 then begin
    ntag=n_tags(old[0])
    temp=create_struct(old[0],tag,value[0])
    new=replicate(temp,nold)
    for i=0,ntag-1 do begin
        new.(i)=old.(i)
    endfor
    new.(ntag)=value
endif else begin
    new=create_struct(old,tag,value)
endelse

return,new

end
