pro find_template_images,templatedir,checkname,imnames,cobjnames,count=count

if n_params() eq 0 then begin
    print,'syntax- find_template_images,templatedir,checkname,imnames,cobjnames,count=count'
    return
endif

;; initialize
imnames = -1
cobjnames = -1
count=0

parts=strsplit(checkname,'_',/extract)

if (n_elements(parts) lt 2) then begin
    print,'Illegal checkname'
    return
endif

date=parts[0]
tlaroot=parts[1]

globstr = templatedir + '/image/??????_' + tlaroot + '_*'

images = findfile(globstr,count=ct)

if (ct eq 0) then begin
    print,'No template images'
    return
endif

;; make sure each image has a cobj and then add to list

for i=0l,ct-1 do begin
    dirparts=strsplit(images[i],'/',/extract)
    
    ;; check that the date is okay (not today)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    if (parts[0] ne date) then begin
        parts=strsplit(dirparts[n_elements(dirparts)-1],'\_c\.fit',/extract,/regex)
        globstr=templatedir + '/prod/' + parts[0] + '_cobj.fit'
        cobjs = findfile(globstr,count=cct)
        
        if (cct eq 1) then begin
            if (count eq 0) then begin
                ;; initialize the list
                imnames = images[i]
                cobjnames = cobjs[0]
                count = count + 1
            endif else begin
                ;; append to the list
                imnames = [imnames,images[i]]
                cobjnames=[cobjnames,cobjs[0]]
                count = count + 1
            endelse
        endif
    endif
endfor



return
end
