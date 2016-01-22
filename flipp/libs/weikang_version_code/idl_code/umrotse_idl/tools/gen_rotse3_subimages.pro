PRO gen_rotse3_subimages, racent, deccent, degrad, imagenames=imagenames, tlaroot=tlaroot, oname=oname, usecoadd=usecoadd, maxframe=maxframe, nocobjcrop=nocobjcrop,square=square, fail=fail, imuse=imuse

if n_params() lt 3 then begin
    print, 'syntax- gen_rotse3_subimages, racent, deccent, degrad, imagenames=imagenames, tlaroot=tlaroot, oname=oname, usecoadd=usecoadd, maxframe=maxframe, nocobjcrop=nocobjcrop,square=square, fail=fail, imuse=imuse'
    print, '   one and only one of imagenames & tlaroot must be set'
    print, '   maxframe will prevent processing even on specified imagenames'
    print, '   ra/dec/radius in degrees'
    print, '   when using tlaroot, usecoadd allows only coadds to be used, otherwise no coadds used'
    print, '   successful image names are returned in oname'
endif

;; initialize
fail=0
oname=''
if n_elements(maxframe) eq 0 then maxframe=50

;; do the checks: imagenames vs tlaroot

use_imname=0 & use_tlaroot=0

if n_elements(imagenames) gt 0 and size(imagenames, /type) eq 7 then use_imname=1

if n_elements(tlaroot) gt 0 and size(tlaroot, /type) eq 7 then use_tlaroot=1

if use_imname and use_tlaroot then begin
    print, 'Can only use one of imagenames, tlaroot'
    fail=1
    return
endif else if not use_imname and not use_tlaroot then begin
    print, 'Must have string input for one of imagenames, tlaroot'
    fail=1
    return
endif

imageset=''

if use_imname then begin
    imageset=imagenames 
    nim=n_elements(imagenames)
endif else begin

    nim=0

    for ii=0, n_elements(tlaroot)-1 do begin
        tmp=find_rotse3_tlaroot(tlaroot[ii],path=['./image','.'],usecoadd=usecoadd,fail=fail)
        if not fail then begin
            if nim eq 0 then imageset=tmp else imageset=[imageset,tmp]
            nim=nim+n_elements(tmp)
        endif
    endfor

;; tlaroot finds no coadds when use_coadd is not set, finds only
;; coadds when use_coadd is set

;; tlaroot should only find unique names.

    if nim eq 0 then begin
        print, 'no results found for tlaroot'
        fail=1
        return
    endif

endelse

;; have some imageset, now cut off those that violate maxframe

imuse=''
nimuse=0

;;stop

for ii=0, nim-1 do begin

    dirparts=strsplit(imageset[ii],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)

;; frame # is the last 3 digits of parts[2], whether it's a coadd or not

    framenum=strmid(parts[2],2,3,/reverse_offset)

    if fix(framenum) le maxframe then begin
        if nimuse eq 0 then imuse=imageset[ii] else imuse=[imuse,imageset[ii]]
        nimuse=nimuse+1
    endif

endfor

if nimuse eq 0 then begin
    print, 'images found, but none below maxframe'
    fail=1
    return
endif

nsuccess=0

;;stop

for ii=0, nimuse-1 do begin

    make_rotse3_subimage,imuse[ii],racent=racent,deccent=deccent,$
      degrad=degrad,oname=onametmp,nocobjcrop=nocobjcrop,square=square,$
      fail=failtmp

    if not failtmp then begin

        if nsuccess eq 0 then oname=onametmp else oname=[oname,onametmp]
        nsuccess=nsuccess+1

    endif

endfor

if nsuccess eq 0 then begin
    print, 'subimages attempted, none succeeded'
    print, racent, deccent, degrad
    fail=1
    return
endif

;; now move to working directory's image/ and prod/ subdirectories if
;; they exist

;; must have BOTH to do this

subdirim=0 & subdirprod=0

res=findfile("-d ./prod", count=cnt)
if cnt gt 0 then subdirprod=1

res=findfile("-d ./image", count=cnt)
if cnt gt 0 then subdirim=1

if subdirprod and subdirim then begin

    for ii=0, n_elements(oname)-1 do begin

        dirparts=strsplit(oname[ii],'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)

        namebase=parts[0]+'_'+parts[1]+'_'+parts[2]

        spawn, 'mv '+namebase+'_c.fit ./image/', res, err
;        print, res, err
        spawn, 'mv '+namebase+'_cobj.fit ./prod/', res, err
;        print, res, err

    endfor

endif

end
