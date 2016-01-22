pro ss_detect_and_plot_ice,newsubs,coadddir=coadddir,respdir=respdir,thumbfile=thumbfile,catalog=catalog,varlist=varlist,cand_list=cand_list,reflist=reflist,refdir=refdir,oldcanddir=oldcanddir,subrefsky=subrefsky

if n_params() eq 0 then begin
    print,'syntax - ss_detect_and_plot,newsubs,coadddir=coadddir,respdir=respdir,thumbfile=thumbfile,catalog=catalog,varlist=varlist,cand_list=cand_list,reflist=reflist,refdir=refdir,oldcanddir=oldcanddir'
    return
endif

nfind=0

;find all the relevant files
if n_elements(newsubs) eq 3 and newsubs[0] ne "nothing" then begin
    nfind=1
    subfiles=strarr(2,3)
    for ind=0,2 do begin
        subfiles[*,ind]=ss_find_image_sobj(newsubs[ind],fail=fail)
        if fail eq 1 then begin
            nfind=0
            print,'missing subtracted file...'
        endif
    endfor
endif else begin
    print,'less than 3 new subtracted sobjfiles found...'
endelse

if nfind eq 1 then begin
    newfiles=strarr(2,3)
    for ind=0,2 do begin
        imagename=sxpar(headfits(subfiles[0,ind]),'NEWIM')
        imagename=coadddir+'image/'+imagename    
        newfiles[*,ind]=ss_find_image_cobj(imagename,fail=fail)
        if fail eq 1 then begin
            nfind=0
            print,'missing new image file...'
        endif
    endfor
endif

if nfind eq 1 then begin

    reffiles=ss_find_ref_files(newfiles[0,0],reflist=reflist,refdir=refdir,fail=fail)
    ;check if the reference is the same as used in subtraction
    if fail eq 0 then begin
        refused=sxpar(headfits(subfiles[0,0]),'REFIM')
        if strmatch(reffiles[0],'*'+refused+'*') eq 0 then fail=1
    endif
    if fail eq 1 then begin
        nfind =0
        print,'missing reference file...'
    endif
endif

if nfind eq 1 then begin

    newstat0=mrdfits(newfiles[1,0],2,/silent)
    newstat1=mrdfits(newfiles[1,1],2,/silent)
    newstat2=mrdfits(newfiles[1,2],2,/silent)
    
    sobj0=mrdfits(subfiles[1,0],1,/silent)
    sobj1=mrdfits(subfiles[1,1],1,/silent)
    sobj2=mrdfits(subfiles[1,2],1,/silent)
    
    print,'extracted in sub0:',n_elements(sobj0)
    print,'extracted in sub1:',n_elements(sobj1)
    print,'extracted in sub2:',n_elements(sobj2)    

    sobj0.flux_aper=sobj0.flux_aper>0.0
    sobj1.flux_aper=sobj1.flux_aper>0.0
    sobj2.flux_aper=sobj2.flux_aper>0.0
    snr0=sobj0.flux_aper/sqrt(sobj0.flux_aper/3.+(sobj0.threshold/1.5)^2*(!dpi*7.^2))
    snr1=sobj1.flux_aper/sqrt(sobj1.flux_aper/3.+(sobj1.threshold/1.5)^2*(!dpi*7.^2))
    snr2=sobj2.flux_aper/sqrt(sobj2.flux_aper/3.+(sobj2.threshold/1.5)^2*(!dpi*7.^2))

    sobj0=ss_add_tag(sobj0,'snr',snr0)
    sobj1=ss_add_tag(sobj1,'snr',snr1)
    sobj2=ss_add_tag(sobj2,'snr',snr2)

    miniso=5
    minsnr0=5.
    minsnr1=2.5
    minsnr2=2.5
    edgew=20
    tst0=where(sobj0.isoarea_image ge miniso and sobj0.snr ge minsnr0 and sobj0.x_image gt edgew and sobj0.x_image lt newstat0.naxis1-edgew and sobj0.y_image gt edgew and sobj0.y_image lt newstat0.naxis2-edgew,n0)
    tst1=where(sobj1.isoarea_image ge miniso and sobj1.snr ge minsnr1 and sobj1.x_image gt edgew and sobj1.x_image lt newstat1.naxis1-edgew and sobj1.y_image gt edgew and sobj1.y_image lt newstat1.naxis2-edgew,n1)
    tst2=where(sobj2.isoarea_image ge miniso and sobj2.snr ge minsnr2 and sobj2.x_image gt edgew and sobj2.x_image lt newstat2.naxis1-edgew and sobj2.y_image gt edgew and sobj2.y_image lt newstat2.naxis2-edgew,n2)

    nfind=min([n0,n1,n2])
    print,'after snr cut:',nfind
endif

if nfind ge 1 then begin
    sobj0=sobj0[tst0]    
    sobj1=sobj1[tst1]
    sobj2=sobj2[tst2]
    
    refstat=mrdfits(reffiles[1],2,/silent)
    
;prepare
    pixscale = 1.85/2048.
    astr_struct_new,pixscale*2048.,astr
    secpixscale = pixscale*3600.
    n_convolve=9l
;translate candidate position into ra and dec.
    astr.crval=[double(refstat.rac),double(refstat.decc)]
    kmap_inv,sobj0.x_image-1.0,sobj0.y_image-1.0,cand_x,cand_y,refstat.kx,refstat.ky,kxi=kxi,kyi=kyi
    xy2rd,cand_x,cand_y,astr,cand_ra,cand_dec
    sobj0=ss_add_tag(sobj0,'ra',cand_ra)
    sobj0=ss_add_tag(sobj0,'dec',cand_dec)
    
    kmap,sobj1.x_image-1.0,sobj1.y_image-1.0,cand_x,cand_y,kxi,kyi
    xy2rd,cand_x,cand_y,astr,cand_ra,cand_dec
    sobj1=ss_add_tag(sobj1,'ra',cand_ra)
    sobj1=ss_add_tag(sobj1,'dec',cand_dec)

    kmap,sobj2.x_image-1.0,sobj2.y_image-1.0,cand_x,cand_y,kxi,kyi
    xy2rd,cand_x,cand_y,astr,cand_ra,cand_dec
    sobj2=ss_add_tag(sobj2,'ra',cand_ra)
    sobj2=ss_add_tag(sobj2,'dec',cand_dec)


    nfind=0
    nrelax=0
    relax=bytarr(n_elements(sobj0))
    lows=where(sobj0.snr lt 15.,nlows)
    if nlows gt 0 then relax[lows]=1
    
    dist1=0.8
    dist2=1.2
    relax1=where(relax eq 0,nr1)
    if nr1 gt 0 then begin
        close_match,sobj0[relax1].x_image,sobj0[relax1].y_image,[0,sobj1.x_image],[0,sobj1.y_image],m01,m10,dist1,1,/circle,/silent
        close_match,sobj0[relax1].x_image,sobj0[relax1].y_image,[0,sobj2.x_image],[0,sobj2.y_image],m02,m20,dist1,1,/circle,/silent
        match,m01,m02,in1,in2,count=nfind
        if nfind gt 0 then begin
            ind1=relax1[m01[in1]]
            ind11=m10[in1]-1
            ind12=m20[in2]-1
            tst1=where((sobj1[ind11].x_image-sobj2[ind12].x_image)^2+(sobj1[ind11].y_image-sobj2[ind12].y_image)^2 le dist1^2,nfind)
            if nfind gt 0 then begin
                ind1=ind1[tst1]
                ind11=ind11[tst1]
                ind12=ind12[tst1]
            endif
        endif
    endif

    relax2=where(relax eq 1,nr2)
    if nr2 gt 0 then begin
        close_match,sobj0[relax2].x_image,sobj0[relax2].y_image,[0,sobj1.x_image],[0,sobj1.y_image],m01,m10,dist2,1,/circle,/silent
        close_match,sobj0[relax2].x_image,sobj0[relax2].y_image,[0,sobj2.x_image],[0,sobj2.y_image],m02,m20,dist2,1,/circle,/silent
        match,m01,m02,in1,in2,count=nrelax
        if nrelax gt 0 then begin
            ind2=relax2[m01[in1]]
            ind21=m10[in1]-1
            ind22=m20[in2]-1
            tst2=where((sobj1[ind21].x_image-sobj2[ind22].x_image)^2+(sobj1[ind21].y_image-sobj2[ind22].y_image)^2 lt dist2^2,nrelax)
            if nrelax gt 0 then begin
                ind2=ind2[tst2]
                ind21=ind21[tst2]
                ind22=ind22[tst2]
            endif            
        endif
    endif
        
    nfind=nfind+nrelax
    print,'after matching position',nfind
endif


if nfind ge 1 then begin

    if nrelax gt 0 then begin
        if nfind gt nrelax then begin
            sobj0=sobj0[[ind1,ind2]]
            sobj1=sobj1[[ind11,ind21]]
            sobj2=sobj2[[ind12,ind22]]            
        endif else begin
            sobj0=sobj0[ind2]
            sobj1=sobj1[ind21]
            sobj2=sobj2[ind22]            
       endelse
    endif else begin
        sobj0=sobj0[ind1]
        sobj1=sobj1[ind11]
        sobj2=sobj2[ind12]
    endelse

;not too close to the edge of all images
    ra_high=min([refstat.ra_high,newstat1.ra_high,newstat2.ra_high])
    dec_high=min([refstat.dec_high,newstat1.dec_high,newstat2.dec_high])
    ra_low=max([refstat.ra_low,newstat1.ra_low,newstat2.ra_low])
    dec_low=max([refstat.dec_low,newstat1.dec_low,newstat2.dec_low])
    tst12=where(sobj0.ra lt ra_high-0.015 and sobj0.ra gt ra_low+0.015 and sobj0.dec lt dec_high-0.015 and sobj0.dec gt dec_low+0.015,nfind)
    
endif 

if nfind ge 1 then begin
    sobj0=sobj0[tst12]
    sobj1=sobj1[tst12]
    sobj2=sobj2[tst12]

    motions=sqrt((sobj1.x_image-sobj2.x_image)^2+(sobj1.y_image-sobj2.y_image)^2)
    sobj0=ss_add_tag(sobj0,'motion',motions)

;test the fwhm
    convref=repstr(reffiles[1],'_cobj.fit','-conv_cobj.fit')
    tst=findfile(convref,count=nconv)
    if nconv eq 1 then crefstat=mrdfits(convref[0],2,/silent) else crefstat=refstat
    newcobj0=mrdfits(newfiles[1,0],1,/silent)
    newcobj1=mrdfits(newfiles[1,1],1,/silent)
    newcobj2=mrdfits(newfiles[1,2],1,/silent)
    
    if tag_exist(newstat0,'fwhm') then fwhm0=newstat0.fwhm else fwhm0=2.5
    if tag_exist(newstat1,'fwhm') then fwhm1=newstat1.fwhm else fwhm1=2.5
    if tag_exist(newstat2,'fwhm') then fwhm2=newstat2.fwhm else fwhm2=2.5
    if tag_exist(refstat,'fwhm') then fwhmr=refstat.fwhm else fwhmr=2.5
    fwhm0=fwhm0>2.5
    fwhm1=fwhm1>2.5
    fwhm2=fwhm2>2.5
    fwhmr=fwhmr>2.5
    if nconv eq 1 and crefstat.fwhm gt 1.5 then fwhmlim0=(crefstat.fwhm*2) >7. else fwhmlim0=((fwhm0+fwhmr)*1.5)>7.
    fwhmlim1=((fwhm1-fwhm0)*1.5+fwhmlim0) >7. ;((fwhm1+fwhmr)*1.5)>7.5
    fwhmlim2=((fwhm2-fwhm0)*1.5+fwhmlim0) >7.;((fwhm2+fwhmr)*1.5)>7.5
    
    tst00=sobj0.fwhm_image le fwhmlim0 and sobj0.fwhm_image ge 1.01
    tst11=sobj1.fwhm_image le fwhmlim1 and sobj1.fwhm_image ge 1.01
    tst22=sobj2.fwhm_image le fwhmlim2 and sobj2.fwhm_image ge 1.01
	 	
    tst12=where(tst00 and tst11 and tst22,nfind)  	  

    print,'after fwhm cut:',nfind,string(fwhmlim0,format='(f4.1)'),string(fwhmlim1,format='(f4.1)'),string(fwhmlim2,format='(f4.1)')

endif

if nfind ge 1 then begin
    sobj0=sobj0[tst12]
        
    cobjtest=bytarr(nfind)
    ;if matches something in new0, should match a good object
    close_match_radec,sobj0.ra,sobj0.dec,newcobj0.ra,newcobj0.dec,cm1,cm2,pixscale*1.5,1,/silent
    if cm1[0] ne -1 then begin
        bad=where(newcobj0[cm2].fwhm lt 0.5 or newcobj0[cm2].m gt 50.,nbad)  
        if nbad gt 0 then cobjtest[cm1[bad]]=1
    endif
    tst=where(cobjtest eq 0,nfind)
    print,'after bad object (hot pixel, noise) cut:',nfind

endif

if nfind ge 1 then begin
    sobj0=sobj0[tst]

;any known variable stars?
    vars=mrdfits(varlist,1,/silent)
    close_match_radec,sobj0.ra,sobj0.dec,vars.ra,vars.dec,v1,v2,0.0015,1,tst12,/silent
    nfind=n_elements(tst12)
    if tst12[0] eq -1 then nfind=0
endif

if nfind ge 1 then begin
    sobj0=sobj0[tst12]

    w_image=refstat.naxis1
    h_image=refstat.naxis2

;flux change test
    fluxtst=bytarr(nfind)
    
    refcobj=mrdfits(reffiles[1],1,/silent)
    subim0=readfits(subfiles[0,0])

;recenter object
    if nconv eq 1 and crefstat.fwhm gt 1.5 then $
      gcntrd,subim0,sobj0.x_image-1,sobj0.y_image-1,newxcen,newycen,crefstat.fwhm,/silent $
    else $
      gcntrd,subim0,sobj0.x_image-1,sobj0.y_image-1,newxcen,newycen,fwhm0+fwhmr,/silent
    bad=where(newxcen lt 0. or newycen lt 0.,nbad)
    if nbad gt 0 then begin
        newxcen[bad]=sobj0[bad].x_image-1.
        newycen[bad]=sobj0[bad].y_image-1.
    endif
    sobj0.x_image=newxcen+1.0
    sobj0.y_image=newycen+1.0
    kmap,sobj0.x_image-1.0,sobj0.y_image-1.0,cand_x,cand_y,kxi,kyi
    xy2rd,cand_x,cand_y,astr,cand_ra,cand_dec
    sobj0.ra=cand_ra
    sobj0.dec=cand_dec
    
; no catalog match
    ;close_match_radec,refcobj.ra,refcobj.dec,cat.ra,cat.dec,galref,mcat,pixscale,1,starref,/silent
    starref=where(refcobj.fwhm le refstat.fwhm*1.4,nstar)  ;1.3 or 1.4
    galref=where(refcobj.fwhm gt refstat.fwhm*1.4,ngal)
    
    convrefname=repstr(reffiles[0],'_c.fit','-conv_c.fit')
    convrefname=repstr(convrefname,'.gz','')
    refim=readfits(convrefname,/silent)
    if keyword_set(subrefsky) then begin
        skyvec=crefstat.sky
        refim=ss_sky_subtract(refim,skyvec)
    endif
    aper=4
    daper=aper*2+1
    xaper=reform((findgen(daper^2) mod daper)-aper,daper,daper)
    yaper=reform((findgen(daper^2) / daper)-aper,daper,daper)
    dist_circle,aperdist,daper,aper,aper
    inaper=where(aperdist le aper)
    xaper=xaper[inaper]
    yaper=yaper[inaper]
    
    cases=lonarr(nfind)
    percents=lonarr(nfind)
    aper,refim,sobj0.x_image-1.0,sobj0.y_image-1.0,reftot,errap,jsky,jskyerr,3.,aper,/flux,setskyval=0.,/silent,/NAN
    aper,subim0,sobj0.x_image-1.0,sobj0.y_image-1.0,subtot,errap,jsky,jskyerr,3.,aper,/flux,setskyval=0.,/silent,/NAN
    
    for i=0,nfind-1 do begin
        mcase=3
        gcirc,1,sobj0[i].ra/15d0,sobj0[i].dec,refcobj[galref].ra/15d0,refcobj[galref].dec,dist
        catdist=dist/((refcobj[galref].fwhm*secpixscale+secpixscale)>2*secpixscale)
        mdist=min(catdist,galm)
        if mdist le 1 then begin
            ;match galaxy
            if dist[galm] ge secpixscale and mdist le 0.20 then mcase=0 else mcase=1
        endif 
        if mcase eq 3 then begin
            if starref[0] ne -1 then begin
                gcirc,1,sobj0[i].ra/15d0,sobj0[i].dec,refcobj[starref].ra/15d0,refcobj[starref].dec,dist
                if min(dist) le secpixscale*2. then mcase=2 ;else mcase=3
            endif ;else mcase=3
        endif
        cases[i]=mcase
        print,i,mcase,sobj0[i].x_image-1.0,sobj0[i].y_image-1.0

        ;dim=[w_image,h_image] 
        ;dist_circle,alldist,dim,sobj1[i].x_image,sobj1[i].y_image
        ;circ=where(alldist le 5)
        ;percent=total(subim1[circ])/(total(refim[circ])>30*20.)
        ixaper=round(sobj0[i].x_image-1.0)+xaper
        iyaper=round(sobj0[i].y_image-1.0)+yaper
        ;subtot=total(subim0[ixaper,iyaper])        
        ;subtot=sobj0[i].flux_aper ;-sobj0[i].fluxerr_aper/2d0
        ;reftot=total(refim[ixaper,iyaper])
        if mcase eq 3 and reftot[i] lt 150 then reftot[i]=0.1
        percent=subtot[i]/(reftot[i]>0.1)
        ;check if close to saturation (masked by 0)
        stest1=where(subim0[ixaper,iyaper] eq 0,ns1)
        if ns1 ge 3 then percent=0.
        percents[i]=long(percent*100.)
        print,percent,subtot[i],reftot[i],sobj0[i].snr,sobj0[i].fwhm_image
        
        case mcase of
            1:if percent ge 0.10 then fluxtst[i]=1b
            2:if percent ge 0.40 then fluxtst[i]=1b
            3:if percent ge 0.12 then fluxtst[i]=1b
            0:if percent ge 0.05 then fluxtst[i]=1b 
        endcase

        if (percent ge 10000. ) and fluxtst[i] eq 1b then begin
;anything with percent change > 1000% should match a detection in new0
            close_match_radec,sobj0[i].ra,sobj0[i].dec,newcobj0.ra,newcobj0.dec,hm1,hm2,pixscale*2.,1,/silent
            
            if hm1[0] eq -1 then fluxtst[i]=0b
        endif

        if fluxtst[i] eq 1b then print,'candidate:',sobj0[i].ra,sobj0[i].dec
    endfor

    sobj0=ss_add_tag(sobj0,'mcase',cases)
    sobj0=ss_add_tag(sobj0,'percent',percents)

    tst=where(fluxtst eq 1,nfind)

    print,'# find:',nfind
endif

if nfind ge 1 then begin
    sobj0=sobj0[tst]
endif

if nfind ge 30 then begin
    lowp=where(sobj0.mcase ge 2,nlow)
    highp=where(sobj0.mcase lt 2,nhigh)

    if nlow ge 30 then begin
;need further filtering
        
        sobj=sobj0[lowp]
        nbtst=bytarr(nlow)
        close_match,sobj.x_image,sobj.y_image,sobj.x_image,sobj.y_image,sm1,sm2,250.,nlow,/silent
        for i=0,nlow-1 do begin
            neighbor=where(sm1 eq i,nnb)
            if nnb ge 15 then nbtst[i]=1
        endfor
        
        tst=where(nbtst eq 0, nlow)
        print,'# (not matching galaxy) after rejecting clustering',nlow
        
        if nlow gt 30 then begin
            rad=[800,600,400]
            i=0
            while nlow gt 30 and i lt n_elements(rad) do begin
                sobj=sobj[tst]
                xl=w_image/2-rad[i]
                xh=w_image/2+rad[i]
                yl=h_image/2-rad[i]
                yh=h_image/2+rad[i]
                tst=where(sobj.x_image gt xl and sobj.x_image lt xh and sobj.y_image gt yl and sobj.y_image lt yh,nlow)
                i=i+1
            endwhile
            print,'# (not matching galaxy) find in subregion (radius ',rad[i-1],')',nlow
        endif
        if nlow gt 0 then sobjl=sobj[tst]
    endif else if nlow gt 0 then sobjl=sobj0[lowp]

    if nlow+nhigh gt 50 and nhigh gt 30 then begin
        sobj=sobj0[highp]
        nbtst=bytarr(nhigh)
        close_match,sobj.x_image,sobj.y_image,sobj.x_image,sobj.y_image,sm1,sm2,250.,nhigh,/silent
        for i=0,nhigh-1 do begin
            neighbor=where(sm1 eq i,nnb)
            if nnb ge 15 then nbtst[i]=1
        endfor

        tst=where(nbtst eq 0, nhigh)
        print,'# (matching galaxy) after rejecting clustering',nhigh

        if nlow+nhigh gt 50 and nhigh gt 30 then begin
            rad=[800,600,400]
            i=0
            while nhigh gt 30 and i lt n_elements(rad) do begin
                sobj=sobj[tst]
                xl=w_image/2-rad[i]
                xh=w_image/2+rad[i]
                yl=h_image/2-rad[i]
                yh=h_image/2+rad[i]
                tst=where(sobj.x_image gt xl and sobj.x_image lt xh and sobj.y_image gt yl and sobj.y_image lt yh,nhigh)
                i=i+1
            endwhile
            print,'# (matching galaxy) find in subregion (radius ',rad[i-1],')',nhigh
        endif
        if nhigh gt 0 then sobjh=sobj[tst]
    endif else if nhigh gt 0 then sobjh=sobj0[highp]
    
    nfind=nlow+nhigh
    print,'# find finally:',nfind
    if nlow gt 0 then begin
        if nhigh gt 0 then sobj0=[sobjh,sobjl] else sobj0=sobjl
    endif else begin
        if nhigh gt 0 then sobj0=sobjh
    endelse
   
endif

if nfind gt 0 then begin

    jpegparts=strsplit(subfiles[0,0],'/',/extract)
    jpegnames=strsplit(jpegparts[n_elements(jpegparts)-1],'_',/extract)
    jpegnamebase=jpegnames[0]+'_ssi_'+jpegnames[1]+'_'+strmid(jpegnames[2],0,2)

    jpegnamenew=jpegnamebase+'_new1.jpg'
    jpegnameref=jpegnamebase+'_ref.jpg'
    jpegnamesub=jpegnamebase+'_sub1.jpg'     
    candname=jpegnamebase+'.bin'

;plot the new, ref and sub images
    newim0=readfits(newfiles[0,0],/silent)
    subim0=readfits(subfiles[0,0],/silent)
    newim1=readfits(newfiles[0,1],/silent)
    subim1=readfits(subfiles[0,1],/silent)
    refim=readfits(reffiles[0],/silent)
    newim2=readfits(newfiles[0,2],/silent)
    subim2=readfits(subfiles[0,2],/silent)

;plot whole images    
    plotdim=[380,380]
    ss_regions_to_jpeg,newim0,jpegname=jpegnamenew,quality=50,dim=plotdim
    ss_regions_to_jpeg,refim,jpegname=jpegnameref,quality=50,dim=plotdim
    ss_regions_to_jpeg,subim0,xim=sobj0.x_image-1,yim=sobj0.y_image-1,box=150,color='green',jpegname=jpegnamesub,quality=75,dim=plotdim

;plot sub images
    rastring=strarr(nfind)
    decstring=strarr(nfind)
    for ij=0,nfind-1 do begin
        jpegname=strarr(5)
        
        rastrgs=string(round(sixty(sobj0[ij].ra/15d0)),format='(i2)')
        rastrgs=repstr(rastrgs,' ','0')
        decstrgs=string(round(sixty(abs(sobj0[ij].dec))),format='(i2)')
        decstrgs=repstr(decstrgs,' ','0')
        rastring[ij]=rastrgs[0]+rastrgs[1]+rastrgs[2]
        decstring[ij]=decstrgs[0]+decstrgs[1]+decstrgs[2]
        if sobj0[ij].dec lt 0 then decstring[ij]='-'+decstring[ij] else decstring[ij]='+'+decstring[ij]
        
        targetid=jpegnamebase+'_'+rastring[ij]+decstring[ij]
        jpegname[0]=targetid+'_new1.jpg'
        jpegname[1]=targetid+'_new2.jpg'
        jpegname[2]=targetid+'_ref.jpg'
        jpegname[3]=targetid+'_sub1.jpg'
        jpegname[4]=targetid+'_sub2.jpg'
        
        radec_circle_new,newstat1,sobj0[ij].ra,sobj0[ij].dec,box=0.11,image=newim1,dim=plotdim,jpegname=jpegname[0],/nolabel,caption='mlim = '+string(newstat1.m_lim,format='(f5.2)')+' ; fwhm = '+string(newstat1.fwhm,format='(f3.1)'),radius=8,/finding,/noskysub
        radec_circle_new,newstat2,sobj0[ij].ra,sobj0[ij].dec,box=0.11,image=newim2,dim=plotdim,jpegname=jpegname[1],/nolabel,caption='mlim = '+string(newstat2.m_lim,format='(f5.2)')+' ; fwhm = '+string(newstat2.fwhm,format='(f3.1)'),radius=8,/finding,/noskysub
        radec_circle_new,refstat,sobj0[ij].ra,sobj0[ij].dec,box=0.11,image=refim,dim=plotdim,jpegname=jpegname[2],/nolabel,caption='mlim = '+string(refstat.m_lim,format='(f5.2)')+' ; fwhm = '+string(refstat.fwhm,format='(f3.1)'),radius=8,/finding,/noskysub
        
        radec_circle_new,refstat,sobj0[ij].ra,sobj0[ij].dec,box=0.11,image=subim1,dim=plotdim,jpegname=jpegname[3],/nolabel,caption='subtraction 1',radius=8,/finding,/noskysub
        radec_circle_new,refstat,sobj0[ij].ra,sobj0[ij].dec,box=0.11,image=subim2,dim=plotdim,jpegname=jpegname[4],/nolabel,caption='subtraction 2',radius=8,/finding,/noskysub
        
    endfor
    
    ;check if any of the candidates appeared in the last days
    nold=lonarr(nfind)
    noldf=0
    lastday=replicate('0000',nfind)
    if n_elements(oldcanddir) eq 1 then begin
        oldf=findfile(oldcanddir+'/*'+jpegnames[1]+'*.fit',count=noldf)
        if noldf eq 0 then oldf=jpegnames[0]
        oldtst=where(strmatch(oldf,'*'+jpegnames[0]+'*') eq 0, noldf)
        if noldf gt 0 then begin
            for i=0,noldf-1 do begin
                old=mrdfits(oldf[oldtst[i]],1,/silent)
                close_match_radec,sobj0.ra,sobj0.dec,old.ra,old.dec,oldm1,oldm2,0.0015,1,/silent
                if oldm1[0] ne -1 then begin
                    nold[oldm1]=nold[oldm1]+1
                    oldfparts=strsplit(oldf[oldtst[i]],'/',/extract)
                    lastday[oldm1]=strmid(oldfparts[n_elements(oldfparts)-1],2,4)
                endif
            endfor
        endif
    endif
    noldstr=string(nold,format='(i2)')+'/'+string(noldf,format='(i2)')+'/'+lastday
    
    ;get the magnitude
    if (size(crefstat.zp_offset))[0] eq 2 then begin
        nbinx=(size(crefstat.zp_offset))[1]
        nbiny=(size(crefstat.zp_offset))[2]
    endif else begin
        nbinx=1
        nbiny=1
    endelse
    xbinsize=2050./float(nbinx)
    ybinsize=2050./float(nbiny)
    for i=0,nfind-1 do begin
        convi=floor(sobj0[i].x_image/xbinsize)
        convj=floor(sobj0[i].y_image/ybinsize)
        sobj0[i].mag_aper=sobj0[i].mag_aper+crefstat.zp_offset[convi,convj]
    endfor
    
    ;save the candidates list as a binary file
    caldat,newstat1.mjd+2400000.5d,month1,day1,year1,hour1,minute1,second1
    caldat,newstat2.mjd+2400000.5d,month2,day2,year2,hour2,minute2,second2
    caldat,refstat.mjd+2400000.5d,monthr,dayr,yearr,hourr,minuter,secondr
    new1time=string(month1,format='(i2)')+'.'+string(day1,format='(i2)')+'.'+string(year1,format='(i4)')+' '+string(hour1,format='(i2)')+':'+string(minute1,format='(i2)')+':'+string(second1,format='(i2)')
    new2time=string(month2,format='(i2)')+'.'+string(day2,format='(i2)')+'.'+string(year2,format='(i4)')+' '+string(hour2,format='(i2)')+':'+string(minute2,format='(i2)')+':'+string(second2,format='(i2)')
    reftime=string(monthr,format='(i2)')+'.'+string(dayr,format='(i2)')+'.'+string(yearr,format='(i4)')+' '+string(hourr,format='(i2)')+':'+string(minuter,format='(i2)')+':'+string(secondr,format='(i2)')
    
    openw,unit,candname,/get_lun
    writeu,unit,new1time,new2time,reftime
    writeu,unit,long(nfind)
    for i=0,nfind-1 do begin
        writeu,unit,double(sobj0[i].ra),double(sobj0[i].dec)
        writeu,unit,rastring[i],decstring[i]
        writeu,unit,float(sobj0[i].mag_aper)
        writeu,unit,long(sobj0[i].mcase)
        writeu,unit,long(sobj0[i].percent)
        writeu,unit,float(sobj0[i].snr),long(sobj0[i].isoarea_image),float(sobj0[i].x_image-1),float(sobj0[i].y_image-1),float(sobj0[i].fwhm_image),float(sobj0[i].motion)
        writeu,unit,noldstr[i]
    endfor
    close,unit
    free_lun,unit

;put the plots into the respdir

    cmd = "chmod 666 " + jpegnamebase+'*.jpg'
    spawn,cmd
    cmd = "cp "+jpegnamebase+'*.jpg'+" "+respdir
    spawn,cmd
    cmd = "rm -f "+jpegnamebase+'*.jpg'
    spawn,cmd
    cmd = "chmod 666 " + candname
    spawn,cmd
    cmd = "cp "+candname+" "+respdir
    spawn,cmd
    cmd = "rm -f "+candname
    spawn,cmd
    cmd= "touch "+thumbfile
    spawn,cmd
    
endif

if nfind gt 0 and n_elements(oldcanddir) eq 1 then begin
    jpegparts=strsplit(subfiles[0,0],'/',/extract)
    jpegnames=strsplit(jpegparts[n_elements(jpegparts)-1],'_',/extract)
    jpegnamebase=jpegnames[0]+'_ssi_'+jpegnames[1]+'_'+strmid(jpegnames[2],0,2)

;save the ra and dec and mag into a fits file   
    candfitname=jpegnamebase+'_cand.fit'
    candstr=replicate({ra:0d0,dec:0d0,x:0.0,y:0.0,mag:0.0},nfind)
    candstr.ra=sobj0.ra
    candstr.dec=sobj0.dec
    candstr.x=sobj0.x_image-1.
    candstr.y=sobj0.y_image-1.
    candstr.mag=sobj0.mag_aper
    mwrfits,candstr,oldcanddir+'/'+candfitname,/create
endif
    
end
