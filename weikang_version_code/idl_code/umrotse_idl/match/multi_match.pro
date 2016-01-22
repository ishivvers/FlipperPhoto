pro multi_match,match,rac=rac,decc=decc,filelist=filelist,$
usnofile=usnofile,dir=dir,preffix=preffix,suffix=suffix,$
filenums=filenums,keep=keep,skip=skip,rskip=rskip,subr=subr,matchfile=matchfile
;takes the files of repeated observtaion and the usnofile and makes
; a match structure
;filelist is a string array of the sextractor catalogs
;usnofile is the fits file containing the usno data
;you can also sprecify dir,preffix,suffix and filenums
;and it will create the filelist for you
;rac and decc are the ra,dec for the center of the image

if n_params() eq 0 then begin
	print,'-syntax multi_match,match,rac=rac,decc=dec,filelist=filelist'
	print,'usnofile=usnofile,dir=dir,preffix=preffix,suffix=suffix'
	print,'filenums=filenums,keep=keep,skip=skip,rskip=rskip,subr=sub'
	print,'matchfile=matchfile'
	return
endif

if n_elements(keep) eq 0 then keep=27
if n_elements(skip) eq 0 then skip=10
if n_elements(rkip) eq 0 then rskip=10
if n_elements(subr) eq 0 then subr=.3

if n_elements(filelist) eq 0 then begin
	print,'making filenames'
	num=n_elements(filenums)
	filelist=strarr(num)
	for i=0,num-1 do begin
		file=dir+preffix+string(filenums(i))+suffix
		file=strcompress(file,/remove_all)
		filelist(i)=file
		print,file
	endfor
endif	


usnocat=mrdfits(usnofile,1,hdr)

num=n_elements(filelist)
j=0
;j is an index like i but doesn't increment when addmatch fails to
;add a match. This is so when we add the imagename, it goes in the
;right spot
for i=0,num-1 do begin
	print,'run number ',i,' of ', num
	file=filelist(i)
	print,file
	cat=mrdfits(file,1,hdr)
	p=strpos(file,'_sobj')
	imf=file
	strput,imf,'_c   ',p
	imf=strcompress(imf,/remove_all)
	;asumes image filename is same as object list
	;except for '_sobj' replaced by '_c'
	hdr=headfits(imf)
	if i eq 0 then begin
		catmatch_s,rac,decc,usnocat,cat,match,iter=4,hdr=hdr,$
		subr=subr,keep=keep,skip=skip,rskip=rskip
		fail=0
                print,'created match structure'
	endif else begin
		addmatch_s,match,cat,match,iter=4,hdr=hdr,keep=keep,skip=skip,fail=fail
		print,'added ',file,' to match structure' 
	endelse
        if fail eq 0 then begin
             match.imagename(j+1)=imf
             j=j+1
        endif    
      

        if (j mod 5) eq 0 and j gt 0 then begin
             print,'IN FILTERING SEQUENCE'
                                ;this is a filtering sequence that
                                ;gets rid of objects that only show up
                                ;once to save memory
            numneg,match,numneg,numnotneg
            w=where(numnotneg gt 2,howm)
            print,n_elements(match.rmag),' objects before filter'
            print,howm,' objects after filter'
            ssz=size(match.jd)
            noob=ssz(1)
            make_mstruct,match2,noob,howm
                                ;this throws out things that only show
                                ;up once (also shows up in template of
                                ;course) to save memory and reduce
                                ;background
            match2.kx=match.kx
            match2.ky=match.ky
            match2.jd=match.jd
            match2.filter=match.filter
            match2.exptime=match.exptime
            match2.imagename=match.imagename
            match2.airmass=match.airmass
            match2.rac=match.rac
            match2.decc=match.decc
            match2.x=match.x(*,w)
            match2.y=match.y(*,w)
            match2.m=match.m(*,w)
            match2.merr=match.merr(*,w)
            match2.fwhm=match.fwhm(*,w)
            match2.ra=match.ra(w)
            match2.dec=match.dec(w)
            match2.rmag=match.rmag(w)
            match2.bmag=match.bmag(w)
            match=match2
            match2=0
                                ;match has now been trimmed and match2 deleted
        endif
     
help,match,/str
help,/memory
endfor
if n_elements(matchfile) ne 0 then begin
matchfile=strcompress(dir+matchfile,/remove_all)
mwrfits,match,matchfile,/create
endif

return
end













