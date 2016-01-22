pro coadd_names3,fnames,imagepath=imagepath,cobjpath=cobjpath,imtot=imtot,coaddname=coaddname,minperc=minperc

;; based on Bob Kehoe's coadd_names program


 if n_params() eq 0 then begin
     print,'syntax- coadd_names3,fnames,imagepath=imagepath,cobjpath=cobjpath,imtot=imtot,coaddname=coaddname,minperc=minperc'
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
     if (fail eq 1) then begin
         print,'Could not find image for ', rawname
         return
     endif
     full_cobjname = find_rotse3_cobj(fnames[i],fail=fail,path=cobjpath)
     if (fail eq 1) then begin
         print,'Could not find cobj for ',rawname
         return
     endif

     dirparts=strsplit(full_imagename,'/',/extract)
     parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
     
     basename = parts[0] + '_' + parts[1] + '_' + parts[2]

     if (i eq 0) then $
       outname = basename $
     else if (i eq n_elements(fnames)-1) then $
       outname = outname + '-' + strmid(parts[2],2,3)+'_c.fit'

     
     
     imagenames[i] = full_imagename
     cobjnames[i] = full_cobjname

 endfor

 ;; Get first image calibrated object list

 cref = mrdfits(cobjnames[0],1)
 sref = mrdfits(cobjnames[0],2)
 imn = r_readfits(imagenames[0],hdr)
 nx = (size(imn))[1]
 ny = (size(imn))[2]

 gdref=where(cref.flags le 2,ngdref)
 if (ngdref lt 100) then begin
     print,'WARNING: Not enough good reference stars.  Using them all.'
     gdref=lindgen(n_elements(cref))
 endif

 weight = fltarr(nx,ny)
 imtot = fltarr(nx,ny)

;; if (not keyword_set(nofirst)) then begin
 imhdr = hdr
 sky,imn,sky,skyerr
 imn = imn - sky
 imtot = imn
 exptime = sxpar(hdr,'EXPTIME')
 tstop = sxpar(hdr,'OBSTIME')
 weight[*,*] = exptime
 totexptime = exptime
 tot_satlvl = sref.sexsatlv - sky - 2*skyerr
;; endif

;; Now, add up the coadded image.  Subtract sky from each image so all regions
;; are on the same footing. Then map to the original frame and add the warped image

 ncoadd=totobs
 for k=1,totobs-1 do begin
     cnew = mrdfits(cobjnames[k],1)
     snew = mrdfits(cobjnames[k],2)

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
         print,'Not adding this image'
         ncoadd=ncoadd-1
     endif else begin        
         imn = r_readfits(imagenames[k], hdr)

         nnx=(size(imn))[1]
         nny=(size(imn))[2]
         
         if ((nnx ne nx) or (nny ne ny)) then begin
             print,'Cannot add frame with different size.'
             print,'Not adding this image.'
             ncoadd=ncoadd-1
         endif else begin

             sky, imn, sky, skyerr
             imn = imn - sky
             exptime = sxpar(hdr, 'EXPTIME')
             tstop = sxpar(hdr,'OBSTIME')
             wn = imn    ;; this is inefficient
             wn[*,*] = exptime
             totexptime = totexptime + exptime
             tot_satlvl = tot_satlvl + (snew.sexsatlv - sky - skyerr)
             
             print,'  Adding frame: ',imagenames[k]
             nl = fix(nobj*0.1)
             nh = fix(nobj*0.5)
             polywarp,cnew[gdnew[[m2[nl:nh]]]].x,cnew[gdnew[[m2[nl:nh]]]].y, $
               cref[gdref[[m1[nl:nh]]]].x,cref[gdref[[m1[nl:nh]]]].y, 2, kx, ky
             imn = poly_2d(imn, kx, ky, 2, missing=0.0, cubic=-0.5)
             wn = poly_2d(wn, kx, ky, 2, missing=0.0, cubic=-0.5)
             imtot = imtot + imn
             weight = weight + wn
         endelse
     endelse
 endfor

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
 sxaddpar,imhdr,'EXPTIME',totexptime
 sxaddpar,imhdr,'SATCNTS',tot_satlvl
 sxaddpar,imhdr,'NCOADD',ncoadd
 sxaddpar,imhdr,'FILENAME',outname
 tstart = sxpar(imhdr,'OBSTIME')
 if tstop lt tstart then tstop=tstop+3600d0*24d0
 efftime = tstop + exptime - tstart
 sxaddpar,imhdr,'EFFTIME',efftime
;; lowest=min(imtot)
;; highest=max(imtot)
;; bscale = (highest - lowest)/65535.0
;;bzero = 0.5*(highest + lowest + bscale)
;; sxaddpar,imhdr,'BZERO',bzero
;; sxaddpar,imhdr,'BSCALE',bscale
;; new_im=fix(round(imtot-bzero)/bscale)
;; writefits, outname, new_im, imhdr
 writefits,outname,imtot,imhdr
 
 coaddname=outname

return
end
