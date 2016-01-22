pro ss_coadd_new,newfiles,coadddir=coadddir,coadd_list=coadd_list,badmap=badmap

if n_params() eq 0 then begin
  print,'syntax- ss_coadd_new,newfiles,coadddir=coadddir,coadd_list=coadd_list,badmap=badmap'
  return
endif

extract_par='/products/idltools/umrotse_idl/tools/sex/'
extract_config='/products/idltools/umrotse_idl/tools/sex/'

frac=0.75

n_new=n_elements(newfiles)
if newfiles[0] ne "nothing" and n_new ge 2 then begin
    newfiles=newfiles(sort(newfiles))

    dirparts=strsplit(newfiles[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    basename = parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,2)

    ;find the "good images"
    nobj=lonarr(n_new)
    itimes=fltarr(n_new)
    fwhms=fltarr(n_new)
    for i=0,n_new-1 do begin
        c=mrdfits(newfiles[i],2,/silent)
        nobj[i]=c.sexnfin
        itimes[i]=c.mjd
        fwhms[i]=c.fwhm
    endfor    
    maxn=max(nobj)
    tst=where(fwhms gt 0,ntst)
    if ntst gt 0 then minfwhm=min(fwhms[tst]) else minfwhm=min(fwhms)
    good=where(nobj ge maxn*frac and fwhms ge minfwhm and fwhms le 1.5*minfwhm,ngood)

    if ngood ge 2 then begin
        newfiles=newfiles[good]
        nobj=nobj[good]
        itimes=itimes[good]
        n_new=n_elements(newfiles)
    endif else begin
        maxn=(nobj[reverse(sort(nobj))])[1]
        good=where(nobj ge maxn,ngood)
        newfiles=newfiles[good]
        nobj=nobj[good]
        itimes=itimes[good]
        n_new=n_elements(newfiles)
    endelse

    ;check if the images are taken for two epochs.
    ;if yes, coadd both epochs.
    ;if no, but there are more than 2 images, devide.
    n_first=0
    if n_new ge 8 then begin
        n_first=n_new/2

    endif else begin
        if n_new ge 2 then begin
            ftime=itimes[0]
            i=1
            while i lt n_new and n_first eq 0 do begin
                nexttime=itimes[i]
                if nexttime-ftime ge 0.5/24. then n_first=i
                ftime=nexttime
                i=i+1
            endwhile  
            if n_first eq 0 then n_first=ceil(n_new/2)
        endif       
    endelse
    
     
    if n_elements(coadd_list) eq 1 and (n_new ge 2 and n_first gt 0 and n_first lt n_new) then begin
        
        first_ep=lindgen(n_first)
        second_ep=lindgen(n_new-n_first)+n_first        

        firstfiles=newfiles[first_ep]
        secondfiles=newfiles[second_ep]
        
        skyname=strarr(3)
        conf=replicate({sobjdir:'',root:'',cimg:'',sobj:'',cobj:''},3)
        conf.sobjdir=coadddir+'/prod/'
       
        for ind=0,2 do begin
            coaddname=basename+'000-00'+string(ind,format='(i1)')
            conf[ind].root=coaddname
            conf[ind].cimg=coadddir+'/image/'+coaddname+'_c.fit' 
            conf[ind].sobj=coadddir+'/prod/'+coaddname+'_sobj.fit'
            conf[ind].cobj=coadddir+'/prod/'+coaddname+'_cobj.fit'
            skyname[ind]=coadddir+'/prod/'+coaddname+'_sky.fit'
        endfor        
        
        if n_elements(badmap) eq 1 then begin
            badpixmap=readfits(badmap)
            print,'start coadding:',firstfiles
            ss_coadd_rotse3_filter,firstfiles,coaddname=coadddir+'/image/'+conf[1].root,badmap=badpixmap
            print,'start coadding:',secondfiles
            ss_coadd_rotse3_filter,secondfiles,coaddname=coadddir+'/image/'+conf[2].root,badmap=badpixmap
            print,'start coadding all...'
            ss_coadd_rotse3_filter,newfiles,coaddname=coadddir+'/image/'+conf[0].root,badmap=badpixmap
            
        endif else begin
            print,'start coadding:',firstfiles
            ss_coadd_rotse3_filter,firstfiles,coaddname=coadddir+'/image/'+conf[1].root
            print,'start coadding:',secondfiles
            ss_coadd_rotse3_filter,secondfiles,coaddname=coadddir+'/image/'+conf[2].root
            print,'start coadding all...'
            ss_coadd_rotse3_filter,newfiles,coaddname=coadddir+'/image/'+conf[0].root
        endelse

        for ind=0,2 do begin
            chdr=headfits(conf[ind].cimg)
            satlev=sxpar(chdr,'SATCNTS')
            satlevel=strtrim(string(long(satlev)),2)
;process the coadded images using sextractor
            cmd='sex '+conf[ind].cimg+' -c '+extract_par+'/rotse3.sex -PARAMETERS_NAME '+extract_par+'/rotse3.par -FILTER_NAME '+extract_config+'/gauss_2.0_5x5.conv -PHOT_APERTURES 7 -SATUR_LEVEL '+satlevel+' -CATALOG_NAME '+conf[ind].sobj+' -CHECKIMAGE_NAME '+skyname[ind]
            spawn,cmd
            
;calibrate the sobjlist
            print,'Beginning sobjfile '+conf[ind].sobj
            sobj=mrdfits(conf[ind].sobj,1,/silent)
            rotse_iii_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0]
            if fail then rotse_iii_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0],skip=1

            if (not fail) then begin
                write_cobj, conf[ind], ustat, ucal, chdr

                print, 'Sobjfile '+conf[ind].sobj+' finished.'

                cmd = "chmod 666 " + coadddir+'/*/'+conf[ind].root+'*'
                spawn,cmd
                
                ss_addto_list,conf[ind].cobj,coadd_list

            endif else begin
                print, 'Catalog match failed.'
                cmd = "chmod 666 " + coadddir+'/*/'+conf[ind].root+'*'
                spawn,cmd

            endelse    
        endfor
    endif else begin
        print,'no coadding.'
    endelse
    
endif else begin
    if newfiles[0] ne "nothing" then print,'less than 2 new sky images found:',newfiles
endelse

end

