function find_rotse3_tlaroot,root,path=path,fail=fail,usecoadd=usecoadd,pair=pair,tel=tel

if n_params() eq 0 then begin
    print,'syntax- find_rotse3_tlaroot,root,path=path,fail=fail,usecoadd=usecoadd,pair=pair,tel=tel'
    fail = 1
    return,['']
endif

fail = 0

paths=['/rotse/data/pipeline/prod/', '/rotse/data/rotse3/', '/rotse3/data0/rotse3/', $
       '/rotse3/data1/rotse3/', '/rotse3/data2/rotse3/']

for i=1l,n_elements(paths)-1 do begin
    paths[i] = paths[i] + '??????' + '/prod/'
endfor

if (n_elements(path) ne 0) then $
  paths = [path + '/', paths]

i=0l
found = 0
cobjs = ['']
while (i lt n_elements(paths)) do begin
    if n_elements(tel) gt 0 then begin
        globstr = paths[i] + '??????_' + root + '_' + tel + '???'
    endif else begin
        globstr = paths[i] + '??????_' + root + '_?????'
    endelse
    if keyword_set(usecoadd) then globstr = globstr + '-???'
    globstr = globstr + '_cobj.fit'

    test=findfile(globstr, count=count)
    if (count gt 0) then begin
        if (not found) then cobjs = test else cobjs = [cobjs,test]
        found = 1
    endif
    i=i+1
endwhile

;; make sure we have a unique list
if (found) then begin
    temparr = strarr(n_elements(cobjs))
    ;; copy all the guys into an array without the pathnames
    for i=0l,n_elements(cobjs)-1 do begin
        dirparts = strsplit(cobjs[i],'/',/extract)
        temparr[i] = dirparts[n_elements(dirparts)-1]
    endfor

    u=uniq(temparr[sort(temparr)])
    cobjs=cobjs[sort(cobjs[u])]
endif


if (not found) then fail = 1 else if keyword_set(pair) then begin
    ;; look for pairs
    temp_cobjs = cobjs
    cobjs = ['']
    found = 0
    for i=0l,n_elements(temp_cobjs)-1 do begin
        cobj=temp_cobjs[i]
        dirparts=strsplit(cobj,'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
        framenum=long(strmid(parts[2],2,3))
        ;; if it's odd, search for the companion.  If it's even, skip it.
        if ((framenum mod 2) eq 1) then begin
            pairname=parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,2) + $
                     string(framenum+1,format='(i3.3)') + '_' + parts[3]
            for j=i+1,n_elements(temp_cobjs)-1 do begin
                dirparts=strsplit(temp_cobjs[j],'/',/extract)
                if (pairname eq dirparts[n_elements(dirparts)-1]) then begin
                    if not found then cobjs=[temp_cobjs[i],temp_cobjs[j]] else $
                      cobjs=[cobjs,temp_cobjs[i],temp_cobjs[j]]
                    found = 1
                    j = n_elements(temp_cobjs)  ;; end the loop
                endif
            endfor
        endif
    endfor

    if (not found) then fail = 1

endif

return,cobjs
end
