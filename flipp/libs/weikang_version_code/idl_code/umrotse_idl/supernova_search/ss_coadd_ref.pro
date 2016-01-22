pro ss_coadd_ref,newfiles,refdir=refdir,reflist=reflist,badmap=badmap

if n_params() eq 0 then begin
  print,'syntax- ss_coadd_ref,newfiles,refdir=refdir,reflist=reflist,badmap=badmap'
  return
endif

extract_par='/products/idltools/umrotse_idl/tools/sex/'
extract_config='/products/idltools/umrotse_idl/tools/sex/'

frac=0.75

n_new=n_elements(newfiles)
if newfiles[0] ne "nothing" then begin
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

    if ngood ge 1 then begin
        newfiles=newfiles[good]
        nobj=nobj[good]
        itimes=itimes[good]
        n_new=n_elements(newfiles)
    endif else begin
        maxn=(nobj[reverse(sort(nobj))])[0]
        good=where(nobj ge maxn,ngood)
        newfiles=newfiles[good]
        nobj=nobj[good]
        itimes=itimes[good]
        n_new=n_elements(newfiles)
    endelse

    if n_new ge 1 then begin
        skyname=''
        conf={sobjdir:'',root:'',cimg:'',sobj:'',cobj:''}
        conf.sobjdir=refdir+'/prod/'

        dirparts1=strsplit(newfiles[0],'/',/extract)
        parts1=strsplit(dirparts1[n_elements(dirparts1)-1],'_',/extract)
        dirparts2=strsplit(newfiles[n_new-1],'/',/extract)
        parts2=strsplit(dirparts2[n_elements(dirparts2)-1],'_',/extract)
        
        coaddname=basename+strmid(parts1[2],2,3)+'-'+strmid(parts2[2],2,3)
        conf.root=coaddname
        conf.cimg=refdir+'/image/'+coaddname+'_c.fit' 
        conf.sobj=refdir+'/prod/'+coaddname+'_sobj.fit'
        conf.cobj=refdir+'/prod/'+coaddname+'_cobj.fit'
        skyname=refdir+'/prod/'+coaddname+'_sky.fit'
                
        
        if n_elements(badmap) eq 1 then begin
            print,'start coadding all...'
            ss_coadd_rotse3_filter,newfiles,coaddname=refdir+'/image/'+conf[0].root,badmap=badpixmap
        endif else begin
            print,'start coadding all...'
            ss_coadd_rotse3_filter,newfiles,coaddname=refdir+'/image/'+conf[0].root
        endelse
        
        
        chdr=headfits(conf.cimg)
        satlev=sxpar(chdr,'SATCNTS')
        satlevel=strtrim(string(long(satlev)),2)
;process the coadded images using sextractor
        cmd='sex '+conf.cimg+' -c '+extract_par+'/rotse3.sex -PARAMETERS_NAME '+extract_par+'/rotse3.par -FILTER_NAME '+extract_config+'/gauss_2.0_5x5.conv -PHOT_APERTURES 7 -SATUR_LEVEL '+satlevel+' -CATALOG_NAME '+conf.sobj+' -CHECKIMAGE_NAME '+skyname
        spawn,cmd
        
;calibrate the sobjlist
        print,'Beginning sobjfile '+conf.sobj
        sobj=mrdfits(conf.sobj,1,/silent)
        rotse_iii_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0]
        if fail then rotse_iii_usno_cal,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0],skip=1

        if (not fail) then begin
            write_cobj, conf, ustat, ucal, chdr
            
            print, 'Sobjfile '+conf.sobj+' finished.'
            
            cmd = "chmod 666 " + refdir+'/*/'+conf.root+'*'
            spawn,cmd
                
            ss_addto_reflist,conf.cimg,reflist,/replaceold
            
        endif else begin
            print, 'Catalog match failed.'
            cmd = "chmod 666 " + refdir+'/*/'+conf.root+'*'
            spawn,cmd
        endelse    
    endif else begin
        print,'no coadding.'
    endelse
    
endif

end

