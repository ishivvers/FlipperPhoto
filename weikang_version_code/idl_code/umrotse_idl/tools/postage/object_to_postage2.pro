function object_to_postage2,mat,obj,matname=matname,path=path,fail=fail

if n_params() eq 0 then begin
    print,'syntax- object_to_postage2,mat,obj,matname=matname,path=path,fail=fail'
    fail = 1
    return,' '
endif

count_postage,mat,obj,fitname,indices,matname=matname,path=path,fail=fail

if (fail eq 1) then begin
    return,fitname
endif

for i=0,n_elements(indices)-1 do begin
    postage_fitmaker2,fitname,mat,obj,indices[i]
endfor

return,fitname
end
