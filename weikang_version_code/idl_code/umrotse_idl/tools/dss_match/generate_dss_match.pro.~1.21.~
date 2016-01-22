pro generate_dss_match,basedir,dssjpeglist,nodssjpeglist,imdir=imdir,cobjdir=cobjdir,tilesize=tilesize,ctilesize=ctilesize,minobs=minobs

if n_params() lt 2 then begin
    print,'syntax- generate_dss_match,basedir,dssjpeglist,nodssjpeglist,imdir=imdir,cobjdir=cobjdir,tilesize=tilesize,ctilesize=ctilesize,minobs=minobs'
    return
endif

cd,basedir

if n_elements(imdir) eq 0 then imdir = 'image/'
if n_elements(cobjdir) eq 0 then cobjdir = 'prod/'
if n_elements(tilesize) eq 0 then tilesize = 0.07   ;; might want to modify
if n_elements(ctilesize) eq 0 then ctilesize = 3./60. ;; central tile, 50%
if n_elements(minobs) eq 0 then minobs = 2

;; find the images to process for dss
imagesfordss = findfile(imdir + '*_3?*-*_c.fit', count=numfilesfordss)

;; find the images to prpcess not for dss matching (non-coadds)
imagesnotfordss = findfile(imdir + '*_3[abcd]???_c.fit', count=numfilesnotfordss)

;; and cobjs for matching
cobjsformatch = findfile(cobjdir + '*3?*-*_cobj.fit', count=numcobjsformatch)


;; we start out by generating the match structure...

ismatch = 0
if (numcobjsformatch ge 2) then begin
    ;; need at least two to match
    
    ;; first check if there's a match structure...
    dirparts=strsplit(cobjsformatch[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    mtname=parts[1] + '_' + strmid(parts[2],0,2)+'_match.fit'

    mparts=strsplit(parts[1],'-',/extract)

    mtpngbase = mparts[0] + '_' + strmid(parts[2],0,2)

    test=findfile(mtname,count=ct)
    if (ct gt 0) then begin
        ;; already have one
        mt=mrdfits(mtname,1)
        st=mrdfits(mtname,2)

        regmatch3_list,mt,st,namelist=cobjsformatch,/save,/append,/over

    endif else begin
        ;; need to create one
        regmatch3_list,mt,st,namelist=cobjsformatch,/save
    endelse

    ;; want times for plot
    if (st[0].trig_tjd gt 10000) then begin
        burst_mjd=double(st[0].trig_tjd) + 40000.0d + st[0].trig_t / (60d*60d*24d)
    endif else begin
        burst_mjd = double(floor(st[0].mjd)) + st[0].trig_t / (60d*60d*24d)
    endelse
    
    allobs=indgen(mt.nobs)

    stimes = (mt.jd[allobs] - burst_mjd) * 24d * 60d * 60d
    dtimes = st[allobs].efftime   ;; effective time = delta_t (seconds)
;;    mlims = mt.m_lim[allobs]
    mlims=st[allobs].m_lim

    ismatch = 1
    datinds=[-1l]

    ;; read in a datfile if we can
    dssdatname = basedir + '/' + mtpngbase + '_dss.dat'

    openr,drlun,dssdatname,/get_lun,error=err
    if (err eq 0) then begin
        ;; there's a file to read in
        line=''                        
        ;; read in the first (starttime) line
        readf,drlun,line
        ;; and the second (endtime) line
        readf,drlun,line

        ;; now, read in the rest
        while (not eof(drlun)) do begin
            readf,drlun,line
            lparts=strsplit(line,' ',/extract)
            index=long(strmid(lparts[0],1,strlen(lparts[0])-1))
            datinds=[datinds,index]
        endwhile
        
        free_lun,drlun
    endif
endif

if (numfilesfordss eq 0) then begin
    print,'No files for dss matching'
endif else begin
    print,'found ',numfilesfordss,' files'

    initialized = 0
    dss_available = 1

    for i=0l,numfilesfordss-1 do begin
        dirparts=strsplit(imagesfordss[i],'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)

        if (stregex(parts[1],'^fup\-') ne -1) then begin
            ;; this is a fup-- so not as simple
            subparts=strsplit(parts[1],'-',/extract)
            usepart = subparts[0] + '-' + subparts[1]
        endif else begin
            subparts = strsplit(parts[1],'-',/extract)
            usepart = subparts[0]
        endelse

        jpgbasename = usepart + '_' + parts[2]

        date=parts[0]
        if n_elements(parts) eq 3 then begin
            print,'not supported'
            return
        endif
        fbase = parts[0] + '_' + parts[1] + '_' + parts[2]
        imname = fbase + '_c.fit'
        cobjname = fbase + '_cobj.fit'

        test=findfile(basedir + '/' + jpgbasename + '*.jpg',count=tct)
        if (tct eq 0) then begin
            ;; there are no jpegs, we should continue
            if (not initialized) then begin
                ;; we need to figure out the ra/dec of the trigger, the dss image
                ;; information, etc, etc

                hdr=headfits(imagesfordss[i])
                trig_ra = sxpar(hdr,'TRIG_RA')
                trig_dec = sxpar(hdr,'TRIG_DEC')
                trig_err = sxpar(hdr,'TRIG_ERR')

                ;; need to check the radius
                if (trig_err gt 0.2) then begin
                    print,'Error box too large: searching central portion'
                    trig_err = 0.2
                endif
                if (trig_err lt 0.05) then begin
                    print,'error box very small: searching larger area'
                    trig_err=0.05
                endif

                ;; download the dss image (if necessary)
                fail = 0
                download_dss_rotse,trig_ra,trig_dec,trig_err*1.2, $
                  dss_image=dss_image,dss_hdr=dss_hdr,fail=fail;;,date=date

                if (fail eq 1) then begin
                    print,'Failed to download/find DSS image'
                    dss_available = 0
                endif

                ;; download the usno-b catalog (if necessary)
                usnoreadb,trig_ra,trig_dec,trig_err*1.2,ubcat,/save

                openw,jlun,dssjpeglist,/get_lun

                initialized = 1
            endif

            skip = 0
            if (not dss_available) then begin
                ;; skip them all
                skip = 1
            endif else begin
                full_image_name=find_rotse3_image(imname,path=['.',imdir],fail=fail)
                if (fail eq 1) then begin
                    print,'Could not find image: '+imname
                    skip = 1
                endif
                
                full_cobj_name = find_rotse3_cobj(cobjname,path=['.',cobjdir],fail=fail)
                if (fail eq 1) then begin
                    print,'Could not find cobj: '+cobjname
                    skip = 1
                endif 
            endelse

            if (skip eq 0) then begin
                im=readfits(full_image_name,im_hdr)
                cobj = mrdfits(full_cobj_name,1)
                cal = mrdfits(full_cobj_name,2)
                ;; now we prepare the tiling
                ntilesize=tilesize
                calculate_subimage_tiling,trig_ra,trig_dec,trig_err,ntilesize,cal,im_hdr,ratiles,dectiles
                nratiles = n_elements(ratiles)
                ndectiles = n_elements(dectiles)
                
                ;; prepare the tiles -- extra center tile
                ntiles = nratiles * ndectiles
                if (ntiles gt 1) then ntiles = ntiles + 1
                tile_ras = fltarr(ntiles)
                tile_decs = tile_ras
                tile_sizes = tile_ras
                errads = tile_ras
                if (ntiles gt 1) then begin
                    tile_ras[0] = trig_ra
                    tile_decs[0] = trig_dec
                    tile_sizes[0] = ctilesize
                    errads[0] = (1.25/60.)/0.0009d
                    ctr = 1
                    for j=0l,nratiles-1 do begin
                        for k=0l,ndectiles-1 do begin
                            tile_ras[ctr] = ratiles[j]
                            tile_decs[ctr] = dectiles[k]
                            tile_sizes[ctr] = ntilesize
                            errads[ctr] = 0
                            ctr=ctr+1
                        endfor
                    endfor

                endif else begin
                    ;; it all fits in one tile
                    tile_ras[0] = ratiles[0]
                    tile_decs[0] = dectiles[0]
                    tile_sizes[0] = ntilesize
                    errads[0] = (1.25/60.)/0.0009d
                endelse
                

                ;; now, we need to plot either cobj _or_ match guys
                mind = -1
                if (ismatch) then begin
                    ;; find where in the match structure it is
                    j=mt.nobs-1
                    while (j ge 0) do begin
                        test=strpos(mt.imagename[j],fbase)
                        if (test ne -1) then begin
                            mind = j
                            j=0
                        endif
                        j=j-1
                    endwhile
                    
                    if (mind eq -1) then begin
                        print,'Ouch!  Observation not in match structure?'
                    endif else begin
                        cind=where(mt.m[mind,*] gt 0,ncind)
                        if (ncind eq 0) then begin
                            print,'No objects in this observation???'
                            mind = -1
                        endif else begin
                            cra=mt.ra[cind]
                            cdec=mt.dec[cind]
                        endelse
                    endelse
                endif

                if (mind eq -1) then begin
                    cra=cobj.ra
                    cdec=cobj.dec
                    cind=lindgen(n_elements(cra))
                endif
                
                ;; match the catalog to our stars
                close_match_radec,cra,cdec,ubcat.raj2000,ubcat.dej2000, $
                  m1,m2,0.0009d,1,miss                             

                printf,jlun,ntiles
                printf,jlun,cal.m_lim

                for ctr=0l,ntiles-1 do begin

                    this_ra = tile_ras[ctr]
                    this_dec = tile_decs[ctr]
                    ntilesize = tile_sizes[ctr]
                    errad = errads[ctr]

                    imjpgname = basedir + '/' + jpgbasename + '_i' + $
                      string(ctr,format='(i2.2)') + '.jpg'
                    djpgname = basedir + '/' + jpgbasename + '_d' + $
                      string(ctr,format='(i2.2)') + '.jpg'

                    num=cind[miss]
                    
;;                    if (ctr eq 0) then nolabel = 0 else nolabel = 1
                    nolabel = 0

                    radec_circle_new,cal,this_ra,this_dec,image=im, $
                      box=ntilesize,/finding,radius=5,errad=errad, $
                      rarr1=cra[m1],darr1=cdec[m1], $
                      rarr2=cra[miss],darr2=cdec[miss],number2=num, $
                      jpegname=imjpgname,dim=[500,500],nolabel=nolabel,/alternum


                    plot_dss_image,dss_image,dss_hdr,this_ra,this_dec, $
                      box=ntilesize,radius=10,errad=0, $
                      rarr1=cra[m1],darr1=cdec[m1], $
                      rarr2=cra[miss],darr2=cdec[miss], $
                      rarr3=ubcat.raj2000,darr3=ubcat.dej2000, $
                      jpegname=djpgname,dim=[500,500],/nolabel
               
                    ;; now output a little data file
                    datname = basedir + '/' + jpgbasename + '_i' + $
                      string(ctr,format='(i2.2)') + '.dat'
                    openw,lun,datname,/get_lun
                    if (num[0] eq -1) then begin
                        printf,lun,'0'
                    endif else begin
                        printf,lun,n_elements(num)
                        for l=0l,n_elements(num)-1 do begin
                            if (mind ne -1) then begin
                                thisra=mt.ra[num[l]]
                                thisdec=mt.dec[num[l]]
                                thismag=mt.m[mind,num[l]]
                            endif else begin
                                thisra=cobj[num[l]].ra
                                thisdec=cobj[num[l]].dec
                                thismag=cobj[num[l]].m
                            endelse

                            rabits=sixty(thisra/15.)
                            rastr = string(fix(rabits[0]),format='(i2.2)') + ':' + $
                              string(fix(rabits[1]),format='(i2.2)') + ':' + $
                              string(fix(rabits[2]),format='(i2.2)') + '.' + $
                              string(fix((rabits[2] - fix(rabits[2]))*100),format='(i2.2)')
                            
                            decbits=sixty(abs(thisdec))
                            if (thisdec lt 0) then sign = '-' else sign = '+'
                            decstr = sign + string(fix(decbits[0]),format='(i2.2)') + ':' + $
                              string(fix(decbits[1]),format='(i2.2)') + ':' + $
                              string(fix(decbits[2]),format='(i2.2)') + '.' + $
                              string(fix((decbits[2] - fix(decbits[2]))*100),format='(i2.2)')
                            
                            ;; need to add on # found
                            if (mind eq -1) then begin
                                nfstr='01/01';
                            endif else begin
                                inim=where(mt.m[*,num[l]] gt 0,nin)
                                nfstr=string(nin,format='(i2.2)') + '/' + $
                                  string(mt.nobs,format='(i2.2)')

                                ;; and here is where we generate a png
                                ;; lightcurve
;;                                if (nin ge minobs) then begin
                                    pngname = mtpngbase + '_' + $
                                      string(num[l],format='(i5.5)') + '_lc.png'
                                    mags=mt.m[allobs,num[l]]
                                    magerrs=mt.merr[allobs,num[l]]
                                    notin=where(mags lt 0,nnot)
                                    if (nnot gt 0) then $
                                      mags[notin] = mlims[notin]
;;                                      mags[notin] = mt.m_lim[notin]
                                    

                                    simple_lc_png,pngname,stimes,mags,magerrs
;;                                endif
                                
                            endelse

                            if (ismatch) then begin
                                numstr = 'd' + strcompress(string(num[l],format='(i6)'),/remove_all)
                            endif else begin
                                numstr = 's' + strcompress(string(num[l],format='(i6)'),/remove_all)
                            endelse

                            printf,lun,numstr+ ' ' + $
                              string(thisra,format='(f9.5)') + ' ' + $
                              string(thisdec,format='(f9.5)') + ' ' + $
                              rastr + ' ' + decstr + ' ' + $
                              string(thismag,format='(f5.2)') + ' ' + $
                              nfstr
                            
                            ;; add on the index for output to the big file
                            if (ismatch) then begin
                                datinds = [datinds,num[l]]
                            endif

                            
                        endfor
                    endelse
                    free_lun,lun

                    
                    ;; and write out that we've made an image
                    printf,jlun,imjpgname                              
                endfor

                ;; we want to write out an overall "key" image as well
                ;; right now, without tile outlines.
                keyjpgname = basedir + '/' + jpgbasename + '_key.jpg'
                num=cind[miss]
                
                radec_circle_new,cal,trig_ra,trig_dec,image=im, $
                  box=trig_err*2.,/finding,radius=5,errad=trig_err/0.0009d, $
                  rarr1=cra[m1],darr1=cdec[m1], $
                  rarr2=cra[miss],darr2=cdec[miss], $
                  jpegname=keyjpgname,dim=[800,800],number2=num

            endif 
        endif else print,"there are jpegs already"
    endfor

    if (initialized) then free_lun,jlun
endelse ;; numfilesfordss


;; now output the big dat file
if (ismatch and (n_elements(datinds) gt 1)) then begin
    ;; okay, get the indices ready -- get rid of duplicates, etc
    inds=datinds[1:n_elements(datinds)-1]

    s=sort(inds)
    inds=inds[s]
    inds=inds[uniq(inds)]

    ;; now, rewrite the file
    openw,dwlun,dssdatname,/get_lun
    stline=''
    dtline=''
    lline=''
    for k=0l,n_elements(stimes)-1 do begin
        stline=stline+string(stimes[k],format='(f8.1)')+' '
        dtline=dtline+string(dtimes[k],format='(f8.1)')+' '
        lline=lline+string(mlims[k],format='(f7.2)')+' '
    endfor
    printf,dwlun,stline
    printf,dwlun,dtline
    printf,dwlun,lline
    
    for i=0l,n_elements(inds)-1 do begin
        thisra=mt.ra[inds[i]]
        thisdec=mt.dec[inds[i]]
        
        rabits=sixty(thisra/15.)
        rastr = string(fix(rabits[0]),format='(i2.2)') + ':' + $
          string(fix(rabits[1]),format='(i2.2)') + ':' + $
          string(fix(rabits[2]),format='(i2.2)') + '.' + $
          string(fix((rabits[2] - fix(rabits[2]))*100),format='(i2.2)')
        
        decbits=sixty(abs(thisdec))
        if (thisdec lt 0) then sign = '-' else sign = '+'
        decstr = sign + string(fix(decbits[0]),format='(i2.2)') + ':' + $
          string(fix(decbits[1]),format='(i2.2)') + ':' + $
          string(fix(decbits[2]),format='(i2.2)') + '.' + $
          string(fix((decbits[2] - fix(decbits[2]))*100),format='(i2.2)')

        line='d' + strcompress(string(inds[i],format='(i6)'),/remove_all)+' '+$
          string(thisra,format='(f10.6)') + ' ' + $
          string(thisdec,format='(f10.6)') + ' ' + $
          rastr+' ' + decstr

        for k=0l,n_elements(allobs)-1 do begin
            line = line + ' ' + string(mt.m[allobs[k],inds[i]],format='(f7.3)') + ' ' + $
              string(mt.merr[allobs[k],inds[i]],format='(f7.3)')
        endfor

        printf,dwlun,line
    endfor

    free_lun,dwlun
endif


;; now work with the ones not for dss
if (numfilesnotfordss gt 0) then begin
    print,'Found ',numfilesnotfordss,' files not for dss'
    initialized = 0
    
    for i=0l,numfilesnotfordss-1 do begin
        dirparts=strsplit(imagesnotfordss[i],'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)

        if n_elements(parts) eq 3 then begin
            print,'Not supported'
            return
        endif

        fbase = parts[0] + '_' + parts[1] + '_' + parts[2]
        imname = fbase + '_c.fit'
        cobjname = fbase + '_cobj.fit'
        jpegname = fbase + '.jpg'
        
        test=findfile(basedir+'/'+jpegname,count=tct)
        if (tct eq 0) then begin
            ;; it hasn't already been made, continue...
            if (not initialized) then begin
                openw,jlun,nodssjpeglist,/get_lun
                initialized = 1
            endif

            hdr=headfits(imagesnotfordss[i])
            rac=sxpar(hdr,'SUB_RA',count=racct)
            decc=sxpar(hdr,'SUB_DEC',count=decct)
            rad=sxpar(hdr,'SUB_RAD',count=rct)
            trig_ra = sxpar(hdr,'TRIG_RA')
            trig_dec = sxpar(hdr,'TRIG_DEC')
            trig_err = sxpar(hdr,'TRIG_ERR')
            
            ;; just in case (though should be upgraded)
            if (racct eq 0 or decct eq 0 or rct eq 0) then begin
                rac = trig_ra
                decc = trig_dec
                rad = 1.4 * trig_err
            endif
               
            skip=0
            full_image_name=find_rotse3_image(imname,path=['.',imdir],fail=fail)
            if (fail eq 1) then begin
                ;; shocking, since we just had it!  (but just in case)
                print,'could not find image: '+imname
                skip = 1
            endif

            full_cobj_name=find_rotse3_cobj(cobjname,path=['.',cobjdir],fail=fail)
            if (fail eq 1) then begin
                print,'could not find cobj: '+cobjname
                skip = 1
            endif

            if (skip eq 0) then begin
                im=readfits(full_image_name)
                cal = mrdfits(full_cobj_name,2)

                radec_circle_new,cal,rac,decc,image=im,/finding,box=2*rad, $
                  jpegname=jpegname,errad=0,rarr1=trig_ra,darr1=trig_dec,$
                  radius = trig_err / 0.0009d
                
                ;; and write to the lun
                printf,jlun,jpegname
            endif

        endif else begin
            print,'There is a jpeg already'
        endelse

    endfor

    if (initialized) then free_lun,jlun

endif


return
end
