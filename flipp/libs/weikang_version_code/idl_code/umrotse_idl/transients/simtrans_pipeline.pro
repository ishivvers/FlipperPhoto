pro simtrans_pipeline,sobjlist,matchname=matchname,matchdir=matchdir,simtransdir=simtransdir,output=output,templatedir=templatedir

if n_params() eq 0 then begin
    print,'syntax- simtrans_pipeline,sobjlist,matchname=matchname,matchdir=matchdir,simtransdir=simtransdir,templatedir=templatedir'
    return
endif

if n_elements(templatedir) eq 0 then templatedir = '.'

rotse_setup

if n_elements(simtransdir) eq 0 then simtransdir = '.'

test=findfile('-d '+simtransdir,count=ct)
if (ct eq 0) then begin
    print,'simtransdir '+simtransdir+' does not exist.  Exiting.'
    return
endif

if n_elements(matchdir) eq 0 then matchdir = !match_archive_path

usematch = 0
if n_elements(matchname) gt 0 then usematch = 1

;; make sure we're in the right directory
cd,simtransdir
readcol,sobjlist,sobjfiles,format='a'

;; make the cobj files
for i=0l,n_elements(sobjfiles)-1 do begin
    cd,'prod'
    dparts=strsplit(sobjfiles[i],'/',/extract)
    sobjfile=dparts[n_elements(dparts)-1]
    sobj2cobj,sobjfile,'../image/'
    cd,'../'
endfor

cobjfiles=strarr(n_elements(sobjfiles))
ncobj = 0
;; make sure the cobj files are there
for i=0l,n_elements(sobjfiles)-1 do begin
    dparts=strsplit(sobjfiles[i],'/',/extract)
    parts=strsplit(dparts[n_elements(dparts)-1],'_',/extract)
    cobjfile = parts[0] + '_' + parts[1] + '_' + parts[2] + '_cobj.fit'

    test=findfile('./prod/'+cobjfile,count=ct)
    if (ct eq 1) then begin 
        cobjfiles[i] = test
        ncobj = ncobj + 1
    endif
endfor

;; check how many cobjfiles
if ((ncobj lt 4) or ((ncobj mod 2) ne 0)) then begin
    print,'Need at least 4 cobjs; need even number'
    return
endif

if (usematch) then begin
    matchfile = findfile(matchname,count=ct)
endif else begin
    parts=strsplit(sobjfile,'_',/extract)

    matchfile=findfile(matchdir + '/' + parts[1] + '_??_match.fit',count=ct)
endelse

if (ct eq 0) then begin
    print,'could not find the match file'
    return
endif


;; now we can make the match structure without saving it...
mt=mrdfits(matchfile[0],1)
st=mrdfits(matchfile[0],2)

regmatch3_list,mt,st,/pair,namelist=cobjfiles,/append

;; generate a conf structure
;;conf = create_struct('workdir',simtransdir, $
;;                     'bindir',simtransdir, $
;;                     'thumbfile',simtransdir+'/thumbcopy', $
;;                     'templatedir',templatedir)


conf = create_struct('workdir',simtransdir, $
                     'bindir','/rotse/data/pipeline/response', $
                     'thumbfile','/rotse/data/pipeline/thumbcopy', $
                     'templatedir',templatedir)


;; and we can now look for transients
appendobs=[mt.nobs-2,mt.nobs-1]

find_new_transients2,mt,st,trans,appendobs=appendobs,output=output,conf=conf,simtransdir=simtransdir,maxtrans=50


if trans[0] eq -1 then begin
    print,'No transients found!'
endif

;; and we need to compare these to what were put in
parts=strsplit(mt.imagename[appendobs[0]],'_',/extract)
addname=parts[0] + '_' + parts[1] + '_addstars.fit'
test=findfile(addname,count=ct)
if (ct gt 0) then begin
    addstars=mrdfits(addname,1)
    addstars.found = 0

    if (trans[0] ne -1) then begin

        close_match_radec,mt.ra[trans],mt.dec[trans],addstars.ra,addstars.dec,m1,m2,0.0009d,1
        addstars[m2].found = 1

        ;; and only output the simulated ones
        trans=trans[m1]
    endif


    ;; and overwrite it
    mwrfits,addstars,addname,/create

endif else begin
    print,'WARNING: Could not find addstars file'
endelse

spawn,'rm '+sobjlist

return
end
