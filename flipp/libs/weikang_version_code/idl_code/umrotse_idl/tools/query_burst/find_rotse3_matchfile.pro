function find_rotse3_matchfile,name,path=path,fail=fail

if n_params() eq 0 then begin
    print,'syntax- find_rotse3_matchfile,name,path=path,fail=fail'
    print,'   name is the short name string'
    fail = 1
    return,''
endif

fail = 0

paths=['/rotse/data/pipeline/prod/', '/rotse/data/rotse3/*/', $
       '/rotse/data/rotse3/*/prod/', $
       '/rotse3/data0/rotse3/*/prod/','/rotse3/data1/rotse3/*/prod/', $
       '/rotse3/data2/rotse3/*/prod/','/rotse4/data1/rotse3/*/', + $
       '/rotse4/data1/rotse3/*/prod/', '/rotse4/data2/rotse3/*/prod/', + $
       '/rotse4/data2/rotse3/*/']

if (n_elements(path) ne 0) then $
  paths = [path + '/', paths]

i=0l
found_match = 0
match=''
while ((i lt n_elements(paths)) and (not found_match)) do begin
    globstr = paths[i] + name + '_3?_match.fit'
    test = findfile(globstr, count = count)
    if (count gt 0) then begin
        match = test[0]
        found_match = 1
    endif
    i=i+1
endwhile

if (not found_match) then fail = 1

return,match
end
