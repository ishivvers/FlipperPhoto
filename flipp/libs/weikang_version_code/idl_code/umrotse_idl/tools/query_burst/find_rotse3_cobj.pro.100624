function find_rotse3_cobj,name,path=path,fail=fail,sobj=sobj

if n_params() eq 0 then begin
    print,'syntax- find_rotse3_cobj,name,path=path,fail=fail,sobj=sobj'
    print,'   name is the image or cobj name'
    fail = 1
    return,''
endif

fail = 0

to_find = 'cobj'
if keyword_set(sobj) then to_find = 'sobj'

paths=['/rotse/data/pipeline/prod/','/rotse/data/rotse3/', $
       '/rotse3/data0/rotse3/','/rotse3/data1/rotse3/','/rotse3/data2/rotse3/', $
       '/rotse5/data0/rotse3/','/rotse5/data1/rotse3/','/rotse5/data2/rotse3/', $
       '/rotse7/data0/rotse3/','/rotse7/data1/rotse3/', $
       '/rotse11/data0/rotse3/','/rotse11/data1/rotse3/']

dirparts = str_sep(name,"/")
nparts = n_elements(dirparts)

parts=str_sep(dirparts[nparts-1],'_')

if n_elements(parts) eq 3 then begin
    fbase = parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,5)
endif else begin
    fbase = parts[0] + '_' + parts[1] + '_' + parts[2]
endelse

for i=1l,n_elements(paths)-1 do begin
    paths[i] = paths[i] + parts[0] + '/prod/'
endfor

if (n_elements(path) ne 0) then $
  paths = [path + '/', paths]

i=0l
found_cobj = 0
cobj=''
while ((i lt n_elements(paths)) and (not found_cobj)) do begin
;;    globstr = paths[i] + fbase + '_cobj.fit'
    globstr = paths[i] + fbase + '_' + to_find + '.fit'
    test = findfile(globstr, count=count)
    if (count gt 0) then begin
        cobj = test[0]
        found_cobj = 1
    endif
    i = i+1
endwhile

if (not found_cobj) then fail = 1

return,cobj

end
