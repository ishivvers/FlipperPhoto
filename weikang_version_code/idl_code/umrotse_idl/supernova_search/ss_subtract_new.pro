pro ss_subtract_new,newcoadds,subdir=subdir,subs_list=subs_list,reflist=reflist,refdir=refdir,badmap=badmap,subsize=subsize,psfscale=psfscale,skysize=skysize,local=local

if n_params() eq 0 then begin
    print,'syntax - ss_subtract_new,newcoadds,subdir=subdir,subs_list=subs_list,reflist=reflist,refdir=refdir,badmap=badmap,subsize=subsize,psfscale=psfscale,skysize=skysize,local=local'
    return
endif


extract_par='/products/idltools/umrotse_idl/tools/sex/'
extract_config='/products/idltools/umrotse_idl/tools/sex/'

const_weight=1.0
if n_elements(subsize) eq 0 then subsize=300l
if n_elements(pixscale) eq 0 then pixscale=0.0009d

ready_for_subtraction=0
newcoadds=newcoadds[sort(newcoadds)]
if newcoadds[0] ne "nothing" then begin

    print,'processing image:',newcoadds
    ready_for_subtraction=1
    
    n_new=n_elements(newcoadds)
    newfiles=strarr(2,n_new)

    for ind=0,n_new-1 do begin
        newfiles[*,ind]=ss_find_image_cobj(newcoadds[ind],fail=fail)
        if fail eq 1 then begin
            print,'missing coadded files...'
            ready_for_subtraction=0
        endif
    endfor
endif

if ready_for_subtraction eq 1 then begin

    reffiles=ss_find_ref_files(newfiles[0,0],reflist=reflist,refdir=refdir,fail=fail)
        
    if fail eq 0 then begin
           
        print,"reference:",reffiles[0]
            
    endif else begin
        ready_for_subtraction=0            
        print,'no reference found.'
    endelse
endif 

if ready_for_subtraction eq 1 then begin
    
    refim=readfits(reffiles[0],refhdr,/silent)
    refcobj=mrdfits(reffiles[1],1,/silent)
    refstat=mrdfits(reffiles[1],2,/silent)
    w_image=(size(refim))[1]
    h_image=(size(refim))[2]

    if n_elements(badmap) eq 1 then begin
        badpixmap=readfits(badmap)
        refim=ss_rm_badpix(refim,badpixmap)
    endif
    
    warpfail=0
    for ind=0,n_new-1 do begin
        newim=readfits(newfiles[0,ind],newhdr,/silent)
        newcobj=mrdfits(newfiles[1,ind],1,/silent)
        newstat=mrdfits(newfiles[1,ind],2,/silent)

        if n_elements(badmap) eq 1 then newim=ss_rm_badpix(newim,badpixmap)

;warp the new image
        if warpfail eq 0 then newim=ss_warp(temporary(newim),refcobj,newcobj,kx=kx,ky=ky,fail=warpfail)
        
        if warpfail eq 0 then begin
            n_convolve=9l
            satcnts1=sxpar(refhdr,'SATCNTS')
            satcnts2=sxpar(newhdr,'SATCNTS')
            if tag_exist(refstat,'fwhm') then fwhm1=refstat.fwhm $
            else fwhm1=ss_get_fwhm(refcobj)
            if tag_exist(newstat,'fwhm') then fwhm2=newstat.fwhm $
            else fwhm2=ss_get_fwhm(newcobj)
            minmag=((newstat.m_lim-4.0)<13.)>12.
            maxmag=(newstat.m_lim-1.5)>(16.<(newstat.m_lim-0.5))
            zeropoint1=23.+refstat.zp_offset
            zeropoint2=23.+newstat.zp_offset
            ronoise1=sxpar(refhdr,'BSTDDEV')
            ronoise2=sxpar(newhdr,'BSTDDEV')

            gd2=where(newcobj.flags le 2 and newcobj.m ge minmag and newcobj.m le maxmag,ngd2)  
            while (ngd2 lt 600) and (maxmag lt newstat.m_lim-0.3) do begin
                maxmag=maxmag+0.2
                gd2=where(newcobj.flags le 2 and newcobj.m ge minmag and newcobj.m le maxmag,ngd2)
            endwhile
            if (ngd2 lt 200) then begin
                print,'WARNING: Not enough good new stars.  Using them all.',ngd2
                gd2=lindgen(n_elements(newcobj))
            endif
            print,'minmag, maxmag, mlim:',minmag,maxmag,newstat.m_lim 
            gd1=where(refcobj.flags le 2 and refcobj.m ge minmag and refcobj.m le maxmag,ngd1)    
            if (ngd1 lt 200) then begin
                print,'WARNING: Not enough good ref stars.  Using them all.',ngd1
                gd1=lindgen(n_elements(refcobj))
            endif

            close_match_radec,refcobj[gd1].ra,refcobj[gd1].dec,newcobj[gd2].ra,newcobj[gd2].dec,match1,match2,pixscale,1
            nmatch=n_elements(match1)
            nsub=(floor(w_image/subsize)>1)*(floor(h_image/subsize)>1)
            if nmatch/nsub lt 8. then begin
                nsub=nmatch/8.
                nsubsize=(w_image+h_image)/2./(floor(sqrt(nsub))>1)
                nsubsize=floor(nsubsize)<500
                print,'using subsize:',nsubsize
            endif else nsubsize=subsize

            if keyword_set(psfscale) then begin
                ss_scale_new_psf,refim,newim,refcobj[gd1[match1]],newcobj[gd2[match2]],fwhm1,fwhm2,satcnts1,satcnts2,zeropoint1,zeropoint2,ronoise1,ronoise2,kx=kx,ky=ky,subsize=nsubsize,fail=sfail
                if sfail then begin
                    print,'psfscaling failed...'
                    mask=ss_make_mask(refim,newim,satcnts1,satcnts2,refcobj,newcobj,fwhm1,fwhm2,zeropoint1,zeropoint2,gd1[match1],gd2[match2],n_convolve=n_convolve,/match,satmask=satmask,/scalenew,subsize=nsubsize)
                endif else begin
                    mask=ss_make_mask(refim,newim,satcnts1,satcnts2,refcobj,newcobj,fwhm1,fwhm2,zeropoint1,zeropoint2,gd1[match1],gd2[match2],n_convolve=n_convolve,/match,satmask=satmask,subsize=nsubsize)
                endelse
            endif else begin
                sfail=1
                mask=ss_make_mask(refim,newim,satcnts1,satcnts2,refcobj,newcobj,fwhm1,fwhm2,zeropoint1,zeropoint2,gd1[match1],gd2[match2],n_convolve=n_convolve,/match,satmask=satmask,/scalenew,subsize=nsubsize)
            endelse
            
            diff=newim-refim
            diff=ss_get_sky(diff,mashsize=32,satmask=satmask)
            newim=newim-diff
            
;determine the name of the subtracted image and proper header
            dirparts=strsplit(newfiles[0,ind],'/',/extract)
            parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
            if strmatch(parts[2],'*000-*') and (not keyword_set(local)) then $
              subname=parts[0]+'_'+parts[1]+'_'+repstr(parts[2],'000-','111-') $
            else subname=parts[0]+'_'+parts[1]+'_'+parts[2]+'-sub'
            subimname=subname+'_c.fit'
            sobjname=subname+'_sobj.fit'
            skyname=subname+'_sky.fit'
            subhdr=refhdr
            mjd=sxpar(newhdr,'MJD')
            sxaddpar,subhdr,'MJD',mjd
            exptime=sxpar(newhdr,'EXPTIME')
            sxaddpar,subhdr,'EXPTIME',exptime
            efftime=sxpar(newhdr,'EFFTIME')
            sxaddpar,subhdr,'EFFTIME',efftime
            dateobs=sxpar(newhdr,'DATE-OBS')
            sxaddpar,subhdr,'DATE-OBS',dateobs
            obstime=sxpar(newhdr,'OBSTIME')
            sxaddpar,subhdr,'OBSTIME',obstime
            
            refparts=strsplit(reffiles[0],'/',/extract)
            refimname=refparts[n_elements(refparts)-1]
            sxaddpar,subhdr,'refim',refimname
            sxaddpar,subhdr,'newim',dirparts[n_elements(dirparts)-1]
            
            if ind eq 0 then begin
                subimage=ss_subtract_full_spline(newim,refim,mask,n_convolve=n_convolve,ref_conv=ref_conv,/convolve_ref,const_weight=const_weight,newimage1=newnew,newimage2=newref,sopath='/products/idltools/umrotse_idl/supernova_search/',subsize=nsubsize)
            endif else subimage=ss_subtract_full_spline(newim,refim,mask,n_convolve=n_convolve,ref_conv=ref_conv,const_weight=const_weight,sopath='/products/idltools/umrotse_idl/supernova_search/',subsize=nsubsize)
            
;save the subtracted image
            print,'writing:',subimname
            if sfail then sxaddpar,subhdr,'PSFSCL','no' else sxaddpar,subhdr,'PSFSCL','yes'
            writefits,subimname,subimage*satmask,subhdr

;process the subtracted images using sextractor
            satlevel=strtrim(string(long(satcnts2<satcnts1)),2)
            cmd='sex '+subimname+' -c '+extract_par+'/rotse_sne.sex -PARAMETERS_NAME '+extract_par+'/rotse_sne.par -FILTER_NAME '+extract_config+'/gauss_2.5_5x5.conv -PHOT_APERTURES 9  -SATUR_LEVEL '+satlevel+' -CATALOG_NAME '+sobjname+' -CHECKIMAGE_NAME '+skyname
            spawn,cmd

;process the convovled reference image
            if ind eq 0 then begin
                if keyword_set(local) then begin
                    refparts=strsplit(refimname,'_',/extract)
                    newrefname=refparts[0]+'_'+refparts[1]+'_'+refparts[2]+'-'+parts[0]+'-'+parts[2]+'-refc_c.fit'
                    newnewname=repstr(newrefname,'-refc_c.fit','-newc_c.fit')
                endif else begin
                    newrefname=repstr(refimname,'_c.fit','-conv_c.fit')
                    newrefname=repstr(newrefname,'.gz','')
                    newnewname=repstr(refimname,'_c.fit','-convnew_c.fit')
                    newnewname=repstr(newnewname,'.gz','')
                 endelse

                sxaddpar,newhdr,'SATCNTS',satcnts2
                writefits,refdir+'/image/'+newnewname,newnew,newhdr

                ;sxaddpar,refhdr,'NEWIM:',parts[0]+'_'+parts[1]+'_'+parts[2]+'_c.fit'
                writefits,refdir+'/image/'+newrefname,newref,refhdr
                conf={sobjdir:'',root:'',cimg:'',sobj:'',cobj:''}
                conf.sobjdir=refdir+'/prod/'
                conf.root=repstr(newrefname,'_c.fit','')
                conf.cimg=refdir+'/image/'+newrefname
                conf.sobj=refdir+'/prod/'+conf.root+'_sobj.fit'
                conf.cobj=refdir+'/prod/'+conf.root+'_cobj.fit'
                refskyname=conf.root+'_sky.fit'
                 
                cmd='sex '+conf.cimg+' -c /products/idltools/umrotse_idl/tools/sex/rotse3.sex -PARAMETERS_NAME /products/idltools/umrotse_idl/tools/sex/rotse3.par -FILTER_NAME /products/idltools/umrotse_idl/tools/sex/gauss_2.5_5x5.conv -PHOT_APERTURES 9 -SATUR_LEVEL '+strtrim(string(long(satcnts1)),2)+' -CATALOG_NAME '+conf.sobj+' -CHECKIMAGE_NAME '+conf.sobjdir+refskyname
                spawn,cmd
;calibrate the sobjlist
                print,'Beginning sobjfile '+conf.sobj
                sobj=mrdfits(conf.sobj,1,/silent)
                rotse_iii_usno_cal,refhdr,sobj,ucat,ucal,ustat,fail=fail,/readusno,subr=[0.5,0.3,0.7,1.0]
                if (not fail) then begin
                    write_cobj, conf, ustat, ucal, refhdr
                endif

            endif

;move the subtracted image into proper folder

            cmd = "chmod 666 " + subname+'*'
            spawn,cmd
            cmd = "cp " + subimname + " " + subdir +"/image/"
            spawn,cmd
            cmd = "rm -f " + subimname
            spawn,cmd
            cmd = "cp " + sobjname + " " + subdir +"/prod/"
            spawn,cmd
            cmd = "rm -f " + sobjname
            spawn,cmd
            cmd = "cp " + skyname + " " + subdir +"/prod/"
            spawn,cmd
            cmd = "rm -f " + skyname
            spawn,cmd

            ss_addto_list,subdir +"/prod/"+sobjname,subs_list

        endif else begin
            print,'warping failed'
        endelse

    endfor
    
endif

end
