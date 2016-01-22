pro ss_coadd_rotse3_filter,fnames,imagepath=imagepath,cobjpath=cobjpath,imtot=imtot,coaddname=coaddname,minperc=minperc,satmask=satmask,savesat=savesat,badmap=badmap

;; apply median filter if there are more than 3 images

if n_params() eq 0 then begin
    print,'syntax- ss_coadd_rotse3_filter,fnames,imagepath=imagepath,cobjpath=cobjpath,imtot=imtot,coaddname=coaddname,minperc=minperc,satmask=satmask,savesat=savesat,badmap=badmap'
    return
endif


;; Initialization

if n_elements(minperc) eq 0 then minperc = 0.5

totobs = (size(fnames))[1]
totexptime = 0.0
tot_satlvl = 0.0

imagenames = strarr(totobs)
cobjnames = strarr(totobs)

if n_elements(imagepath) eq 0 then imagepath = 'image'
if n_elements(cobjpath) eq 0 then cobjpath = 'prod'

for i=0l,n_elements(fnames)-1 do begin
    ;; we can take a list of images or cobj files
    
    fail = 0
    full_imagename = find_rotse3_image(fnames[i],fail=fail,path=imagepath)
    if fail eq 1 then begin
        fimname=repstr(fnames[i],'prod/','image/')
        fimname=repstr(fimname,'_cobj.','_c.')
        full_imagename=findfile(fimname,count=ct)
        if ct eq 0 then begin
            fimname=fimname+'.gz'
            full_imagename=findfile(fimname,count=ct)
        endif
        if ct eq 1 then fail=0
        
    endif
    if (fail eq 1) then begin
        print,'Could not find image for ',fnames[i]
        return
    endif
    
    full_cobjname = find_rotse3_cobj(fnames[i],fail=fail,path=cobjpath)
    if fail eq 1 then begin
        full_cobjname=findfile(fnames[i],count=ct)
        if ct eq 1 then fail=0
    endif
    if (fail eq 1) then begin
        print,'Could not find cobj for ',fnames[i]
        return
    endif
    imagenames[i] = full_imagename
    cobjnames[i] = full_cobjname
    
endfor
 
if n_elements(coaddname) ne 1 then begin
    dirparts=strsplit(imagenames[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    basename = parts[0] + '_' + parts[1] + '_' + parts[2]
  
    dirparts=strsplit(imagenames[totobs-1],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    outname = basename + '-' + strmid(parts[2],2,3)+'_c.fit'
    satname= basename + '-' + strmid(parts[2],2,3)+'_satmask.fit'
endif else begin
    outname=coaddname+'_c.fit'
    satname=coaddname+'_satmask.fit'
    dirparts=strsplit(imagenames[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    basename = parts[0] + '_' + parts[1] + '_' + parts[2]
endelse

;; Get first image calibrated object list

cref = mrdfits(cobjnames[0],1,/silent)
sref = mrdfits(cobjnames[0],2,/silent)
imn = r_readfits(imagenames[0],hdr)
nx = (size(imn))[1]
ny = (size(imn))[2]

usebad=0b
if keyword_set(badmap) then begin
    szbd= size(badmap)
    if szbd[1] eq nx and szbd[2] eq ny then begin
        usebad=1b
        imn=ss_rm_badpix(imn,badmap)
    endif else begin
        print,'bad pixel map doesnot match the size of image, not using it'
    endelse
endif

gdref=where(cref.flags le 2,ngdref)
if (ngdref lt 100) then begin
    print,'WARNING: Not enough good reference stars.  Using them all.'
    gdref=lindgen(n_elements(cref))
endif

weight = fltarr(nx,ny)
imtot = fltarr(nx,ny)
if keyword_set(satmask) then satmask = bytarr(nx,ny) 

;; array to store the image valus and sky values
imstack=fltarr(nx,ny,totobs)
imct=0
singlenames=strarr(totobs)
singlenames[imct]=sxpar(hdr,'FILENAME')
 
imhdr = hdr

;; make a satruation map
if keyword_set(satmask) or keyword_set(savesat) then begin
    satmask=bytarr(nx,ny)
    satmask[where(imn ge sref.sexsatlv)]=1b
endif

;; need better sky subtraction??
sky,imn,sky,skyerr,/silent
imn = imn - sky

imstack[*,*,imct]=imn
exptime = sxpar(hdr,'EXPTIME')
;tstart=sxpar(hdr,'OBSTIME')
;tstop=tstart+exptime
jdstart=sref.mjd
jdstop=sref.mjd
weight[*,*] = exptime
totexptime = exptime
tot_satlvl = sref.sexsatlv - sky - 2*skyerr
mjdstart=sxpar(hdr,'MJD')

;; Now, add up the coadded image.  Subtract sky from each image so all regions
;; are on the same footing. Then map to the original frame and add the warped image

if totobs gt 1 then begin
    for k=1,totobs-1 do begin
        cnew = mrdfits(cobjnames[k],1,/silent)
        snew = mrdfits(cobjnames[k],2,/silent)
        
        gdnew=where(cnew.flags le 2,ngdnew)
        if (ngdnew lt 100) then begin
            print,'WARNING: Not enough good new stars.  Using them all.'
            gdnew=lindgen(n_elements(cnew))
        endif
        
    ;; put some stuff in later to check for ra 0 degrees...
        ;;diff = sref.rac - sref.rac
        
        ;; match only the good stars
        close_match_radec,cref[gdref].ra,cref[gdref].dec, $
          cnew[gdnew].ra,cnew[gdnew].dec,m1,m2,0.0009D,1.0,miss1
        nobj = n_elements(m1)
        
        print,'Number of matched objects is: ',+string(nobj)
        
        if (nobj lt (minperc * ngdref)) then begin
            print,'Not enough stars matched:',n_elements(m1),' < ',minperc*ngdref
            print,'Not adding this image.'
        endif else begin 
            imn = r_readfits(imagenames[k], hdr)

            nnx=(size(imn))[1]
            nny=(size(imn))[2]
            
            if ((nnx ne nx) or (nny ne ny)) then begin
                print,'Cannot add frame with different size.'
                print,'Not adding this image.'
            endif else begin
            
                if keyword_set(badmap) and usebad eq 1b then imn=ss_rm_badpix(imn,badmap)
                sky, imn, sky, skyerr,/silent
                imn = imn - sky
                exptime = sxpar(hdr, 'EXPTIME')
                ;tstart0=sxpar(hdr,'OBSTIME')
                ;tstop0=tstart0+exptime
                ;if tstart0 lt tstart then tstart=tstart0
                ;if tstop0 gt tstop then tstop=tstop0
                jdstop=snew.mjd
                wn = imn    ;; this is inefficient
                wn[*,*] = exptime
                totexptime = totexptime + exptime
                tot_satlvl = tot_satlvl + (snew.sexsatlv - sky - skyerr)
                mjdnew=sxpar(hdr,'MJD')
                if mjdnew lt mjdstart then mjdstart=mjdnew

                print,'Adding frame: ',imagenames[k]
                nl = fix(nobj*0.1)
                nh = fix(nobj*0.6)
                polywarp,cnew[gdnew[[m2[nl:nh]]]].x,cnew[gdnew[[m2[nl:nh]]]].y, $
                  cref[gdref[[m1[nl:nh]]]].x,cref[gdref[[m1[nl:nh]]]].y, 3, kx, ky
                imn = poly_2d(imn, kx, ky, 2, missing=0.0, cubic=-0.5)
                wn = poly_2d(wn, kx, ky, 2, missing=0.0, cubic=-0.5)
                
                ;; update the satruation map
                if keyword_set(satmask) or keyword_set(savesat) $
                  then satmask[where(imn ge snew.sexsatlv-sky)]=1b
                
                imct=imct+1
                singlenames[imct]=sxpar(hdr,'FILENAME')
                imstack[*,*,imct]=imn
                weight = weight + wn
            endelse
        endelse
    endfor
endif 

imstack=imstack[*,*,0:imct]
singlenames=singlenames[0:imct]

if imct ge 2 then begin
;;apply median filter if there are more than 3 images
    
    pixmed=fltarr(nx,ny)
    for inx=0,nx-1 do begin
        for iny=0,ny-1 do begin
            pixmed[inx,iny]=median(imstack[inx,iny,*],/even)
        endfor
    endfor
    pixvar=(imstack[*,*,0]-pixmed)^2
    for ind=1,imct do begin
        pixvar=pixvar+(imstack[*,*,ind]-pixmed)^2
    endfor
    pixvar=sqrt(pixvar/imct)
    surround=[(-nx+lindgen(3)-1),-1,1,(nx+lindgen(3)-1)]
    for ind=0,imct do begin
        bad=where(abs(imstack[*,*,ind]-pixmed) gt 3*pixvar,nbad)
        if nbad gt 0 then begin
            imtemp=imstack[*,*,ind]
            imtemp[bad]=median(imtemp[bad+surround],/even)  
            imstack[*,*,ind]=imtemp
        endif
    endfor
    
endif 

imtot=imstack[*,*,0]
if imct ge 1 then begin
    for ind=1,imct do begin
        imtot=imtot+imstack[*,*,ind]
    endfor
endif

;; now...
h=where(weight ne 0.0, count)
imtot[h] = imtot[h]*(totexptime/weight[h])
minval = min(imtot[h], iobj)
if (minval lt 0.0) then begin
    nlow = 1
    minval2 = minval
    m2 = iobj
    while (nlow le 12) do begin
        minval = minval2
        m = m2
        minval2 = minval2 + 100.0
        m2 = where(imtot[h] lt minval2, nlow)
    endwhile
    imtot[h[m]] = minval
endif

;; Construct a filename and header, and write the image
sxaddpar,imhdr,'MJD',mjdstart
;sxaddpar,imhdr,'OBSTIME',tstart
sxaddpar,imhdr,'EXPTIME',totexptime
sxaddpar,imhdr,'SATCNTS',tot_satlvl
sxaddpar,imhdr,'NCOADD',imct+1
sxaddpar,imhdr,'FILENAME',outname
sxaddpar,imhdr,'BASENAME',basename

;efftime = tstop - tstart
efftime=(jdstop-jdstart)*24d0*3600d0+exptime
sxaddpar,imhdr,'EFFTIME',efftime
;; lowest=min(imtot)
;; highest=max(imtot)
;; bscale = (highest - lowest)/65535.0
;;bzero = 0.5*(highest + lowest + bscale)
;; sxaddpar,imhdr,'BZERO',bzero
;; sxaddpar,imhdr,'BSCALE',bscale
;; new_im=fix(round(imtot-bzero)/bscale)
;; writefits, outname, new_im, imhdr
for i=0,imct do begin
    singlehdr='IM'+repstr(string(i+1,format='(i2)'),' ','0')
    sxaddpar,imhdr,singlehdr,singlenames[i]
endfor

writefits,outname,imtot,imhdr

if keyword_set(savesat) then writefits,satname,satmask    
 
end
