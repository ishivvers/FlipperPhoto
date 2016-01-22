pro simtrans_generate,simtransdir,matchname,ntrans,output=output,templatedir=templatedir

if n_params() eq 0 then begin
    print,'syntax- simtrans_generate,simtransdir,matchname,ntrans,output=output,templatedir=templatedir'
    return
endif

st=mrdfits(matchname,2)

parts=strsplit(st[n_elements(st)-1].fname,'_',/extract)
lastdate = parts[0]

useim = bytarr(n_elements(st))
for j=long(n_elements(st)-1),0,-1 do begin
    parts = strsplit(st[j].fname,'_',/extract)
    if (parts[0] eq lastdate) then useim[j] = 1 else j = 0l
endfor

use=where(useim eq 1,uct)
if (uct eq 0) then begin
    print,'No images????'
    return
endif

fnames=st[use].fname

imnames=strarr(n_elements(fnames))
for i=0l,n_elements(imnames)-1 do begin
    fail = 0
    imnames[i]=find_rotse3_image(fnames[i],fail=fail,path='./image')
    if (fail eq 1) then begin
        print,'Image not found!  Fatal error.'
        return
    endif
endfor


;; make the images
simtrans_add_stars_to_images,imnames,ntrans,ofile,addstars,simtransdir=simtransdir,templatedir=templatedir

if n_elements(addstars) eq 0 then begin
    print,'problem with simtrans_add_stars_to_images'
    return
endif

;; make the links
;; all the addstars guys have the same images, so just use the 0th index
for i=0l,n_elements(addstars[0].fnames)-1 do begin
    cmd = "ln -s "+simtransdir+"/image/"+addstars[0].fnames[i]+ $
      ' '+simtransdir+'/links/'
    spawn,cmd
endfor

;; now, run sexpacman2.  Be sure that "quit 1" is set in the sexpipeline.conf file

cd,simtransdir
cmd='sexpacman2.pl sexpipeline.conf'
spawn,cmd

;;simtrans_pipeline,
simtrans_pipeline,simtransdir+'/sobjlist',matchname=matchname,simtransdir=simtransdir,templatedir=templatedir,output=output



return
end
