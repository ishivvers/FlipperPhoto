;; ********************************************************************************
pro rphot_coadd_images,data

;; coadd each set of binned images
;; weight by the target flux error

;; which photometry system are we using?
psys=(*data).usesys

;; get the image path
imnames=(*(*data).images).imname
imagepath=strmid(imnames[0],0,strpos(imnames[0],'/',/reverse_search)+1)
imnames=strmid(imnames,strlen(imagepath))

;; get the cobj path
cobjfile=(*(*data).images)[0].cobjfile
cobjpath=strmid(cobjfile,0,strpos(cobjfile,'/',/reverse_search)+1)

;; get the target flux
rphot_get_relative_flux,data,flux,eflux,/target,psys=psys
weights=eflux^(-2.0) ;### use sky noise instead? ###

;; coadd the images
suminds=(*(*data).images).sumind
w=where(suminds ge 0,nw)
temp=suminds[w]
unq_sumis=temp[uniq(temp,sort(temp))]
nsums=n_elements(unq_sumis)

for i=0,nsums-1 do begin
    w=where(suminds eq unq_sumis[i] and finite(f) eq 1 and finite(eflux) eq 1 and eflux gt 0,nw)
    if nw lt 2 then continue

    print,'******************************'
    print,'RPHOT: coadding images, weight'
    for j=0,nw-1 do print,imnames[w[j]],weights[w[j]]

    coadd_names3,imnames[w],imagepath=imagepath,cobjpath=cobjpath,imtot=imtot $
      ,coaddname=coaddname,minperc=0.0,weights=weights[w],outdir=imagepath

    print,'RPHOT: created new coadd '+coaddname
endfor

;; make the master ref using the best data
r=(*(*data).images).ratio[psys]
sky=(*(*data).images).sky/r
skynoise=(*(*data).images).skynoise/r
limmag=-2.5*alog10(3*skynoise)+(*data).zp[0]
fwhm=(*(*data).images).fwhm
w=where(suminds gt 0 and finite(f) eq 1 and finite(eflux) eq 1 and eflux gt 0,nw)
blah=fwhm[sort(fwhm)]
bestfwhm=blah[0.1*(n_elements(blah)-1)]
w=where(suminds gt 0 and finite(f) eq 1 and finite(eflux) eq 1 and eflux gt 0 and fwhm lt 1.25*bestfwhm,nw)
bestlim=max(limmag[w])
w=where(limmag gt bestlim-0.5 and suminds gt 0 and finite(f) eq 1 and finite(eflux) eq 1 and eflux gt 0 and fwhm lt 1.25*bestfwhm,nw)
exptime=(*(*data).images).exp


print,'******************************'
print,'     Images for Master REF     '
print,'             image               exp  limmag  fwhm       weight'
for i=0,nw-1 do print,imnames[w[i]],exptime[w[i]],limmag[w[i]],fwhm[w[i]],weights[w[i]] $
  ,format='(a,i5,f7.2,f7.2,f)'

ans=''
read,ans,prompt='Construct Master REF from these '+strtrim(nw,2)+' images (y/n/s)? '
if ans eq 's' then stop
if ans eq 'y' then begin
    print,'Making master REF'
    coadd_names3,imnames[w],imagepath=imagepath,cobjpath=cobjpath,imtot=imtot $
      ,coaddname=coaddname,minperc=0.0,weights=weights[w],outdir=imagepath
    print,'Master REF done'
endif

print,'RPHOT: you must now create cobj files for the new'
print,'       images exteranlly before rphot can use them'

end

;; ********************************************************************************
pro rphot_print_data_table,data,tex=tex

;; print out the start time, end time, exp time, mag, emag, limmag

;; which photometry system are we using?
psys=(*data).usesys

;; time from the burst in sec
mjd0=(*data).mjd
jd0=mjd0+2400000.5d
caldat,jd0,mon,day,year,hour,min,sec
month=month_cnv(mon)
sec='00'+nicetext(sec,2)
sec=strmid(sec,strlen(sec)-5)
sjd0=string(year,month,day,hour,min,sec,format='(i4," ",a3," ",i2.2,", ",2(i2.2,":"),a," UT")')
print,'Setting t=0 to ',sjd0
x=((*(*data).images).mjd-mjd0)*24.0*3600.0
ex=x+(*(*data).images).efftime
exptime=(*(*data).images).exp

;; get the target flux
rphot_get_relative_flux,data,y,ey,/target,psys=psys

;; sky and error for limmag calculation
r=(*(*data).images).ratio[psys]
sky=(*(*data).images).sky/r
skynoise=(*(*data).images).skynoise/r

;; get the run numbers from the image names
imnames=(*(*data).images).imname
nimages=n_elements(imnames)
run=strarr(nimages)
for i=0,nimages-1 do begin
    run[i]=strmid(imnames[i],strlen(imnames[i])-12,3)
endfor

;; sum data points?
suminds=(*(*data).images).sumind
if (*data).dosum eq 1 then begin
    ;; sum (skips inds less than 0)
    w=where(suminds ge 0,nw)
    temp=suminds[w]
    unq_sumis=temp[uniq(temp,sort(temp))]

    nsums=n_elements(unq_sumis)
    newx=dblarr(nsums)
    newex=dblarr(nsums)
    newexptime=dblarr(nsums)
    newy=dblarr(nsums)+!values.d_nan
    newey=dblarr(nsums)+!values.d_nan
    newskynoise=dblarr(nsums)+!values.d_nan
    newrun=strarr(nsums)

    for i=0,nsums-1 do begin
        w=where(suminds eq unq_sumis[i] and finite(y) eq 1,nw)
        if nw gt 0 then begin
            ;; get the average x,y values
            newx[i]=min(x[w])
            newex[i]=max(ex[w])
            newexptime[i]=total(exptime[w])
            blah=wtaverage(y[w],ey[w])
            newy[i]=blah[0]
            newey[i]=blah[1]

            blah=wtaverage(sky[w],skynoise[w])
            newskynoise[i]=blah[1]

            if nw gt 1 then newrun[i]=run[w[0]]+'-'+run[w[nw-1]] $
            else newrun[i]=run[w[0]]
        endif
    endfor
    x=newx
    ex=newex
    exptime=newexptime
    y=newy
    ey=newey
    skynoise=newskynoise
    suminds=unq_sumis
    run=newrun
endif

;; convert to magnitudes
mags=-2.5*alog10(y)+(*data).zp[psys]
emags=(2.5/alog(10))*(ey/y)
limmag=-2.5*alog10(3*skynoise)+(*data).zp[0]

if keyword_set(tex) then begin
    print,'\begin{deluxetable}{ccccc}'
    print,'\tablewidth{0pt}'
    print,'\tablecaption{}'
    print,'\tabletypesize{\scriptsize}'
    print,'\tablehead{'
    print,'  \colhead{$t_{\mathrm{start}}$ (s)} &'
    print,'  \colhead{$t_{\mathrm{end}}$ (s)} &'
    print,'  \colhead{Exp time}'
    print,'  \colhead{Magnitude}'
    print,'  \colhead{Merr}'
    print,'  \colhead{Lim Mag}'
    print,'}'
    print,'\startdata'

    for i=0,n_elements(mags)-1 do begin
        print,x[i],ex[i],exptime[i],mags[i],emags[i],limmag[i] $
          ,format='(f10.2," & ",f10.2," & ",i5," & ",f8.2," & ",f7.2," & ",f8.2," \\")'
    endfor

    print,'\enddata'
    print,'\tablecomments{}'
    print,'\end{deluxetable}'
endif else begin
    print,'  tstart     tend     exp   mag   emag  limmag  images'
    for i=0,n_elements(mags)-1 do begin
        print,x[i],ex[i],exptime[i],mags[i],emags[i],limmag[i],run[i] $
          ,format='(f10.4," ",f10.4," ",i5," ",f8.5," ",f7.5," ",f8.5," ",a8)'
    endfor
endelse

end

;; ********************************************************************************
pro rphot_clip_refim_objects,refims
COMPILE_OPT IDL2

xmin=min((*refims.refx)[0,*])-2.5*refims.fwhm
xmax=max((*refims.refx)[0,*])+2.5*refims.fwhm
ymin=min((*refims.refy)[0,*])-2.5*refims.fwhm
ymax=max((*refims.refy)[0,*])+2.5*refims.fwhm
objxs=*refims.objx
objys=*refims.objy
wuse=where(objxs gt xmin and objxs lt xmax and objys gt ymin and objys lt ymax,nuse)
if nuse eq 0 then begin
    print,'*****************************'
    print,'RPHOT: cant find any refim objects!'
    print,'*****************************'
    return
endif
*refims.objx=(*refims.objx)[wuse]
*refims.objy=(*refims.objy)[wuse]
*refims.objra=(*refims.objra)[wuse]
*refims.objdec=(*refims.objdec)[wuse]
*refims.objcounts=(*refims.objcounts)[*,wuse]
*refims.objecounts=(*refims.objecounts)[*,wuse]

end

; ********************************************************************************
pro rphot_change_phot_mode,event
COMPILE_OPT IDL2

;; change the photometry mode

widget_control,event.top,get_uvalue=data
(*data).usesys=widget_info((*data).phot_mode_list_id,/droplist_select)

;; show it
rphot_display_plot,data

end

; ********************************************************************************
pro rphot_bin_data,event,data=data,binmode=binmode
COMPILE_OPT IDL2

;; set the binning for data points

if keyword_set(data) eq 0 then begin
    widget_control,event.top,get_uvalue=data
    widget_control,event.id,get_uvalue=binmode
endif

if binmode eq 'reset' then begin
    (*(*data).images).sumind=indgen(n_elements(*(*data).images))
    (*data).dosum=0
    rphot_display_plot,data
    return
endif

;; hold on to the current indicies
oldinds=(*(*data).images).sumind

case binmode of
    'log' : begin
        dt=alog10(((*(*data).images).mjd-(*data).mjd)*24*60*60)
        inds=round(dt*10)
        w=where((*(*data).images).mjd eq 0,nw)
        if nw gt 0 then inds[w]=oldinds[w]
        (*data).dosum=1
   end

    '10': begin
        inds=fix(indgen(n_elements(*(*data).images))/10)
        (*data).dosum=1
    end

    'unbin': begin
        inds=indgen(n_elements(*(*data).images))
    end

    'noref': begin
        inds=oldinds
        inds[(*data).refi]=-1
    end

    'nobad': begin
        ;; bin up the ratios
        ;; find the peak of the distribution
        ;; just keep images with zp +/-0.5

        cut=0.6 ;; ### reset to 0.6

        ratios=(*(*data).images).ratio[0,*]
        eratios=(*(*data).images).eratio[0,*]
        inds=indgen(n_elements(*(*data).images))
        w=where(inds ne (*data).refi and eratios gt 0)
        bin=0.01
        minr=min(ratios[w])-bin
        maxr=max(ratios[w])+bin
        best=max(ratios[w])
        hist=histogram(ratios,min=minr,max=maxr,bin=bin)
        bins=linespace(minr,maxr,n_elements(hist))
        junk=max(hist,wmax)
        ;;w=where(ratios lt 0.75*bins[wmax] or ratios gt 1.35*bins[wmax],nw)
        w=where(ratios lt cut*best,nw)
        inds=oldinds
        if nw gt 0 then inds[w]=-1
        (*data).dosum=1

        col=getcolor(/load)
        widget_control,(*data).image_id,get_value=win_id
        wset,win_id
        (*data).display_mode='ratios'
        plot,bins,hist,ps=10,xs=3,/nodata,xtitle='Ratio',ytitle='Number of Images'
        oplot,bins,hist,ps=10,color=col.red
        ;;w=where(bins ge 0.75*bins[wmax] and bins le 1.35*bins[wmax],nw)
        w=where(bins ge cut*best)
        oplot,bins[w],hist[w],ps=10,color=col.green
    end

    'auto': begin
        minSN=7.0

        ;; get the target flux, error
        psys=(*data).usesys
        rphot_get_relative_flux,data,flux,eflux,/target,psys=psys

        ;; bin things up so S/N is always > minSN
        n=n_elements((*(*data).images))
        inds=indgen(n)
        ind=0
        wstart=0
        wend=0
        repeat begin
            w=indgen(wend-wstart+1)+wstart
            ;;w=where(inds ge wstart and inds le wend,nw)

            ;; get the S/N
            blah=wtaverage(flux[w],eflux[w])
            s2n=blah[0]/blah[1]

            if s2n lt minSN then begin
                wend=wend+1
                inds[wstart:wend]=ind
            endif else begin
                wstart=wend+1
                wend=wstart
                ind=inds[wstart]
            endelse
        endrep until wend ge n-1
        (*data).dosum=1
    end

    else: begin
        print,'Unknown binning mode: '+binmode
    end
endcase

;; put last few stragglers into second to last bin
wpenult=where(inds eq max(inds)-1,npenult)
wmax=where(inds eq max(inds),nmax)
if npenult gt 0 and nmax gt 0 and nmax lt 0.8*npenult then inds[wmax]=max(inds)-1

;; don't change things with negative indicies
w=where(oldinds lt 0,nw) 
if nw gt 0 then begin
    inds[w]=oldinds[w]
endif

;; update
(*(*data).images).sumind=inds

;; show it
rphot_display_plot,data

end

; ********************************************************************************
pro rphot_unblind,event
COMPILE_OPT IDL2

;; turns off blinding

widget_control,event.top,get_uvalue=data
(*data).blind=0

end

; ********************************************************************************
pro rphot_save_match_struct,event
COMPILE_OPT IDL2

;; creates a new match struct and fills it with values in
;; "data". Saves to a user specified file.
;; saves target + objects

;; get the data
widget_control,event.top,get_uvalue=data

;; get the output file name
file=dialog_pickfile(filter='*.fit',title='Save Match Struct Data As',/write,file="rphot_match.fit",path=(*data).basedir)
if file eq '' then return

;; which photometry system are we saving?
psys=(*data).usesys

;; get all the object fluxes
rphot_get_relative_flux,data,objfluxes,objefluxes,/allobjects,psys=psys

;; add the target flux
rphot_get_relative_flux,data,flux,eflux,/target,psys=psys

;; put the target and object fluxes together
nimages=n_elements( (*(*data).images) )
fluxes=fltarr(nimages,n_elements(objfluxes[0,0,*])+1)
fluxes[*,0]=flux
fluxes[*,1:*]=reform(objfluxes)
efluxes=fltarr(nimages,n_elements(objfluxes[0,0,*])+1)
efluxes[*,0]=eflux
efluxes[*,1:*]=reform(objefluxes)
nobj=n_elements(fluxes[0,*])

;; create new match struct
refims=(*(*data).images)[(*data).refi]
make_match3_new,match,nimages,nobj

;; fill match struct with data
match.nobs=nimages
match.nobj=nobj
match.jd=(*(*data).images).mjd
match.exptime=(*(*data).images).exp
;;match.rac=
;;match.decc=
;;match.ral=
;;match.rah=
;;match.decl=
;;match.dech=

for i=0,nimages-1 do begin
    ims=(*(*data).images)[i]
    
    match.kx=*ims.rdkx
    match.ky=*ims.rdky

    ;; strip dir from imname
    imname=strmid(ims.imname,strpos(ims.imname,'/',/reverse_search)+1)
    match.imagename=imname

    match.m[i,*]=99.9
    match.merr[i,*]=99.9
    if ims.sumind eq -1 then continue

    w=where(fluxes[i,*] gt 0,nw)
    if nw gt 0 then begin
        ;; convert flux to magnitudes
        match.m[i,w]=-2.5*alog10(fluxes[i,w])+(*data).zp[psys]
        match.merr[i,w]=(2.5/alog(10))*(efluxes[i,w]/fluxes[i,w])

        match.flags[i,w] = 0
        match.rflags[i,w] = 0
        match.dra[i,w] = 0
        match.ddec[i,w] = 0
        match.msys[i,w] = 0
    endif
endfor

match.ra=[refims.ra,*refims.objra]
match.dec=[refims.dec,*refims.objdec]
;;match.numobs=
;;match.consec=
;;match.ngood=
;;match.mavg=
;;match.mstd=

skynoise=(*(*data).images).skynoise/(*(*data).images).ratio[psys]
match.m_lim=-2.5*alog10(3*skynoise)+(*data).zp[0]

calc_diag_parms,match
;; now get the stats_struct
elt=create_struct('file','')
dummy=replicate(elt,nimages)
dummy.file=(*(*data).images).cobjfile
err=stats_strct(dummy,allstats,0)
;;stats_strct,(*(*data).images).cobjfile,allstats

;; save match struct to file
;;save_match,match,allstats
mwrfits,match,file,/create
mwrfits,allstats,file

end

; ********************************************************************************
pro rphot_wipe_data,data,keepref=keepref,keepk=keepk
COMPILE_OPT IDL2

nphot=(*data).nphot
for i=0,n_elements( (*(*data).images).imname)-1 do begin
    if (*(*data).images)[i].imname eq (*(*data).images)[(*data).refi].imname $
      and keyword_set(keepref) then continue
    
    if not keyword_set(keepk) then begin
        *(*(*data).images)[i].kx=-1.0
        *(*(*data).images)[i].ky=-1.0
    endif

    (*(*data).images)[i].x=dblarr(nphot)-1.0
    (*(*data).images)[i].y=dblarr(nphot)-1.0
    (*(*data).images)[i].ra=-1.0
    (*(*data).images)[i].dec=-1.0
    (*(*data).images)[i].counts=dblarr(nphot)+!values.d_nan
    (*(*data).images)[i].ecounts=dblarr(nphot)+!values.d_nan
    *(*(*data).images)[i].refx=dblarr(nphot)-1.0
    *(*(*data).images)[i].refy=dblarr(nphot)-1.0
    *(*(*data).images)[i].refra=-1.0
    *(*(*data).images)[i].refdec=-1.0
    *(*(*data).images)[i].refcounts=dblarr(nphot)+!values.d_nan
    *(*(*data).images)[i].refecounts=dblarr(nphot)+!values.d_nan
    (*(*data).images)[i].ratio=dblarr(nphot)+1.0
    (*(*data).images)[i].eratio=dblarr(nphot)
    *(*(*data).images)[i].mask=-1
endfor


end

; ********************************************************************************
pro rphot_save_radec,event
COMPILE_OPT IDL2

;; saves the target and refstar RA and DEC to a user specified file

;; get the output file name
widget_control,event.top,get_uvalue=data
file=dialog_pickfile(filter='*.txt',title='Save Target/Refstar RA,DEC To',/write,file="rphot_radec.txt",path=(*data).basedir)
if file eq '' then return

refims=(*(*data).images)[(*data).refi]

openw,lun,file,/get_lun
printf,lun,'TARGET'
printf,lun,'RA','DEC',format='(a12," ",a12)'
printf,lun,refims.ra,refims.dec,format='(d12.7," ",d12.7)'

printf,lun,''
printf,lun,'REFSTARS'
printf,lun,'RA','DEC',format='(a12," ",a12)'
for i=0,n_elements((*refims.refx)[0,*])-1 do begin
    printf,lun,(*refims.refra)[i],(*refims.refdec)[i],format='(d12.7," ",d12.7)'
endfor
close,lun
free_lun,lun

end

; ********************************************************************************
pro rphot_adjust_zoom,event
COMPILE_OPT IDL2

;; this routine responds to user requests to change the image windowing

widget_control,event.id,get_uvalue=mode
widget_control,event.top,get_uvalue=data

ims=(*(*data).images)[(*data).current_image]

zoom=ims.zoom
xw=max([10,zoom[2]-zoom[0]])
xc=(zoom[0]+zoom[2])/2
yw=max([10,zoom[3]-zoom[1]])
yc=(zoom[1]+zoom[3])/2
case mode of
    'in2x': begin
        minx=max([0,xc-xw/4])
        maxx=min([ims.nx-1,xc+xw/4])
        miny=max([0,yc-yw/4])
        maxy=min([ims.ny-1,yc+yw/4])
        zoom=[minx,miny,maxx,maxy]
    end
    'out2x': begin
        minx=max([0,xc-xw])
        maxx=min([ims.nx-1,xc+xw])
        miny=max([0,yc-yw])
        maxy=min([ims.ny-1,yc+yw])
        zoom=[minx,miny,maxx,maxy]
    end
    'auto': begin
        if (*ims.refx)[0] ne -1 then begin
            newx=(*ims.refx)[0,*]
            newy=(*ims.refy)[0,*]
            zoom=[max([0,min(newx)-50]), $
                  max([0,min(newy)-50]), $
                  min([ims.nx-1,max(newx)+50]), $
                  min([ims.nx-1,max(newy)+50])  $
                 ]
        endif
    end
    'all': begin
        zoom=[0,0,ims.nx-1,ims.ny-1]
    end
    else: return
endcase

;; set the new zoom
(*(*data).images)[(*data).current_image].zoom=zoom

;; redraw the display
rphot_display_image,data,ims.imname

end

;; ********************************************************************************
pro rphot_choose_images,event
COMPILE_OPT IDL2

;; lets the user select images using a file finder. If an image was
;; in the old list, its data is preserved.

widget_control,event.top,get_uvalue=data
file=(*(*data).images)[0].imname
if file[0] ne '' then path=strmid(file[0],0,strpos(file[0],'/',/REVERSE_SEARCH)+1) $
else path=(*data).basedir
imlist=dialog_pickfile(filter='*.fit.gz',/must_exist,title='Choose Images to Photometer' $
                       ,file=file[0],path=path,/MULTIPLE_FILES)
if imlist[0] eq '' then return

rphot_fix_image_list,data,imlist

end

;; ********************************************************************************
pro rphot_add_images,event
COMPILE_OPT IDL2

;; lets the user add images to the list using a file finder. A unique
;; list of images is kept, so adding an existing image does nothing.

widget_control,event.top,get_uvalue=data

file=(*(*data).images)[0].imname
if file[0] ne '' then path=strmid(file[0],0,strpos(file[0],'/',/REVERSE_SEARCH)+1)
imnames=dialog_pickfile(filter='*.fit.gz',/must_exist,title='Choose Images to Photometer' $
                        ,file=file[0],path=path,/MULTIPLE_FILES)
if imnames[0] eq '' then return

imlist=[(*(*data).images).imname,imnames]
imlist=imlist[uniq(imlist,sort(imlist))]
rphot_fix_image_list,data,imlist

end

;; ********************************************************************************
pro rphot_clean_imlist,data,imnames
COMPILE_OPT IDL2

;; first be sure all the images and cobj files exist
if not keyword_set(imnames) then return
print,'Making sure all the image and cobj files exist...'
n=n_elements(imnames)
isok=intarr(n)
for i=0,n-1 do begin
    if (findfile(imnames[i]))[0] eq '' then begin
        print,'*** RPHOT: cannot find image ',imnames[i]
    endif else begin
        ;; figure out the cobjfilename
        dir=strmid(imnames[i],0,strpos(imnames[i],'/',/REVERSE_SEARCH)-5)+'prod/'
        file=strmid(imnames[i],strpos(imnames[i],'/',/REVERSE_SEARCH)+1)
        file=strmid(file,0,strpos(file,'.fit'))+'obj.fit'
        cobjfile=dir+file

        if (findfile(cobjfile))[0] eq '' then begin
            print,'*** RPHOT: cannot find cobjfile ',cobjfile
        endif else isok[i]=1
    endelse
endfor

w=where(isok eq 1,nw)
if nw eq 0 then begin
    print,'RPHOT: no valid data! Enter new image list'
    blah=temporary(imnames)
    return
endif

if n ne nw then begin
    ;; reset the image list
    print,'RPHOT: removing ',strtrim(n-nw,2),' images from the list'
    imnames=imnames[w]
endif else print,'...done checking for files'

end

;; ********************************************************************************
pro rphot_fix_image_list,data,imlist
COMPILE_OPT IDL2

;; sets the image list to the new imlist. Data from images carried
;; over from the old list to the new list are preserved. Creates new
;; pointers to image data; old pointers are freed

;; through out image names with no data or no cobjfile
rphot_clean_imlist,data,imlist
if not keyword_set(imlist) then return

;; save current imname
current_imname=(*(*data).images)[(*data).current_image].imname

;; create the new image structs
n_images=n_elements(imlist)
images=[rphot_new_image(imlist[0],(*data).nphot)]
for i=1,n_images-1 do begin
    images=[images,rphot_new_image(imlist[i],(*data).nphot)]
endfor

;; copy over the existing data
oldnames=(*(*data).images).imname
for i=0,n_elements(oldnames)-1 do begin
    w=where(imlist eq oldnames[i],nw)
    if nw gt 0 then begin
        images[w[0]]=rphot_copy_image((*(*data).images)[i],(*data).nphot)
    endif
    
    ;; free old data from memory
    n_tags=n_tags((*(*data).images)[i])
    for j=0,n_tags-1 do begin
        info=size( (*(*data).images)[i].(j) )
        type=info[n_elements(info)-2]
        if type eq 10 then begin
            undefine,*(*(*data).images)[i].(j)
            ptr_free,(*(*data).images)[i].(j)
        endif
    endfor
endfor

;; store new data in data
*(*data).images=images

;; reset current_image
w=where((*(*data).images).imname eq current_imname,nw)
if nw ne 0 then (*data).current_image=w[0]

;; reset refi
w=where((*(*data).images).imname eq (*data).refname,nw)
if nw ne 0 then (*data).refi=w[0]

;; adjust "choose image" list
if (*data).show_image_id ne 0 then begin
    widget_control,(*data).imlist_id,set_value=(*(*data).images).imname
    widget_control,(*data).imlist_id,set_list_select=(*data).current_image
endif

end

;; ********************************************************************************
pro rphot_choose_refim,event
COMPILE_OPT IDL2

;; lets the user select the reference image with a file finder. The
;; reference image should be the "best" image--best seeing and
;; deepest. It will be used to construct the sky mask for the target,
;; and will serve as the reference system for the relative
;; photometry. The zeropoint will be calculated using the refimage.

widget_control,event.top,get_uvalue=data

file=(*data).refname
if file[0] eq '' then file=(*(*data).images[0]).imname
if file[0] ne '' then path=strmid(file[0],0,strpos(file[0],'/',/REVERSE_SEARCH)+1)
refname=dialog_pickfile(filter='*.fit.gz',/must_exist,title='Choose Reference Image',file=file[0],path=path)
if refname eq '' then return

;; add refimage to image list
w=where((*(*data).images).imname eq refname,nw)
if nw eq 0 then begin
    imlist=[(*(*data).images).imname,refname]
    imlist=imlist[uniq(imlist,sort(imlist))]
    rphot_fix_image_list,data,imlist
    w=where(imlist eq refname,nw)
endif
(*data).refi=w[0]
(*data).refname=refname

;; wipe all data using old refsys
rphot_wipe_data,data

end

;; ********************************************************************************
pro rphot_choose_object,event
COMPILE_OPT IDL2

;; lets the user select the target and reference stars on the
;; reference image. Really a wrapper for rphot_select_objects

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=just_one
if (*data).select_objects_id ne 0 then begin
    widget_control,(*data).select_objects_id,/show
    return
endif

refname=(*data).refname
if refname eq '' then begin
    ;; the refim must be loaded first. Warn user
    print,'!!!!!!!!!!!!!!!!!!!!!!!!!'
    print,'You must first selecet the reference image!'
    print,'!!!!!!!!!!!!!!!!!!!!!!!!!'

    rphot_choose_refim,event
endif

;; must choose target before picking refstars
if not keyword_set(just_one) and (*(*data).images)[(*data).refi].x[0] eq -1 then begin
    print,'!!!!!!!!!!!!!!!!!!!!!!!!!'
    print,'You must select the target before choosing refstars'
    print,'!!!!!!!!!!!!!!!!!!!!!!!!!'
    return
endif

;; ### set *refim.objx=[-1] here to reload all objects from the
;; refimage ###


;; display the image
rphot_display_image,data,refname,title='REFIM: '+refname

;; launch select_objects widget
rphot_select_objects,data,ims,just_one=just_one

end

;; ********************************************************************************
pro rphot_get_calib,event
COMPILE_OPT IDL2

;; lets the user select a file with the field calibration data (ra,
;; dec, mag, and emag of stars in the file) using a file finder. The
;; stars in the calibration file are then matched to the refstars;
;; non-matching stars are dropped. A zeropoint on the refimage is
;; calculated for each matching star, and the MEDIAN zeropoint is
;; recorded to calibrate the refimage (and hence, all the images).
;;
;; example calib file:
;;
;;R
;;        RA         DEC    Rmag   emag
;;327.264770  -27.697215  16.495  0.022
;;
;; first line just lists the filter
;; second line names the columns (skipped)
;; third and beyond lists values for each star.

widget_control,event.top,get_uvalue=data
file=(*(*data).images[0]).imname
path=strmid(file[0],0,strpos(file[0],'/',/REVERSE_SEARCH)+1)
calib=dialog_pickfile(filter='*.dat',/must_exist,title='Choose Calibration File',path=path)
if calib eq '' then return
refims=(*(*data).images)[(*data).refi]

;; read the calib file
readcol,calib,ra,dec,mag,emag,vmr,format='(d,d,d,d,d)',/silent

;; get the filter
openr,lun,calib,/get_lun
filter=''
readf,lun,filter
color=''
readf,lun,color
close,lun
free_lun,lun

;; set calib data
(*data).calib.filter=filter
*(*data).calib.ra=ra
*(*data).calib.dec=dec
*(*data).calib.mag=mag
*(*data).calib.emag=emag
*(*data).calib.use=intarr(n_elements(mag))
*(*data).calib.refmag=dblarr(n_elements(*refims.refra))
*(*data).calib.color=vmr

;; match calibs to refstars
close_match_radec,*refims.refra,*refims.refdec,ra,dec,wref,wcal,0.0009d,1.0,missed
if wcal[0] eq -1 then begin
    for i=0,n_elements(ra)-1 do begin
        dist=min(sqrt((*refims.refra-ra[i])^2.0+(*refims.refdec-dec[i])^2.0),minind)
        if dist lt 0.0009 then begin
            wcal=[wcal,i]
            wref=[wref,minind]
        endif
    endfor
    if n_elements(wcal) gt 1 then begin
        wcal=wcal[1:*]
        wref=wref[1:*]
    endif else begin
        ;; oh well
        print,'RPHOT: Could not calibrate !!!!!'
        return
    endelse
endif
(*(*data).calib.use)[wcal]=1
(*(*data).calib.refmag)[wref]=mag[wcal]

;; calculate zeropoints
for i=0,(*data).nphot-1 do begin
    zps=mag[wcal]+2.5*alog10((*refims.refcounts)[i,wref])
    (*data).zp[i]=median(zps)
endfor

;; give the mag range, color of the stars used
wuse=where((*(*data).calib.use) eq 1,nuse)
mags=((*(*data).calib.mag))[wuse]
minmag=min(mags)
maxmag=max(mags)
colors=((*(*data).calib.color))[wuse]
mincolor=min(colors)
maxcolor=max(colors)
print,'********************************************************************'
print,'RPHOT: calibrated magnitude scale using '+strtrim(nuse,2)+' objects'
print,'RPHOT: calibration objects have ',nicetext(minmag,1),' < ',filter,' < ',nicetext(maxmag,1),' median=',nicetext(median(mags),2)
print,'RPHOT: calibration objects have ',nicetext(mincolor,1),' < ',color,' < ',nicetext(maxcolor,1),' median=',nicetext(median(colors),2)
print,'********************************************************************'

;; redraw
rphot_display_image,data
rphot_display_plot,data

end

;; ********************************************************************************
pro rphot_get_psf,data,ims
COMPILE_OPT IDL2

;; NOT the DAOPHOT psf fitting.
;; calculates the PSF on an image by stacking all the refstars
;; (shifted to the nearest 1/grow pixels). Fits a 2D gaussian to
;; determine the sigma->FWHM. Sets fwhm.


if ims.fwhm eq 0 then ims.fwhm=(*data).fixrad
radtol=0.75*ims.fwhm

n=round((*data).psf_npix > 4*ims.fwhm)

grow=(*data).psf_grow
psf=fltarr(n*grow,n*grow)
npsf=intarr(n*grow,n*grow)
for i=0,n_elements((*ims.refx)[0,*])-1 do begin
    ;; recentroid this refstar
    gcntrd,*ims.image,(*ims.refx)[0,i],(*ims.refy)[0,i],xcen,ycen,ims.fwhm,maxgood=ims.satcounts

    if xcen eq -1.0 or ycen eq -1.0 $
      or sqrt( ((*ims.refx)[0,i]-xcen)^2.0 + ((*ims.refy)[0,i]-ycen)^2.0 ) gt radtol $
      then continue

    minx=long(xcen-n/2.0)
    maxx=minx+n-1
    miny=long(ycen-n/2.0)
    maxy=miny+n-1
    if minx lt 0 or miny lt 0 or maxx ge ims.nx or maxy ge ims.ny then continue
    
    ;; reset sky radii
    skyrad1=(*data).skyrad1*((*data).fixrad > ims.fwhm) + 1.0
    skyrad2=(*data).skyrad2*((*data).fixrad > ims.fwhm)

    ;; subtract sky
    niter=0
    naper=!pi*((*data).fixrad > ims.fwhm)^2.0
    repeat begin
        lsky=(get_local_sky(*ims.image,xcen,ycen,skyrad1,skyrad2 $
                            ,annulus=annulus,std=std,rej=rej))[0]
        nsky=n_elements(annulus)
        w=where(rej ne -1,nrej)
        nsky=nsky-nrej
        niter=niter+1
        skyrad2=skyrad2+skyrad1
    endrep until nsky gt naper or niter gt 4

    imclip=(*ims.image)[minx:maxx,miny:maxy]-lsky
    if rej[0] ne -1 then imclip[rej]=0
    
    ;; dilate the new psf
    newpsf=rebin(imclip,grow*n,grow*n)
    temp=rebin(imclip,grow*n,grow*n,/sample) ;; ##### should we do bi-lin interpolation?
    
    ;; center the new psf
    xoff=round(((*ims.refx)[0,i]-minx-n/2.0)*grow)
    yoff=round(((*ims.refy)[0,i]-miny-n/2.0)*grow)
    newpsf=shift(newpsf,-xoff,-yoff) ; edge values get wrapped, but oh well...
    
    w=where(temp ne 0,nw)
    psf[w]=psf[w]+newpsf[w]
    npsf[w]=npsf[w]+1
endfor
w=where(npsf gt 0,nw)
if nw gt 0 then psf[w]=psf[w]/npsf[w]
*ims.psf=psf

;; find radius that encloses 93.7% of the flux
ntry=n*grow/2-1 < 5*ims.fwhm/2*grow
flux=fltarr(ntry)
for i=1,ntry-1 do begin
    aper_rphot,psf,n*grow/2.0,n*grow/2.0,f,ef,sky,esky,1,i,[0,0],[0,0],/flux,/exact,/silent,setskyval=0
    flux[i]=f
endfor
totalflux=max(flux)
w=where(flux gt 0.937*totalflux,nw)
fwhm0=float(w[0])/grow

if keyword_set(radial_fwhm) then begin
    rads=linespace(0,(ntry-1)/grow,ntry)
    profile=(flux[1:*]-flux)/!pi/(rads[1:*]^2.0-rads^2.0)
    r=[-reverse(rads[1:*]),rads[1:*]]
    p=[reverse(profile),profile]
    yfit=gaussfit(r,p,a,nterms=3)
    ims.fwhm=2*sqrt(2*alog(2))*a[2]
    (*(*data).images)[(*data).current_image]=ims
    return
endif

;; do spline fit
rads=linespace(0,ntry-1,ntry/0.05)
fitflux=spline(findgen(ntry),flux,rads)
w=where(fitflux gt 0.937*totalflux,nw)
if nw gt 0 then fwhm1=float(rads[w[0]])/grow else fwhm1=0.0

catch, error_status
if (error_status ne 0) then begin
    print,'RPHOT: Could not fit Gaussian to PSF...'
    print,(*data).fixrad,format='("setting FWHM to Fixed radius (",f5.2,")")'
    ims.fwhm=(*data).fixrad
endif else begin
    ;; fit the gaussian
    yfit=gauss2dfit(psf,a,/tilt)

    ;; see if this worked
    ;;sigma=max(a[2:3])/grow  ;; #### bigger sigma?
    sigma=min(a[2:3])/grow  ;; #### smaller sigma?
    fwhm=2*sqrt(2*alog(2))*sigma
    ;;fwhm=total(2*sqrt(2*alog(2))*a[2:3]/grow)/2 ;; ##### take average?
    if fwhm gt 0.5 and fwhm lt n*grow/2.0 then begin
        ;; reset the FWHM
        print,ims.fwhm,fwhm,fwhm1,format='("^^^^ resetting fwhm from ",f6.3," to ",f6.3," (",f6.3,") ^^^^")'
        ims.fwhm=fwhm
    endif else begin
        print,'RPHOT: Invalid Gaussian fit to PSF...'
        print,(*data).fixrad,format='("setting FWHM to Fixed radius (",f5.2,")")'
        ims.fwhm=(*data).fixrad
    endelse
endelse
catch,/cancel

;;debug=1
if keyword_set(debug) then begin
    print,a[2]/grow,a[3]/grow,format='("sigmax=",f7.3,"  sigmay=",f7.3)'
    device,window_state=ws
    w=where(ws ne 0,nw)
    if nw gt 0 then oldwin=!d.window

    !p.multi=[0,2,2]
    if ws[2] ne 1 then window,2,xs=800,ys=800
    wset,2
    col=getcolor(/load)
    plot,rads,fitflux/max(fitflux)
    niceframe,psf/max(psf),span=1,zero=0
    boxdata,2*fwhm,n*grow/2.0,n*grow/2.0,col.green,/circ
    boxdata,2*fwhm1,n*grow/2.0,n*grow/2.0,col.red,/circ
    frame,yfit/max(psf),span=1,zero=0
    niceframe,(psf-yfit)/max(psf)
    
    if nw gt 0 then wset,oldwin
    !p.multi=0
    ;;stop
endif


;; record
(*(*data).images)[(*data).current_image]=ims

end

;; ********************************************************************************
pro rphot_load_image,data,imname,skiprefphot=skiprefphot
COMPILE_OPT IDL2

;; loads the specified image (ie. actually put the image data array
;; into the "data" structure). Will locate refstars, calculate
;; transformation coefficients, and do photometry if needed.

;; max number of image data arrays to keep in memory at a time
n_maxload=5

w=where((*(*data).images).imname eq imname,nw)
if nw eq 0 then begin
    print,imname,format='(a,": image not available")'
    return
endif
index=w[0]
isave=(*data).current_image
(*data).current_image=index
ims=(*(*data).images)[index]

if not keyword_set(*ims.image) then begin
    ;; free up memory if needed
    w=where((*(*data).images).timestamp ne 0,nw)
    if nw ge n_maxload then begin
        w2=sort((*(*data).images)[w].timestamp)
        *(*(*data).images)[w[w2[0]]].image=0
        (*(*data).images)[w[w2[0]]].timestamp=0
    endif

    ;; load the image
    *ims.image=readfits(imname,head)
    
    ;; see if the file read worked
    s=size(*ims.image)
    if s[0] ne 2 then begin ; should be 2 dimensional array
        ;; file read failed, try again
        wait,2
        *ims.image=readfits(imname,head)
        s=size(*ims.image)
        if s[0] ne 2 then begin
            print,'!!!!!!!!!!!!!!!!!'
            print,'RPHOT: could not access image! Fix it.'
            print,'!!!!!!!!!!!!!!!!!'
            stop
        endif
    endif

    ims.timestamp=systime(1)
    size=size(*ims.image)
    ims.nx=size[1]
    ims.ny=size[2]
    ims.clip=[0,0,0,0]

    subinds=sxpar(head,'IMSUB')
    if keyword_set(subinds) then begin
        ;; this is a sub frame
        xsub=fix([strmid(subinds,0,4),strmid(subinds,5,4)])
        ysub=fix([strmid(subinds,10,4),strmid(subinds,15,4)])
     endif else begin
         xsub=[0,ims.nx-1]
         ysub=[0,ims.ny-1]
     endelse
    ims.xsub=xsub
    ims.ysub=ysub

    ;; read in the cobj file
    cal=mrdfits(ims.cobjfile,2)

    ;; see if the file read worked
    s=size(cal)
    type=s[s[0]+1]
    if type eq 2 then begin
        ;; file read failed, try again
        wait,2
        cal=mrdfits(ims.cobjfile,2)
        s=size(cal)
        type=s[s[0]+1]
        if type eq 2 then begin
            print,'!!!!!!!!!!!!!!!!!'
            print,'RPHOT: could not access cobjfile! Fix it.'
            print,'!!!!!!!!!!!!!!!!!'
            stop
        endif
    endif
    ims.mjd=cal.mjd
    ims.exp=cal.exptime
    ims.efftime=cal.efftime
    ims.crval=[cal.crval1,cal.crval2]
    *ims.rdkx=cal.kx
    *ims.rdky=cal.ky
    ims.satcounts=cal.satcnts
    ims.satmag=cal.sat_mag
    ims.ronoise=cal.bstddev
    ims.satflux=10.0^(0.4*(cal.sexmgzpt+cal.zp_offset-cal.sat_mag))

    ;; set approx fwhm
    if ims.fwhm eq 0 then begin
        ;; see if the fwhm tag exists
        tags=tag_names(cal)
        w=where(tags eq 'FWHM',nw)
        if nw ne 0 then ims.fwhm=cal.fwhm $
        else ims.fwhm=(*data).fixrad
    endif

    ;; subtract sky background
    if (*data).doskysub eq 1 then begin
        sub_sky,*ims.image,cal.sky,newim,xsub=ims.xsub,ysub=ims.ysub
        *ims.image=newim
    endif

    ;; get the burst time from the refimage
    if (*data).mjd eq 0 and ims.imname eq (*(*data).images)[(*data).refi].imname then begin
        trig_sod=sxpar(head,'TRIG_T')
        trig_jd=sxpar(head,'TRIG_TJD')
        (*data).mjd=trig_jd+trig_sod/24/60/60.0+40000.0
    endif

    ;; get the sky value
    if(ims.skymode eq 0) then begin
        sky,*ims.image,skymode,skysig
        ims.skymode=skymode
        ims.skysig=skysig

        ;; set the span and zero
        ims.span=8*ims.skysig
        ims.zero=ims.skymode-1.5*ims.skysig
    endif

    ;; record
    (*(*data).images)[index]=ims
endif else begin
    (*(*data).images)[index].timestamp=systime(1)
endelse

;; locate objects
if((*ims.objx)[0] eq -1) then begin
    ;; load the cobj file
    pho=mrdfits(ims.cobjfile,1)
    s=size(pho)
    type=s[s[0]+1]
    if type ne 8 then begin
        ;; file read failed, try again
        wait,2
        pho=mrdfits(ims.cobjfile,1)
        s=size(pho)
        type=s[s[0]+1]
        if type ne 8 then begin
            print,'!!!!!!!!!!!!!!!!!'
            print,'RPHOT: could not access cobjfile! Fix it.'
            print,'!!!!!!!!!!!!!!!!!'
            stop
        endif
    endif
    
    s=size(pho)
    type=s[s[0]+1]
    if type eq 8 then begin
        w=where(pho.x lt 0 or pho.x ge ims.nx or pho.y lt 0 or pho.y ge ims.ny,nw,comp=wgood,ncomp=ngood)
        if nw gt 0 then begin
            ;;print,"print cobjfile has out of bounds objects!!!"
            if ngood gt 0 then pho=pho[wgood] else type=0
        endif
        *ims.flags=pho.flags
        *ims.objra=pho.ra
        *ims.objdec=pho.dec
        *ims.objx=pho.x
        *ims.objy=pho.y
    endif else begin
        print,'RPHOT error: Could not locate cobj file'
        undefine,pho
        ims.sumind=-1
    endelse

    ;; record
    (*(*data).images)[index]=ims
endif

;; locate refstars
if ims.imname ne (*(*data).images)[(*data).refi].imname and (*(*(*data).images)[(*data).refi].refx)[0] ne -1 then begin
    refims=(*(*data).images)[(*data).refi]
    if((*ims.refx)[0] eq -1) then begin
        close_match_radec,*refims.refra,*refims.refdec,*ims.objra,*ims.objdec,refi,newi,0.0009d,1.0,missed
        if n_elements(newi) eq 0 then newi=-1
        if newi[0] ne -1 then begin
            *ims.refx=dblarr((*data).nphot,n_elements(*refims.refra))
            *ims.refy=dblarr((*data).nphot,n_elements(*refims.refra))
            *ims.refra=dblarr((*data).nphot,n_elements(*refims.refra))
            *ims.refdec=dblarr((*data).nphot,n_elements(*refims.refra))
            
            (*ims.refx)[0,refi]=(*ims.objx)[newi]
            (*ims.refy)[0,refi]=(*ims.objy)[newi]
            (*ims.refra)[0,refi]=(*ims.objra)[newi]
            (*ims.refdec)[0,refi]=(*ims.objdec)[newi]
            
            ;; get transform from refsys to current image (new)
            if n_elements(*ims.kx) eq 1 then begin
                refx=(*refims.refx)[0,refi]
                refy=(*refims.refy)[0,refi]
                newx=(*ims.objx)[newi]
                newy=(*ims.objy)[newi]
                degree=floor(min([sqrt(n_elements(refx))-1,2]))  ;##### should this be floor or ceil??? ####
                if degree lt 1 then begin
                    print,'RPHOT: not enough matching refstars! need at least 4'
                endif else begin
                    ;; calculate kx & ky
                    catch, error_status
                    if (error_status ne 0) then begin
                        print,'RPHOT: Could not calculate kx,ky...'
                    endif else begin
                        polywarp,newx,newy,refx,refy,degree,kx,ky
                    endelse
                    catch,/cancel
                   
                    if  n_elements(kx) gt 1 then begin
                        ;; make sure the refstars were properly matched
                        problems=1
                        keepers=refi
                        while total(problems) ne 0 do begin
                            ;; locate problems
                            problems=lonarr(n_elements(keepers))
                            for i=0,n_elements(keepers)-1 do begin
                                refx=(*refims.refx)[0,keepers[i]]
                                refy=(*refims.refy)[0,keepers[i]]
                                kmap,refx,refy,x,y,kx,ky
                                dist=sqrt( ((*ims.refx)[0,keepers[i]]-x)^2.0 + ((*ims.refy)[0,keepers[i]]-y)^2.0 )
                                ;;print,'RPHOT: refstar '+strtrim(i,2)+' off by ',strtrim(dist[0],2)+' pixels'
                                if dist[0] gt 1.0 then begin
                                    problems[i]=dist
                                endif
                            endfor
                            
                            if total(problems) ne 0 then begin
                                ;; drop worst ofender
                                worst=max(problems,wmax)
                                print,'RPHOT: dropping refstar '+strtrim(keepers[wmax],2)
                                if missed[0] eq -1 then missed=wmax $
                                else missed=[missed,keepers[wmax]]
                                
                                ;; keep the rest
                                w=where(problems ne worst,nkeep)
                                if nkeep gt 0 then begin
                                    keepers=keepers[w]
                                    refx=(*refims.refx)[0,keepers]
                                    refy=(*refims.refy)[0,keepers]
                                    newx=(*ims.refx)[0,keepers]
                                    newy=(*ims.refy)[0,keepers]
                                    
                                    degree=floor(min([sqrt(n_elements(refx))-1,2]))
                                    if degree lt 1 then begin
                                        print,'RPHOT: not enough matching refstars! need at least 4'
                                        problems=0
                                    endif else begin
                                        ;; recalculate kx & ky
                                        polywarp,newx,newy,refx,refy,degree,kx,ky
                                    endelse
                                endif
                            endif
                        endwhile
                        
                        *ims.kx=kx
                        *ims.ky=ky    
                    endif
                endelse
            endif

            ;; locate missing refstars
            if missed[0] ne -1 and n_elements(*ims.kx) ne 1 then begin
                for i=0,n_elements(missed)-1 do begin
                    ;;print,'looking for refstar '+strtrim(missed[i],2)
                    refx=(*refims.refx)[0,missed[i]]
                    refy=(*refims.refy)[0,missed[i]]
                    kmap,refx,refy,x,y,*ims.kx,*ims.ky
                    
                    ra=(*refims.objra)[missed[i]]
                    dec=(*refims.objdec)[missed[i]]
                    
                    ;; add this star to the ref list
                    (*ims.refx)[0,missed[i]]=x
                    (*ims.refy)[0,missed[i]]=y
                    (*ims.refra)[0,missed[i]]=ra
                    (*ims.refdec)[0,missed[i]]=dec
                endfor
            endif

            ;; get the psf
            if ims.fwhm eq 0 then begin
                rphot_get_psf,data,ims
                rphot_get_psf,data,ims
            endif

            ;; ***
            ;; put check here to make sure transform is valid
            ;; ***
            ;; convert refim object ra/dec to this image x/y
            ;;rphot_rd2xy,ims.cobjfile,*refims.refra,*refims.refdec,x,y
            rphot_rd2xy,ims.crval,*ims.rdkx,*ims.rdky,*refims.refra,*refims.refdec,x,y

            ;; get test kx/ky in this system
            d=sqrt(n_elements(x))-1
            degree=2
            if d lt degree then begin
                print,'RPHOT: You need to chose more refstars for the transform to work well!'
                stop
            endif
            polywarp,x,y,(*refims.refx)[0,*],(*refims.refy)[0,*],degree,testkx,testky

            ;; apply that warping
            kmap,(*refims.refx)[0,*],(*refims.refy)[0,*],testx,testy,testkx,testky

            ;; match refx,y to this image objx,y
            close_match,testx,testy,*ims.objx,*ims.objy,m1,m2,0.75*ims.fwhm,1
            if m1[0] eq -1 then stop ; you've got a problem
            x1=testx[m1]
            y1=testy[m1]
            x2=(*ims.objx)[m2]
            y2=(*ims.objy)[m2]

            ;; get median residual
            testres=median(sqrt((x2-x1)^2.0 + (y2-y1)^2.0))

            if n_elements(*ims.kx) eq 1 then res=testres+1 $
            else begin
                kmap,(*refims.refx)[0,*],(*refims.refy)[0,*],x2,y2,*ims.kx,*ims.ky
                res=median(sqrt((x2-x)^2.0 + (y2-y)^2.0))
            endelse

            ;; use which ever is better
            print,res,testres,format='("medres=",f7.4,", test medres=",f7.4)'
            if testres lt res then begin
                print,'******************'
                print,'RPHOT: using psuedo-cobj kx and ky for mapping'
                print,'******************'
                *ims.kx=testkx
                *ims.ky=testky

                ;; update refstar x,y
                (*ims.refx)[0,m1]=x1
                (*ims.refy)[0,m1]=y1
            endif
            ims.medres=testres < res
            
            ;; record
            (*(*data).images)[index]=ims
        endif
    endif
endif else if ims.imname eq (*(*data).images)[(*data).refi].imname then begin
    ;; set up kx,ky
    kx=fltarr(4,4)
    ky=fltarr(4,4)
    kx[0,1]=1
    ky[1,0]=1
    *ims.kx=kx
    *ims.ky=ky
endif

;; locate target
if (*data).current_image ne (*data).refi and ims.x[0] eq -1 and n_elements(*ims.kx) ne 1 then begin
    refx=((*(*data).images)[(*data).refi].x)[0]
    refy=((*(*data).images)[(*data).refi].y)[0]
    kmap,refx,refy,x,y,*ims.kx,*ims.ky
    ims.x[0]=x
    ims.y[0]=y

    ;; record
    (*(*data).images)[index]=ims
    
    ;; do all the photometry
    rphot_do_photometry,data
endif

;; auto-zoom to working area
if (*ims.refx)[0] ne -1 and total(ims.zoom) eq 0 then begin
    newx=(*ims.refx)[0,*]
    newy=(*ims.refy)[0,*]
    zoom=[max([0,min(newx)-50]), $
          max([0,min(newy)-50]), $
          min([ims.nx-1,max(newx)+50]), $
          min([ims.ny-1,max(newy)+50]) $
         ]
    (*(*data).images)[index].zoom=long(zoom)
endif else if total(ims.zoom) eq 0 then (*(*data).images)[(*data).current_image].zoom=[0,0,ims.nx-1,ims.ny-1]

;; do photometry on ref if needed/possible
if keyword_set(skiprefphot) eq 0 and (*data).current_image eq (*data).refi and (*ims.refx)[0] ne -1 and finite(ims.counts[0]) eq 0 $
  and ims.x[0] ne -1 and (*ims.refx)[0] ne -1 then begin
    ;; get the psf
    if ims.fwhm eq 0 then begin
        rphot_get_psf,data,ims
        rphot_get_psf,data,ims
    endif

    ;; do the photometry
    rphot_do_photometry,data

    ;; read in cobjfile
    pho=mrdfits(ims.cobjfile,1)
    
    ;; match up refstars
    close_match,(*ims.refx)[0,*],(*ims.refy)[0,*],pho.x,pho.y,m1,m2,ims.fwhm,1,missed1
    
    ;; set ballpark zps
    if m1[0] ne -1 then begin
        print,'RPHOT: setting ZPs to *APPROXIMATE* values...'
        for i=0,(*data).nphot-1 do begin
            zps=pho[m2].m+2.5*alog10((*ims.refcounts)[i,m1])
            (*data).zp[i]=median(zps)
        endfor
    endif
endif

;; reset image index
(*data).current_image=isave

end

;; ********************************************************************************
pro rphot_display_image,data,imname,title=title,skiprefphot=skiprefphot
COMPILE_OPT IDL2

;; Does much more than just display an image. Loads images as
;; necessary, finds refstars, finds the target, calls photometry
;; routines, calculates ref/new ratio, etc. This is where everything
;; actually gets done.

if not keyword_set(imname) then imname=(*(*data).images)[(*data).current_image].imname
if imname eq '' then return
if keyword_set(title) eq 0 then title=imname

w=where((*(*data).images).imname eq imname,nw)
if nw eq 0 then begin
    print,imname,format='(a,": image not available")'
    return
endif
i=w[0]
(*data).current_image=i
if (*data).show_image_id ne 0 then widget_control,(*data).imlist_id,set_list_select=(*data).current_image

;; set the plotting window
widget_control,(*data).image_id,get_value=win_id
wset,win_id
(*data).display_mode='image'

;; load in the image
rphot_load_image,data,imname,skiprefphot=skiprefphot
ims=(*(*data).images)[(*data).current_image]
if not keyword_set(*ims.image) then return

;; adjust the widgets
rphot_set_zero,data,zero=ims.zero
rphot_set_span,data,span=ims.span

;; display
zoom=ims.zoom
frame,(*ims.image)[zoom[0]:zoom[2],zoom[1]:zoom[3]],offset=zoom[0:1],title=title,span=ims.span,zero=ims.zero
rphot_show_objects,data

;; make sure the mode is set to zoom, zero/span, or examine now that
;; we're showing an image
if (*data).mode eq 'check' or (*data).mode eq 'analysis' or (*data).mode eq 'photometry' then begin
    rphot_change_mode_to,data,'examine'
    widget_control,(*data).mode_list_id,set_droplist_select=2

endif

;; store the plotting var clip region
(*data).image_clip=!p.clip

end

;; ********************************************************************************
pro rphot_show_objects,data
COMPILE_OPT IDL2

;; draws circles/hexagons around objects, refstars, the target, and
;; objects in the calibration list.

col=getcolor(/load)

ims=(*(*data).images)[(*data).current_image]
;;rad= ims.fwhm > (*data).fixrad
radscale=(*data).radscale[(*data).usesys]
if radscale lt 0 then rad=abs(radscale) $
else rad=ims.fwhm*radscale
if (*data).show_objects eq 1 then begin
    ;; draw red circles around all detected objects
    w=where(*ims.objx gt ims.zoom[0] and *ims.objx lt ims.zoom[2] $
            and *ims.objy gt ims.zoom[1] and *ims.objy lt ims.zoom[3],nw)
    if nw gt 0 then boxdata,2*rad,(*ims.objx)[w],(*ims.objy)[w],col.red,/circ

    ;; draw red boxes around all substars
    if (*data).nsubstars gt 0 then begin
        substars=*(*data).substars
        kmap,substars.x,substars.y,x,y,*ims.kx,*ims.ky
        boxdata,2*rad,x,y,col.red
    endif
endif
if (*data).show_refstars eq 1 then begin
    ;; draw yellow circle around ref objects
    if total(*ims.refx) gt -1 then begin
        w=where((*ims.refx)[0,*] gt ims.zoom[0] and (*ims.refx)[0,*] lt ims.zoom[2] $
                and (*ims.refy)[0,*] gt ims.zoom[1] and (*ims.refy)[0] lt ims.zoom[3],nw)
        if nw gt 0 then begin
            boxdata,2*rad,(*ims.refx)[0,w],(*ims.refy)[0,w],col.yellow,/circ
            xyouts,(*ims.refx)[0,w],(*ims.refy+rad+1)[0,w],strtrim(w,2)
        endif
    endif
endif
if (*data).show_target eq 1 then begin
    ;; draw green circle around target object
    if ims.x[0]+ims.y[0] gt -1 then begin
        boxdata,2*rad,ims.x[0],ims.y[0],col.green,/circ,thick=2
    endif
endif
if (*data).show_calibs eq 1 then begin
    ;; draw purple hexagon around calib stars
    if (*(*data).calib.use)[0] ne -1 then begin
        ;; convert ra/dec values to x,y position on refimage
        ;;rphot_rd2xy,ims.cobjfile,*(*data).calib.ra,*(*data).calib.dec,x,y
        rphot_rd2xy,ims.crval,*ims.rdkx,*ims.rdky,*(*data).calib.ra,*(*data).calib.dec,x,y

        w=where(x gt ims.zoom[0] and x lt ims.zoom[2] and y gt ims.zoom[1] and y lt ims.zoom[3] $
                and *(*data).calib.use eq 1,nw)
        if nw gt 0 then boxdata,2*rad+2,x[w],y[w],col.magenta,/hex
    endif
endif

end

;; ********************************************************************************
pro rphot_display_closeup,data,x,y,nodata=nodata
COMPILE_OPT IDL2

;; shows a 3.0*(*data).fixrad+1 square view of the image centered at
;; x,y. Also shows the sky mask, and marks objects in the field. Can
;; optionally show the psf, or the psf-subtracted (kinda) closeup.

col=getcolor(/load)

;; set the plotting window
widget_control,(*data).closeup_id,get_value=win_id
wset,win_id

ims=(*(*data).images)[(*data).current_image]
if n_elements(*ims.image) eq 0 then rphot_load_image,data,ims.imname  ;; ### change this to load_image ###

skyrad2=(*data).skyrad2*((*data).fixrad > ims.fwhm)
n=skyrad2 + 1.0
if n_elements(x) eq 0 then begin
    if (*data).plot_mode eq 'refstar' then begin
        x=(*ims.refx)[0,(*data).refstari]
        y=(*ims.refy)[0,(*data).refstari]
    endif else if (*data).plot_mode eq 'object' then begin
        refims=(*(*data).images)[(*data).refi]
        refimx=(*refims.objx)[(*data).objecti]
        refimy=(*refims.objy)[(*data).objecti]

        ;; convert to current image x,y
        kmap,refimx,refimy,x,y,*ims.kx,*ims.ky
    endif else begin
        x=min([ims.x[0],ims.nx-1])
        y=min([ims.y[0],ims.ny-1])
    endelse
endif

;; x and y must be scalars
x=x[0]
y=y[0]

;; check for out of bounds
if x lt 0 or y lt 0 or x gt ims.nx-1 or y gt ims.ny-1 then begin
    print,"RPHOT: can't display closeup--object off image!"
    erase
    return
endif

;; ### need better out of bounds checking ###
minx=long(max([0,x-n]))
maxx=long(min([ims.nx-1,x+n]))
miny=long(max([0,y-n]))
maxy=long(min([ims.ny-1,y+n]))

if (*data).closeup_mode eq 'image' then begin
    if not keyword_set(*ims.image) then rphot_load_image,data,ims.imname
    image=(*ims.image)

    ;; *** subtract out stars which interfer with the photometry ***
    if (*data).nsubstars gt 0 then begin
        substars=*(*data).substars
        kmap,substars.x,substars.y,subx,suby,*ims.kx,*ims.ky

        counts=substars.counts*ims.ratio[1]
        mags=-2.5*alog10(counts)+25.0
        
        rphot_substar,image,subx,suby,mags $
          ,usepsf=*ims.psf,gauss=ims.gauss,psfmag=ims.psfmag,psfrad=ims.psfrad,fitrad=ims.fitrad 
    endif

    closeup=image[minx:maxx,miny:maxy]
    frame,closeup,offset=[minx,miny],span=ims.span,zero=ims.zero,/noframe,/full
    if keyword_set(nodata) then return
    rphot_show_objects,data
;;stop
  
    ;; show the sky mask
    if x eq ims.x[0] and y eq ims.y[0] then begin
        inmask=*ims.mask
        noreject=1
    endif else noreject=0

    ;; reset sky radii
    skyrad1=(*data).skyrad1*((*data).fixrad > ims.fwhm) + 1.0
    skyrad2=(*data).skyrad2*((*data).fixrad > ims.fwhm)

    niter=0
    naper=!pi*((*data).fixrad > ims.fwhm)^2.0
    repeat begin
        lsky=(get_local_sky(*ims.image,x[0],y[0],skyrad1,skyrad2 $
                            ,annulus=annulus,std=std,rej=rej,inmask=inmask,noreject=noreject))[0]
        nsky=n_elements(annulus)
        w=where(rej ne -1,nrej)
        nsky=nsky-nrej
        ;;w=where(noreject ne -1,nrej)
        ;;if noreject eq 0 then nsky=nsky-nrej
        niter=niter+1
        skyrad2=skyrad2+0.5*skyrad1
    endrep until nsky gt 2*naper or niter gt 8
    my=annulus/ims.nx
    mx=annulus mod ims.nx
    device, get_graphics = old, set_graphics = 6 ;Set xor
    boxdata,1,mx,my,col.cyan
    device, set_graphics = old

    ;; show rejected pixels
    if keyword_set(inmask) then rej=[rej,inmask]
    my=rej/ims.nx
    mx=rej mod ims.nx
    ;;device, get_graphics = old, set_graphics = 3 ;Set xor
    ;;boxdata,1,mx,my,col.blue
    device, set_graphics = 11 ;Set xor
    boxdata,1,mx,my,col.blue
    boxdata,1,mx,my,col.blue
    device, set_graphics = old

    ;; check lsky with mmm value for same pixels, full annulus
    ;; debug=1
    if keyword_set(debug) then begin
        wused=annulus
        if rej[0] ne -1 then begin
            for i=0,n_elements(rej)-1 do begin
                w=where(wused ne rej[i],wn)
                wused=wused[w]
            endfor
        endif

        mmm,(*ims.image)[wused],skymod,skysig,skyskw
        wfull=annulus
        if inmask[0] ne -1 then wfull=[wfull,inmask]
        mmm,(*ims.image)[wfull],skymod0,skysig0,skyskw0
        print,lsky,skymod,skymod0,format='("lsky is ",f8.3,", mmm gives ",f8.3," (",f8.3,")")'
        print, std,skysig,skysig0,format='("std  is ",f8.3,", mmm gives ",f8.3," (",f8.3,")")'
        
        device,window_state=ws
        w=where(ws ne 0,nw)
        if nw gt 0 then oldwin=!d.window
        if ws[2] ne 1 then window,2,xs=900,ys=600
        wset,2
        
        bin=std[0]/3
        low=lsky[0]-4*std[0]
        high=lsky[0]+10*std[0]
        hist0=histogram((*ims.image)[wfull],bin=bin,min=low,max=high)
        xax0=linespace(low,high,n_elements(hist0))
        plot,xax0,hist0,ps=10
        hist1=histogram((*ims.image)[wused],bin=bin,min=low,max=high)
        xax1=linespace(low,high,n_elements(hist1))
        oplot,xax1,hist1,ps=10,color=col.green

        x=linespace(low,high,100)
        y=max(hist0)*exp(-((x-skymod[0])/skysig[0])^2.0/2)
        oplot,x,y,linestyle=1,color=col.red,thick=2
        yfit=gaussfit(xax0,hist0,a,nterms=3)
        oplot,x,a[0]*exp(-((x-a[1])/a[2])^2.0/2),linestyle=2
        sig0=a[2]

        x=linespace(low,high,100)
        y=max(hist1)*exp(-((x-lsky[0])/std[0])^2.0/2)
        oplot,x,y,linestyle=1,color=col.green,thick=2
        yfit=gaussfit(xax1,hist1,a,nterms=3)
        oplot,x,a[0]*exp(-((x-a[1])/a[2])^2.0/2),linestyle=2

        print,sig0,a[2]          ,format='("fits    ",f8.3,",    and    ",f8.3)'

        if nw gt 0 then wset,oldwin
    endif
endif else if (*data).closeup_mode eq 'fitpsf' then begin
    ;; grow the image clip
    grow=(*data).psf_grow
    n=(size(*ims.psf))[1]/grow
    minx=long(x-n/2.0)
    maxx=minx+n-1
    miny=long(y-n/2.0)
    maxy=miny+n-1
    imclip=rebin((*ims.image)[minx:maxx,miny:maxy],grow*n,grow*n)

    yfit=gauss2dfit(imclip,imclipa)
    yfit=gauss2dfit(*ims.psf,psfa)

    psf=(*ims.psf)*imclipa[1]/psfa[1]+imclip[0]
    ;;psf=shift(psf,imclipa[4]-psfa[4],imclipa[5]-psfa[5])
    xoff=round((x-minx-n/2.0)*grow)
    yoff=round((y-miny-n/2.0)*grow)
    psf=shift(psf,xoff,yoff)

    frame,imclip-psf,/full,/noframe
    contour,imclip-psf,nlevels=10,color=col.magenta,/overplot
;;stop
endif else begin
    ;; show the psf
    frame,*ims.psf,/full,/noframe
    n=(size(*ims.psf))[1]
    boxdata,2*ims.fwhm*(*data).psf_grow,n/2.0,n/2.0,col.cyan,/circ
    contour,*ims.psf,nlevels=15,color=col.magenta,/overplot
    plots,n/2.0,n/2.0,psym=7,color=col.cyan

    yfit=gauss2dfit(*ims.psf,a)
    plots,a[4],a[5],psym=7,color=col.magenta
endelse

;; store the plotting var clip region
(*data).closeup_clip=!p.clip

end

;; ********************************************************************************
pro rphot_display_plot,data,x=x,y=y,save_data=save_data,save_plot=save_plot,wset=win_id,nowset=nowset
COMPILE_OPT IDL2

;; plots target/refstar light curve. Can optionally sum data points.

if keyword_set(save_plot) then begin
    set_plot,'ps'
    device,/landscape,filename=save_plot,bits_per_pixel=8,/color
endif else if keyword_set(nowset) eq 0 then begin
    ;; set the plotting window
    if n_elements(win_id) eq 0 then widget_control,(*data).plot_id,get_value=win_id
    wset,win_id
endif

;; load the colors
col=getcolor(/load)

;; which photometry system are we using?
psys=(*data).usesys

;; get the X values
n=n_elements((*(*data).images))
if (*data).plot_xmode eq 'mjd' then begin
    x=(*(*data).images).mjd
    ex=(*(*data).images).mjd+(*(*data).images).efftime/3600./24.
    xtitle='MJD'
endif else if (*data).plot_xmode eq 'tburst' then begin
    ;; burst times in seconds
    x=((*(*data).images).mjd-(*data).mjd)*24.0*3600.0
    ex=x+(*(*data).images).efftime

    jd0=(*data).mjd+2400000.5d
    caldat,jd0,mon,day,year,hour,min,sec
    month=month_cnv(mon)
    sec='00'+nicetext(sec,2)
    sec=strmid(sec,strlen(sec)-5)
    sjd0=string(year,month,day,hour,min,sec,format='(i4," ",a3," ",i2.2,", ",2(i2.2,":"),a," UT")')
    xtitle='Seconds After '+sjd0

    if 0 then begin
        x=(*(*data).images).mjd-(*data).mjd
        ex=x+(*(*data).images).efftime/3600./24.
        maxx=max(x)
        if maxx gt 1.0 then begin
            xtitle='tburst (days)'
        endif else if maxx*24.0 gt 1.0 then begin
            xtitle='tburst (hours)'
            x=x*24.0
            ex=ex*24.0
        endif else if maxx*24.0*60.0 gt 1.0 then begin
            xtitle='tburst (minutes)'
            x=x*24.0*60.0
            ex=ex*24.0*60.0
        endif else begin
            xtitle='tburst (seconds)'
            x=x*24.0*3600.0
            ex=ex*24.0*3600.0
        endelse
    endif
endif else begin
    x=indgen(n)
    ex=x
    xtitle='image index'
endelse

;; get the Y values
showmag=(*data).plot_ymode eq 'mag'
r=(*(*data).images).ratio[psys]
dr=(*(*data).images).eratio[psys]
if (*data).plot_mode eq 'target' then begin
    ;; plot target counts
    title=(*data).name+' Light Curve'
    ytitle='Relative Flux'
    norm=abs((*(*data).images)[(*data).refi].counts[psys])
    if finite(norm) eq 0 then norm=1.0
    f=(*(*data).images).counts[psys]
    df=(*(*data).images).ecounts[psys]
    y=f/r/norm
    ey=sqrt( (df/r/norm)^2.0 + (dr*f/r^2.0/norm)^2.0 )
endif else if (*data).plot_mode eq 'refstar' then begin
    ;; plot refstar counts
    j=(*data).refstari
    if (*(*data).calib.use)[0] ne -1 then cmag=(*(*data).calib.refmag)[j] else cmag=0
    title='Refstar '+strtrim(j,2)+' Light Curve'
    if cmag ne 0 then title=title+' ('+(*data).calib.filter+'='+nicetext(cmag,2)+')'
    norm=abs((*(*(*data).images)[(*data).refi].refcounts)[psys,j])
    if finite(norm) eq 0 then norm=1.0
    rphot_get_relative_flux,data,y,ey,inds=j,psys=psys
    y=y/norm
    ey=ey/norm
endif else if (*data).plot_mode eq 'object' then begin
    ;; plot object counts
    j=(*data).objecti
    title='Object '+strtrim(j,2)+' Light Curve'
    norm=abs((*(*(*data).images)[(*data).refi].objcounts)[psys,j])
    if finite(norm) eq 0 then norm=1.0
    rphot_get_relative_flux,data,y,ey,inds=j,psys=psys,/allobjects
    y=y/norm
    ey=ey/norm
endif

sky=(*(*data).images).sky/r/norm
skynoise=(*(*data).images).skynoise/r/norm

;; sum data points?
suminds=(*(*data).images).sumind
if (*data).dosum eq 1 then begin
    ;; sum (skips inds less than 0)
    w=where(suminds ge 0,nw)
    temp=suminds[w]
    unq_sumis=temp[uniq(temp,sort(temp))]

    nsums=n_elements(unq_sumis)
    newx=dblarr(nsums)
    newex=dblarr(nsums)
    newy=dblarr(nsums)+!values.d_nan
    newey=dblarr(nsums)+!values.d_nan
    newskynoise=dblarr(nsums)+!values.d_nan

    for i=0,nsums-1 do begin
        w=where(suminds eq unq_sumis[i] and finite(y) eq 1,nw)
        if nw gt 0 then begin
            if 0 then begin
                ;; force chisq <= 1 (grow errorbars only)
                blah=wtaverage(y[w],ey[w])
                chisq=total((blah[0]-y[w])^2.0/(ey[w])^2.0)/(nw-1)
                cheat=1.00
                iter=0
                while nw gt 1 and chisq gt 1.0 do begin
                    cheat=cheat+0.001
                    blah=wtaverage(y[w],cheat*ey[w])
                    chisq=total((blah[0]-y[w])^2.0/(cheat*ey[w])^2.0)/(nw-1)
                    iter=iter+1
                    if iter gt 1e5 then break
                endwhile
            endif else cheat=1.0

            ;; get the average x,y values
            newx[i]=min(x[w])
            newex[i]=max(ex[w])
            blah=wtaverage(y[w],cheat*ey[w])
            newy[i]=blah[0]
            newey[i]=blah[1]

            blah=wtaverage(sky[w],skynoise[w])
            newskynoise[i]=blah[1]
        endif
    endfor
    x=newx
    ex=newex
    y=newy
    ey=newey
    skynoise=newskynoise
    suminds=unq_sumis
endif else begin
    ;; skip where sumind=-1
    ;; w=where((*(*data).images).sumind eq -1,nw)
endelse

;; are we blind?
if (*data).plot_mode eq 'target' and (*data).blind eq 1 then begin
    ;; just show S/N
    title=(*data).name+' S/N'
    ytitle='S/N'
    showmag=0
    y=y/ey
    ey[*]=0
endif

;; add photometry name to plot title
title=title+' ('+(*data).photnames[psys]+')'

;; zeropoint for the skynoise
noisezp=(*data).zp[0]-2.5*alog10(norm)

;; just plot good data
w=where(finite(y) eq 1 and suminds ge 0,nw)

;; change x, ex to mean time, halfwidth
x=(x+ex)/2.0
ex=ex-x
if nw gt 0 then xrange=[min(x[w]-ex[w]),max(x[w]+ex[w])]

;; plot it
if nw gt 0 then begin
    if showmag then begin
        ;; convert flux to magnitudes
        ;; add zeropoint if calibration available
        mag=dblarr(n)
        memag=dblarr(n)
        pemag=dblarr(n)
        mag[*]=!values.d_nan
        memag[*]=!values.d_nan
        pemag[*]=!values.d_nan
        if (*data).zp[psys] ne 0 then begin
            ytitle='ROTSE Magnitude'
            zp=(*data).zp[psys]-2.5*alog10(norm)
        endif else begin
            ytitle='Relative Mag'
            zp=0
        endelse
        w2=where(y gt 0,nw2)
        if nw2 gt 0 then mag[w2]=-2.5*alog10(y[w2])+zp
        w2=where(y-ey gt 0,nw2)
        if nw2 gt 0 then pemag[w2]=-2.5*alog10(y[w2]-ey[w2])+zp
        w2=where(y+ey gt 0,nw2)
        if nw2 gt 0 then memag[w2]=-2.5*alog10(y[w2]+ey[w2])+zp

        ;; get plotting range
        w2=where(finite(memag[w]) eq 1 and finite(pemag[w]) eq 1,nw2)
        w3=where(finite(memag[w]) eq 1 and finite(pemag[w]) eq 0,nw3)
        w4=where(finite(memag[w]) eq 1 and finite(mag[w]) eq 1,nw4)
        w5=where(finite(memag[w]) eq 1 and finite(mag[w]) eq 0,nw5)
        if nw2 gt 0 then begin
            minmag=min(memag[w[w2]])
            maxmag=max(pemag[w[w2]])
            yrange=[maxmag,minmag]
        endif else begin
            wok=where(finite(memag[w]) and finite(mag[w]) eq 1,nwok)
            if nwok gt 0 then begin
                minmag=min(memag[w[wok]])
                maxmag=max(mag[w[wok]])
                yrange=[maxmag,minmag]
            endif
        endelse

        ;; plot
        plot,x[w],mag[w],psym=4,title=title,xtitle=xtitle,ytitle=ytitle,xstyle=3,ystyle=3 $
            ,xlog=(*data).plot_xlog,yrange=yrange,xrange=xrange
        oploterror,x[w],mag[w],ex[w],intarr(nw),ps=4

        ;; mark S/N > 3 points in bold
        wreal=where(y[w]/ey[w] gt 3.0,nw)
        if nw gt 0 then oplot,x[w[wreal]],mag[w[wreal]],psym=4,thick=2

        ;; plot mag error bars
        if nw2 gt 0 then errplot,x[w[w2]],memag[w[w2]],pemag[w[w2]]
        if nw4 gt 0 then oploterror,x[w[w4]],mag[w[w4]],mag[w[w4]]-memag[w[w4]],/lobar,ps=4
        xlen=!d.x_vsize/100.0 
        ylen=xlen
        for i=0,nw3-1 do begin
            devc=convert_coord(x[w[w3[i]]],mag[w[w3[i]]],/to_device)
            plots,[devc[0],devc[0]],[devc[1],devc[1]-3*ylen],/device,noclip=0
            plots,[devc[0]-xlen,devc[0]],[devc[1]+ylen,devc[1]]-3*ylen,/device,noclip=0
            plots,[devc[0]+xlen,devc[0]],[devc[1]+ylen,devc[1]]-3*ylen,/device,noclip=0
        endfor

        ;; show limiting magnitudes
        wsort=sort(x[w])
        oplot,x[w[wsort]],-2.5*alog10(3*skynoise[w[wsort]])+noisezp,ps=10,color=col.orange,linestyle=0        
        
        ;; plot calib magnitudes and average magnitude
        avy=wtaverage(y[w],ey[w])
        avmag=-2.5*alog10(avy[0])+zp
        xrange=!x.crange
        if (*data).plot_xlog eq 1 then xrange=10.0^xrange
        if (*data).plot_mode ne 'target' then oplot,xrange,[avmag,avmag],color=col.cyan
        if (*data).plot_mode eq 'refstar' then begin
            oplot,xrange,[cmag,cmag],color=col.red
        endif

        ;; save data?
        if keyword_set(save_data) then begin
            limmag=-2.5*alog10(3*skynoise)+noisezp
            openw,lun,save_data,/get_lun
            printf,lun,';; '+xtitle+'    etburst       mag        -emag       +emag      limmag'
            for i=0,n_elements(x)-1 do begin
                printf,lun,x[i],ex[i],mag[i],memag[i],pemag[i],limmag[i],format='(f16.6,f12.5,f12.5,f12.5,f12.5,f12.5)'
            endfor
            close,lun
            free_lun,lun
        endif

       y=mag
    endif else begin
        plot,x[w],y[w],ps=4,title=title,xtitle=xtitle,ytitle=ytitle,xstyle=3,ystyle=3,xlog=(*data).plot_xlog,xrange=xrange
        ;;oploterror,x[w],y[w],ey[w],ps=4
        oploterror,x[w],y[w],ex[w],ey[w],ps=4

        ;; mark S/N > 3 points in bold
        w2=where(y[w]/ey[w] gt 3.0,nw)
        if nw gt 0 then oplot,x[w[w2]],y[w[w2]],psym=4,thick=2

        ;; show limiting flux
        if (*data).blind eq 0 then begin
            wsort=sort(x[w])
            oplot,x[w[wsort]],3*skynoise[w[wsort]],ps=10,color=col.orange,linestyle=0
        endif

        ;; save data?
        if keyword_set(save_data) then begin
            openw,lun,save_data,/get_lun
            printf,lun,';; '+xtitle+'        etburst          flux           eflux'
            for i=0,n_elements(x)-1 do begin
                printf,lun,x[i],ex[i],y[i],ey[i]
            endfor
            close,lun
            free_lun,lun
        endif
    endelse

    if (*data).dosum eq 0 then begin
        ;; show current image in green
        oplot,[x[(*data).current_image]],[y[(*data).current_image]],ps=8,color=col.green,thick=2
        
        ;; show reference image in red
        oplot,[x[(*data).refi]],[y[(*data).refi]],ps=8,color=col.red
    endif
endif

;; show fit?

if keyword_set(save_plot) then begin
    device,/close
    set_plot,'x'
endif

;; store the plotting var clip region
(*data).plot_clip=!p.clip

end

;; ********************************************************************************
pro rphot_image_clicked,event
COMPILE_OPT IDL2

;; responds to user mouse clicks on the main image window. Depending
;; on the mode, this could mean (un)selecting a target/refstar,
;; zooming in on the image, or selecting an object for closeup display.

;; load colors
col=getcolor(/load)

if event.press eq 0 then return

widget_control,event.top,get_uvalue=data
ims=(*(*data).images)[(*data).current_image]

;; set the plotting window
widget_control,event.id,get_value=win_id
wset,win_id

;; determine the image x,y coord of the click
clip=(*data).image_clip
winx=clip[2]-clip[0]
winy=clip[3]-clip[1]
offset=clip[0:1]

if (*data).display_mode eq 'checks' then begin
    ;;coord=convert_coord(event.x,event.y,/device,/to_data)
    ;;x=coord[0]
    ;;y=coord[1]
    x=event.x
    y=event.y
    dist=(*(*data).plotdatax-x)^2 + (*(*data).plotdatay-y)^2
    mindist=sqrt(min(dist,wmin))

    ind=(*(*data).plotdataind)[wmin]
    refims=(*(*data).images)[(*data).refi]

    if widget_info((*data).check_mode_list_id,/droplist_select) eq 1 then begin
        refimx=(*refims.objx)[ind]
        refimy=(*refims.objy)[ind]
    endif else begin
        refimx=(*refims.refx)[0,ind]
        refimy=(*refims.refy)[0,ind]
    endelse

    ;; convert to current image x,y
    kmap,refimx,refimy,objx,objy,*ims.kx,*ims.ky
endif else begin
    zoom=(*(*data).images)[(*data).current_image].zoom
    plotx=zoom[2]-zoom[0]
    ploty=zoom[3]-zoom[1]

    stepx=float(plotx)/float(winx)
    x=(event.x-clip[0])*stepx+zoom[0]+ims.clip[0]
    stepy=float(ploty)/float(winy)
    y=(event.y-clip[1])*stepy+zoom[1]+ims.clip[1]
    
    ;;Find the closest object to click
    object='random'
    objx=x
    objy=y
    ;; is it the target?
    if sqrt((ims.x[0]-x)^2+(ims.y[0]-y)^2) le ims.fwhm then begin
        objx=ims.x[0]
        objy=ims.y[0]
        object='target'
    endif else begin
        ;; is it a refstar?
        dist=((*ims.refx)[0,*]-x)^2+((*ims.refy)[0,*]-y)^2
        mindist=sqrt(min(dist,wmin))
        if mindist le ims.fwhm then begin
            objx=(*ims.refx)[0,wmin]
            objy=(*ims.refy)[0,wmin]
            object='refstar'
        endif else begin
            ;; is it an object on the refim?
            refims=(*(*data).images)[(*data).refi]
            refimxs=*refims.objx
            refimys=*refims.objy
            
            ;; convert to current image x,y
            kmap,refimxs,refimys,objxs,objys,*ims.kx,*ims.ky
            
            dist=(objxs-x)^2+(objys-y)^2
            mindist=sqrt(min(dist,wmin))

            if mindist le ims.fwhm then begin
                objx=objxs[wmin]
                objy=objys[wmin]
                object='object'
            endif
        endelse
    endelse
endelse

;; what we do with that click depends on the mode
case (*data).display_mode of
    'image': begin
        case (*data).mode of
            'zoom': begin
                if not keyword_set(*ims.image) then return
                
                rphot_display_image,data,ims.imname
                drag_cursor,xyarr,color=col.green,/silent,/mess
                if(xyarr[2]-xyarr[0] lt 5 or xyarr[3]-xyarr[1] lt 5) then return
                zoom=[max([0,xyarr[0]]),max([0,xyarr[1]]),min([ims.nx-1,xyarr[2]]),min([ims.ny-1,xyarr[3]])]
                (*(*data).images)[(*data).current_image].zoom=long(zoom)
                rphot_display_image,data,ims.imname
            end
            
            'select': begin
                if (*data).just_one eq 1 and object ne 'random' then begin
                    ;; set new target
                    ims.x[0]=objx
                    ims.y[0]=objy
                    
                    if ims.ra eq -1 then begin
                        ;; set the ra and dec
                        dist=(*ims.objx-objx)^2+(*ims.objy-objy)^2
                        mindist=sqrt(min(dist,wmin))
                        if mindist le ims.fwhm then begin
                            ims.ra=(*ims.objra)[wmin]
                            ims.dec=(*ims.objdec)[wmin]
                        endif
                    endif
                    
                    ;; do aperture photometry on target
                    rphot_get_aper_counts,data,ims.x[0],ims.y[0],flux,eflux,lsky=lsky,skynoise=skynoise
                    ims.counts[0]=flux
                    ims.ecounts[0]=eflux
                    ims.sky=lsky
                    ims.skynoise=skynoise
                    
                    ;; redraw
                    (*(*data).images)[(*data).current_image]=ims
                    rphot_display_image,data,ims.imname
                endif else if (*data).just_one eq 3 then begin
                    ;; add/drop objects from the refim
                    
                    ;; can we centroid this object?
                    gcntrd,*ims.image,x,y,xcen,ycen,ims.fwhm,maxgood=ims.satcounts
                    w=where(xcen ne -1.0 and ycen ne -1.0,nw)
                    if nw eq 0 then begin
                        print,'!!! gcntrd could not find a centroid for that object !!!'
                    endif
                    
                    ;; is this already in the refim obj list?
                    close_match,*ims.objx,*ims.objy,xcen,ycen,m1,m2,0.75*ims.fwhm,1,missed1
                    if m1[0] ne -1 and n_elements(missed1) gt 0 then begin
                        *ims.objx=(*ims.objx)[missed1]
                        *ims.objy=(*ims.objy)[missed1]
                        *ims.objra=(*ims.objra)[missed1]
                        *ims.objdec=(*ims.objdec)[missed1]
                        *ims.objcounts=(*ims.objcounts)[missed1]
                        *ims.objecounts=(*ims.objecounts)[missed1]
                    endif else begin
                        ;; assume > 1 objects already in list
                        *ims.objx=[*ims.objx,xcen]
                        *ims.objy=[*ims.objy,ycen]
                        ;;*ims.objcounts=[*ims.objcounts,0]
                        ;;*ims.objecounts=[*ims.objcounts,-1.0]
                        
                        ;; get RA,DEC of object
                        astr_struct_new,1.85,astr
                        astr.crval=ims.crval
                        xy2rd,xcen,ycen,astr,ra,dec
                        *ims.objra=[*ims.objra,ra]
                        *ims.objdec=[*ims.objdec,dec]
                    endelse
                endif else if (*data).just_one eq 2 then begin
                    ;; substar add/drop
                    substars=*(*data).substars

                    ;; can we centroid this object?
                    gcntrd,*ims.image,objx,objy,xcen,ycen,ims.fwhm,maxgood=ims.satcounts
                    w=where(xcen ne -1.0 and ycen ne -1.0,nw)
                    if nw eq 0 then begin
                        print,'!!! gcntrd could not find a centroid for that object !!!'
                    endif

                    ;; is this already in the substar list?
                    if (*data).nsubstars gt 0 then w=where(substars.x eq xcen and substars.y eq ycen,nw,ncomp=nkeep,comp=wkeep) $
                    else nw=0
                    if nw gt 0 then begin
                        if nkeep gt 0 then *(*data).substars=substars[wkeep]
                        (*data).nsubstars=nkeep
                    endif else begin
                        newsubstar=replicate(substars[0],1)
                        newsubstar.x=xcen
                        newsubstar.y=ycen

                        ;; record counts, ecounts (### RA,DEC ??? ###
                        if object eq 'refstar' then begin
                            newsubstar.counts=(*ims.refcounts)[1,wmin]
                            newsubstar.ecounts=(*ims.refecounts)[1,wmin]
                        endif else if object eq 'object' then begin
                            newsubstar.counts=(*ims.objcounts)[1,wmin]
                            newsubstar.ecounts=(*ims.objecounts)[1,wmin]
                        endif else begin
                            print,'!!!!! substars must be objects/refstars for now'
                            return
                        endelse

                        if (*data).nsubstars eq 0 then begin 
                            *(*data).substars=newsubstar
                            (*data).nsubstars=1
                        endif else begin
                            *(*data).substars=[substars,newsubstar]
                            (*data).nsubstars=(*data).nsubstars+1
                        endelse
                    endelse
                endif else begin
                    ;; refstar add/drop
                    if (*ims.refx)[0] ne -1 and object eq 'refstar' then begin
                        ;; drop from refstar list
                        w2=where(lindgen(n_elements((*ims.refx)[0,*])) ne wmin,nw2)
                        if nw2 eq 0 then begin
                            *ims.refx=dblarr((*data).nphot)-1
                            *ims.refy=dblarr((*data).nphot)-1
                            *ims.refra=-1
                            *ims.refdec=-1
                            *ims.refcounts=dblarr((*data).nphot)+!values.d_nan
                            *ims.refecounts=dblarr((*data).nphot)+!values.d_nan
                        endif else begin
                            *ims.refx=(*ims.refx)[*,w2]
                            *ims.refy=(*ims.refy)[*,w2]
                            *ims.refra=(*ims.refra)[w2]
                            *ims.refdec=(*ims.refdec)[w2]
                            *ims.refcounts=(*ims.refcounts)[*,w2]
                            *ims.refecounts=(*ims.refecounts)[*,w2]
                        endelse
                    endif else begin
                        ;; add refstar
                        if (*ims.refx)[0] eq -1 then begin
                            *ims.refx=transpose([[objx],[-1.0d]])
                            *ims.refy=transpose([[objy],[-1.0d]])
                            *ims.refra=transpose([[(*ims.objra)[wmin]],[-1.0d]])
                            *ims.refdec=transpose([[(*ims.objdec)[wmin]],[-1.0d]])
                            ;;*ims.refx=[objx]
                            ;;*ims.refy=[objy]
                            ;;*ims.refra=[(*ims.objra)[wmin]]
                            ;;*ims.refdec=[(*ims.objdec)[wmin]]
                        endif else begin
                            *ims.refx=transpose([[reform((*ims.refx)[0,*]),objx],[reform((*ims.refx)[1,*]),-1.0d]])
                            *ims.refy=transpose([[reform((*ims.refy)[0,*]),objy],[reform((*ims.refy)[1,*]),-1.0d]])
                            *ims.refra=[*ims.refra,(*ims.objra)[wmin]]
                            *ims.refdec=[*ims.refdec,(*ims.objdec)[wmin]]
                        endelse
                    endelse
                    
                    (*(*data).images)[(*data).current_image]=ims
                    rphot_display_image,data,ims.imname,/skiprefphot
                endelse
            end

            else: begin
                case object of
                    'target': (*data).plot_mode='target'
                    'refstar': begin
                        (*data).plot_mode='refstar'
                        (*data).refstari=wmin[0]
                    end
                    'object': begin
                        (*data).plot_mode='object'
                        (*data).objecti=wmin[0]
                    end
                    else :
                endcase
                rphot_display_plot,data
            end
        endcase
    endcase

    'checks': begin
        if widget_info((*data).check_mode_list_id,/droplist_select) eq 1 then begin
            ;; plot object LC
            (*data).plot_mode='object'
            (*data).objecti=ind[0]
        endif else begin
            ;; plot refstar LC
            (*data).plot_mode='refstar'
            (*data).refstari=ind[0]
        endelse
        
        rphot_display_plot,data
    end
    
    else :
endcase

if (*data).mode ne 'zoom' then begin
    ;; display a closeup of the object
    rphot_display_closeup,data,objx[0],objy[0]
endif

end

;; ********************************************************************************
pro rphot_closeup_clicked,event
COMPILE_OPT IDL2

;; responds to user clicks on the closeup image. Will add/drop pixel(s)
;; from the target sky mask depending on which button was
;; pressed. Recalculates target counts.

if event.press eq 0 then return

widget_control,event.top,get_uvalue=data
if (*data).closeup_mode ne 'image' then return
ims=(*(*data).images)[(*data).current_image]

;; determine the image x,y coord of the click
rphot_display_closeup,data,/nodata
xy=convert_coord(event.x,event.y,/device,/to_data)
x=xy[0]
y=xy[1]

;; toggel the pixel mask
ind=long(round(x)+round(y)*ims.nx)
case event.press of
    1: begin
        ;; left mouse press
        ;; add 1 pixels
        *ims.mask=[*ims.mask,ind]
    end
    2: begin
        ;; center mouse press
        ;; add 9 pixels
        *ims.mask=[*ims.mask $
                   ,ind-1,ind,ind+1 $
                   ,ind-1-ims.nx,ind-ims.nx,ind+1-ims.nx $
                   ,ind-1+ims.nx,ind+ims.nx,ind+1+ims.nx]
    end
    4: begin
        ;; right mouse press
        ;; remove 1 pixel
        w=where(*ims.mask ne ind,nw)
        if nw eq 0 then *ims.mask=-1 else *ims.mask=(*ims.mask)[w]
    end
    8: begin
        ;; mouse-wheel down? press
        ;; remove 9 pixels
        w=where(*ims.mask ne ind-1 and *ims.mask ne ind and *ims.mask ne ind+1 $
                and *ims.mask ne ind-1-ims.nx and *ims.mask ne ind-ims.nx and *ims.mask ne ind+1-ims.nx $
                and *ims.mask ne ind-1+ims.nx and *ims.mask ne ind+ims.nx and *ims.mask ne ind+1+ims.nx,nw)
        if nw eq 0 then *ims.mask=-1 else *ims.mask=(*ims.mask)[w]
    end
    16: begin
        ;; mouse-wheel up? press
        ;; add 9 pixels
        *ims.mask=[*ims.mask $
                   ,ind-1,ind,ind+1 $
                   ,ind-1-ims.nx,ind-ims.nx,ind+1-ims.nx $
                   ,ind-1+ims.nx,ind+ims.nx,ind+1+ims.nx]
    end 
endcase

w=where(*ims.mask ne -1,nw)
if nw eq 0 then *ims.mask=-1 else *ims.mask=(*ims.mask)[w]
*ims.mask=(*ims.mask)[uniq(*ims.mask,sort(*ims.mask))]

;; recalculate target aperture flux
rphot_get_aper_counts,data,ims.x[0],ims.y[0],flux,eflux,lsky=lsky,skynoise=skynoise
ims.counts[0]=flux
ims.ecounts[0]=eflux
ims.sky=lsky
ims.skynoise=skynoise
(*(*data).images)[(*data).current_image]=ims

;; show the new target mask
rphot_display_closeup,data
rphot_display_plot,data

end

;; ********************************************************************************
pro rphot_plot_clicked,event
COMPILE_OPT IDL2

;; responds to user clicks on the plot window. Finds the closest data
;; point and sets it as the current image, then re-displays
;; everything.

if event.press eq 0 then return

;; get the xy location of the click
widget_control,event.top,get_uvalue=data
rphot_display_plot,data,x=xs,y=ys
xy=convert_coord(xs,ys,/to_device)
xs=xy[0,*]
ys=xy[1,*]
wok=where(finite(xs) eq 1 and finite(ys) eq 1,nwok)
if nwok eq 0 then begin
    print,'no valid data'
    return
endif
xs=xs[wok]
ys=ys[wok]

;; find closest data point to click
dist=(xs-event.x)^2.0+(ys-event.y)^2.0
mindist=sqrt(min(dist,wmin))

;; display that image
(*data).current_image=wok[wmin]
rphot_display_image,data
rphot_display_plot,data
rphot_display_closeup,data

end

;; ********************************************************************************
pro rphot_get_counts,event
COMPILE_OPT IDL2

;; recalculate photometry for the current image

widget_control,event.top,get_uvalue=data
ims=(*(*data).images)[(*data).current_image]

;; get the psf
if ims.fwhm eq 0 then begin
    rphot_get_psf,data,ims
    rphot_get_psf,data,ims
endif

;; do the photometry
rphot_do_photometry,data

;; redraw
rphot_display_image,data
rphot_display_plot,data

end

;; ********************************************************************************
pro rphot_get_aper_counts,data,x,y,flux,eflux,lsky=lsky,std=std,skynoise=skynoise,skys=skys,radius=radius,image=image
COMPILE_OPT IDL2

;; preforms aperature photometry on the current image. X and Y can be
;; arrays. If no mask exists for the current image and we are getting
;; target counts, transforms the refimage sky mask to the current
;; image, then checks for additional bad pixels (CRs, etc.). Otherwise
;; masks are calculated on the fly.

ims=(*(*data).images)[(*data).current_image]
if not keyword_set(radius) then radius=(*data).fixrad
if not keyword_set(image) then image=*ims.image

if n_elements(*ims.kx) eq 1 or n_elements(*ims.ky) eq 1 then begin
    print,"RPHOT: ref transform not yet calculated for"+ims.filename
    flux=!values.d_nan
    eflux=!values.d_nan
    lsky=0
    std=0
    skynoise=0
    return
endif

n=n_elements(x)
flux=dblarr(n)
eflux=dblarr(n)
skys=dblarr(n)
for i=0,n-1 do begin
    ;; is this the target?
    if x[i] eq ims.x[0] and y[i] eq ims.y[0] then begin
        ;; does a mask exist?
        if (*ims.mask)[0] eq -1 then begin
            if (*data).current_image eq (*data).refi then begin
                undefine,inmask
                noreject=0
            endif else begin
                ;; make one
                refims=(*(*data).images)[(*data).refi]
                refmask=*refims.mask
                refx=refmask mod refims.nx
                refy=refmask/refims.nx

                ;; dilate the mask by 0.2 pix
                refx=[refx-0.2,refx,refx+0.2 $
                      ,refx-0.2,refx,refx+0.2 $
                      ,refx-0.2,refx,refx+0.2 ]
                refy=[refy-0.2,refy-0.2,refy-0.2 $
                      ,refy,refy,refy $
                      ,refy+0.2,refy+0.2,refy+0.2]

                ;; transform the mask
                kmap,refx,refy,newx,newy,*ims.kx,*ims.ky
                inmask=long(round(newx)+round(newy)*ims.nx)
                inmask=inmask[uniq(inmask,sort(inmask))]
                noreject=0
            endelse
        endif else begin
            inmask=*ims.mask
            noreject=1
        endelse
    endif else begin
        undefine,inmask
        noreject=0
    endelse

    ;; reset sky radii
    skyrad1=(*data).skyrad1*((*data).fixrad > ims.fwhm) + 1.0
    skyrad2=(*data).skyrad2*((*data).fixrad > ims.fwhm)

    ;; do local sky subtraction
    niter=0
    naper=!pi*((*data).fixrad > ims.fwhm)^2.0
    repeat begin
        lsky=(get_local_sky(image,x[i],y[i],skyrad1,skyrad2 $
                            ,annulus=annulus,std=std,rej=rej,inmask=inmask,noreject=noreject))[0]
        nsky=n_elements(annulus)
        w=where(rej ne -1,nrej)
        nsky=nsky-nrej
        ;;w=where(noreject ne -1,nrej)
        ;;if noreject eq 0 then nsky=nsky-nrej
        niter=niter+1
        skyrad2=skyrad2+0.5*skyrad1
    endrep until nsky gt 2*naper or niter gt 8
    setsky=[lsky,std,nsky]
    skys[i]=lsky

    ;; save target mask
    if x[i] eq ims.x[0] and y[i] eq ims.y[0] and (*ims.mask)[0] eq -1 then begin
        ;; save the mask
        if (*data).current_image eq (*data).refi then *ims.mask=rej $
        else if rej[0] ne -1 then *ims.mask=[inmask,rej] $
        else *ims.mask=inmask
        w=where(*ims.mask ne -1,nw)
        if nw gt 0 then *ims.mask=(*ims.mask)[w]

        ;; record
        (*(*data).images)[(*data).current_image]=ims
    endif

    ;; ##### replace masked pixels inside the aper radius with profile
    ;; values #####

    ;; get the counts
    aper_rphot,image,x[i],y[i],f,ef,sky,esky,ims.gain,radius,[skyrad1,skyrad2],[0,0] $
        ,/flux,/exact,/silent,setskyval=setsky
    flux[i]=f
    eflux[i]=ef

    ;; calcualte the local sky noise
    area=!pi*radius^2.0
    skynoise=sqrt(area*std^2.0 + std^2.0/nsky*area^2.0)
endfor

w=where(finite(flux) eq 0,nw)
if nw gt 0 then begin
    print,"APER returned flux=NAN. It shouldn't. Use updated APER...stopping"
    stop
endif

end

;; ********************************************************************************
pro rphot_get_fitrad,data,ims,fitrad,psfrad
COMPILE_OPT IDL2

fitrads=linespace(1.5,4,step=0.05)
nfitrads=n_elements(fitrads)

;; do aperture photometry
rphot_get_aper_counts,data,ims.x[0],ims.y[0],f,ef,skys=sky
rphot_get_aper_counts,data,(*ims.refx)[0,*],(*ims.refy)[0,*],flux,eflux,skys=skys
mag=-2.5*alog10(f)+25
mags=-2.5*alog10(flux)+25

;; recentroid refstars
refx=(*ims.refx)[0,*]
refy=(*ims.refy)[0,*]
gcntrd,*ims.image,refx,refy,xcen,ycen,ims.fwhm,maxgood=ims.satcounts

radtol=0.75*ims.fwhm
w=where(xcen ne -1.0 and ycen ne -1.0 $
        and sqrt( (refx-xcen)^2.0 + (refy-ycen)^2.0 ) lt radtol $
        and flux/eflux gt 1.0 and flux/eflux lt 200.0,nobj)
if nobj eq 0 then begin
    ;; return unhappy
    fitrad=ims.fwhm
    psfrad=1.5*fitrad
    return
endif

emags=fltarr(nfitrads,nobj)
emags2=fltarr(nfitrads)
for i=0,nfitrads-1 do begin
    xs=xcen[w]
    ys=ycen[w]
    thisskys=skys[w]
    thismags=mags[w]

    fitrad=fitrads[i]
    psfrad=fitrads[i]*1.5
    inds=lindgen(nobj)
    magerr=-1

    ;; Calculate the local PSF (actually, the residuals from a gaussian)
    getpsf_rphot,*ims.image,xs,ys,thismags,thisskys $
      ,ims.ronoise,ims.gain,gauss,psf,inds,psfrad,fitrad,'',psfmag=psfmag,/quiet

    ;; group the stars together
    group,xs,ys,psfrad+fitrad,ngroup

    ;; nstar does the actual psf fitting
    nstar_rphot,*ims.image,inds,xs,ys,thismags,thisskys,ngroup,ims.gain,ims.ronoise,'',magerr $
      ,usepsf=psf,gauss=gauss,psfmag=psfmag,psfrad=psfrad,fitrad=fitrad,/silent

    emags[i,inds]=magerr

    ;; now for the target
    x=ims.x[0]
    y=ims.y[0]
    merr=-1
    nstar_rphot,*ims.image,inds,x,y,mag,sky,1,ims.gain,ims.ronoise,'',merr $
      ,usepsf=psf,gauss=gauss,psfmag=psfmag,psfrad=psfrad,fitrad=fitrad,/silent

    emags2[i]=merr
endfor

;; pick the best fitrad
best=intarr(nobj)
for i=0,nobj-1 do begin
    junk=min(emags[*,i],wmin)
    best[i]=wmin
endfor

cal=mrdfits(ims.cobjfile,2)

device,window_state=ws
w=where(ws ne 0,nw)
if nw gt 0 then oldwin=!d.window
if ws[2] ne 1 then window,2,xs=800,ys=800
wset,2

col=getcolor(/load)
plot,[0],[0],yrange=[5e-3,0.5],/ylog,xr=[min(fitrads),max(fitrads)],ys=1,xs=1,xtitle='FITRAD (pixels)',ytitle='Mag Error'
for i=0,nobj-1 do oplot,fitrads,emags[*,i],color=col.((i mod 10) + 3)
for i=0,nfitrads-1 do plots,fitrads[i],mean(emags[i,*]),thick=3,ps=4
oplot,fitrads,emags2,thick=2

oplot,[1,1]*cal.fwhm,10^!y.crange,linestyle=1
oplot,[1,1]*ims.fwhm,10^!y.crange,linestyle=0


if nw gt 0 then wset,oldwin


;; set fitrad, psfrad
fitrad=ims.fwhm
psfrad=1.5*fitrad

stop
end

;; ********************************************************************************
;; ##################
;; ##################
;; ##################
;; ##################
;; ##################
pro rphot_check_phot_mode,event
COMPILE_OPT IDL2

;; called when the user changes between refstars and objects in the
;; checks mode.

end

;; ********************************************************************************
pro rphot_do_check,event
COMPILE_OPT IDL2

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=plottype
rphot_check_photometry,data,plottype

end

;; ********************************************************************************
pro rphot_check_mag_rms,event
COMPILE_OPT IDL2

widget_control,event.top,get_uvalue=data
rphot_check_photometry,data,'mag_rms'

end

;; ********************************************************************************
pro rphot_check_rms_rms,event
COMPILE_OPT IDL2

widget_control,event.top,get_uvalue=data
rphot_check_photometry,data,'rms_rms'

end

;; ********************************************************************************
pro rphot_check_rms_mederr,event
COMPILE_OPT IDL2

widget_control,event.top,get_uvalue=data
rphot_check_photometry,data,'rms_mederr'

end

;; ********************************************************************************
pro rphot_check_photometry,data,plottype,ps=ps
COMPILE_OPT IDL2

;; make a plot of magnitude vs. RMS(time series mag) using all the
;; sources on the refim.

;;widget_control,event.top,get_uvalue=data
;;widget_control,event.id,get_uvalue=plottype

allobjects=widget_info((*data).check_mode_list_id,/droplist_select)
(*data).mode='checks'

;; load the refim
;;(*data).current_image=(*data).refi
;;rphot_load_image,data,(*(*data).images)[(*data).refi].imname

if keyword_set(ps) then begin
    set_plot,'ps'
    device,/landscape,file=plottype+'.ps',/color
endif else begin
    ;; set the plotting window
    widget_control,(*data).image_id,get_value=win_id
    wset,win_id
    (*data).display_mode='checks'
endelse

nphot=(*data).nphot
refims=(*(*data).images)[(*data).refi]
if keyword_set(allobjects) then nstars=n_elements(*refims.objx) $
else nstars=n_elements((*refims.refx)[0,*])
nimages=n_elements( (*(*data).images).imname )

zp=(*data).zp

;; get the relative flux in each aper
rphot_get_relative_flux,data,fluxes,efluxes,allobjects=allobjects

;; get the RMS for each star
mags=dblarr(nphot,nstars)
magrms=dblarr(nphot,nstars)
mederr=dblarr(nphot,nstars)
w=where((*(*data).images).sumind ge 0 and finite((*(*data).images).counts[0]) eq 1,nuse)
for i=0,nstars-1 do begin
    f0=finite(fluxes[0,*,i]) eq 1
    f1=finite(fluxes[1,*,i]) eq 1
    w=where(f0 and f1 and (*(*data).images).sumind ge 0,nw)
    if nw gt 2 and total(f0) gt 0.5*nuse and total(f1) gt 0.5*nuse then begin
        ;; convert to magnitudes
        for j=0,nphot-1 do begin
            ;;w=where(finite(fluxes[j,*,i]) eq 1 and (*(*data).images).sumind ge 0,nw)
            medflux=median(fluxes[j,w,i])
            mags[j,i]=-2.5*alog10(medflux)+zp[j]

            ;; calculate the RMS
            magrms[j,i]=2.5/alog(10)*stddev(fluxes[j,w,i])/medflux

            ;; calculate the median error
            mederr[j,i]=2.5/alog(10)*median(efluxes[j,w,i]/fluxes[j,w,i])
       endfor
    endif
endfor

;; get the skynoise
skynoise=sqrt(!pi)*(*(*data).images).fwhm * (*(*data).images).skynoise
skynoise=median(skynoise)

;; plot
col=getcolor(/load)
;;colors=[col.orchid,col.cyan,col.green,col.orange,col.red,col.pink]
colors=[col.cyan,col.magenta,col.yellow,col.orange,col.green,col.pink]
ncolors=n_elements(colors)
psysnames=(*data).photnames
case plottype of
    'mag_rms': begin
        plot,[0],[0],/ylog,ps=4,xtitle='Magnitude',ytitle='Time Series RMS',yr=[2e-3,2],xr=[10,20],/ys,title='Photometric Consistency',/nodata
        inds=lonarr(nphot,nstars)
        for i=0,nphot-1 do begin
            oplot,mags[i,*],magrms[i,*],ps=4,color=colors[i mod ncolors]
            inds[i,*]=lindgen(nstars)
        endfor
        legend,psysnames[0:nphot-1],colors=colors[indgen(nphot) mod ncolors],psym=4,/bottom,/right

        ;; convert to device coords
        coords=convert_coord(mags,magrms,/data,/to_device)
        *(*data).plotdatax=reform(coords[0,*])
        *(*data).plotdatay=reform(coords[1,*])
        *(*data).plotdataind=inds[*]

        if 1 then begin
            ;; show optimal error curve (photon + sky noise)
            mag=linespace(10,22,100)
            f=10.0^(-0.4*(mag-(*data).zp[0]))
            ef=sqrt(f)
            err=2.5/alog(10.0)*ef/f
            ;;oplot,mag,err,color=col.orange
            
            esky=2.5/alog(10.0)*skynoise/f
            ;;oplot,mag,esky,color=col.green
            oplot,mag,sqrt(err^2.0+esky^2.0)
        endif
    end

    'rms_rms': begin
        plot,[0],[0],ps=4,ys=3,xs=3,xr=[10,20],yr=[-1,1]*1.25,xtitle=(*data).photnames[0]+' Magnitude',ytitle='Fixed Aper RMS -  RMS Percent Difference',/nodata
        labels=strarr(nphot-1)
        mediandiffs=fltarr(nphot-1)

        ;; reset plotdatax,y
        *(*data).plotdatax=-1000
        *(*data).plotdatay=-1000
        *(*data).plotdataind=0

        inds=lindgen(nstars)
        for i=1,nphot-1 do begin
            percdiff=(magrms[0,*]-magrms[i,*])/magrms[0,*]
            w=where(finite(percdiff) eq 1,nw)
            if nw gt 0 then begin
                oplot,mags[0,w],percdiff[w],ps=4,color=colors[i mod ncolors]
                mediandiffs[i-1]=median(percdiff[w])
                diffstd=stddev(percdiff[w])
                oplot,!x.crange,[1,1]*mediandiffs[i-1],color=colors[i mod ncolors],linestyle=2

                labels[i-1]=string(psysnames[i],100*mediandiffs[i-1],100*diffstd,format='(a15," ",f5.1," +/- ",f5.1)')

                ;; store plotdatax,y
                coords=convert_coord(mags[0,w],percdiff,/data,/to_device)
                *(*data).plotdatax=[*(*data).plotdatax,reform(coords[0,*])]
                *(*data).plotdatay=[*(*data).plotdatay,reform(coords[1,*])]
                *(*data).plotdataind=[*(*data).plotdataind,inds[w]]
            endif else begin
                print,'RPHOT: no valid data to plot'
            endelse
        endfor
        w=reverse(sort(mediandiffs))
        legend,labels[w],colors=colors[w+1],linestyle=2+intarr(nphot-1),/top,/right
    end

    'rms_mederr': begin
        inds=lonarr(nphot,nstars)
        plot,[0],[0],/nodata,yr=[0,2],xr=[10,20],xtitle='Magnitude',ytitle='Time Series RMS / Median Error'
        for i=0,nphot-1 do begin
            oplot,mags[i,*],magrms[i,*]/mederr[i,*],ps=4,color=colors[i mod ncolors]
            inds[i,*]=lindgen(nstars)
        endfor
        legend,psysnames[0:nphot-1],colors=colors[indgen(nphot) mod ncolors],psym=4,/bottom,/right
        
        ;; convert to device coords
        coords=convert_coord(mags,magrms/mederr,/data,/to_device)
        *(*data).plotdatax=reform(coords[0,*])
        *(*data).plotdatay=reform(coords[1,*])
        *(*data).plotdataind=inds[*]
    end

    'mag_chisq': begin
        chisq=dblarr(nphot,nstars)
        for i=0,nphot-1 do begin
            for j=0,nstars-1 do begin
                w=where(finite(fluxes[i,*,j]) eq 1 and (*(*data).images).sumind ge 0,nw)
                if nw eq 0 then continue
                
                m=-2.5*alog10(fluxes[i,w,j])+zp[i]
                em=2.5/alog(10)*efluxes[i,w,j]/fluxes[i,w,j]
                chisq[i,j]=total( (m-mags[i,j])^2.0/em^2.0 )/(nw-1)
            endfor
        endfor

        inds=lonarr(nphot,nstars)
        plot,[0],[0],/nodata,yr=[0,2],xr=[10,20],xtitle='Magnitude',ytitle='Chisq/dof'
        for i=0,nphot-1 do begin
            oplot,mags[i,*],chisq[i,*],ps=4,color=colors[i mod ncolors]
            inds[i,*]=lindgen(nstars)
        endfor
        oplot,!x.crange,[1,1],linestyle=1
        legend,psysnames[0:nphot-1],colors=colors[indgen(nphot) mod ncolors],psym=4,/top,/right

       ;; convert to device coords
       coords=convert_coord(mags,chisq,/data,/to_device)
       *(*data).plotdatax=reform(coords[0,*])
       *(*data).plotdatay=reform(coords[1,*])
       *(*data).plotdataind=inds[*]
    end

    else: print,'RPHOT: plot type '+plottype+' not recgonized'
endcase

if keyword_set(ps) then begin
    device,/close
    set_plot,'x'
endif

end

;; ********************************************************************************
pro rphot_check_psf,event,data=data
COMPILE_OPT IDL2

;; check for variations in the psf across the refstars

if not keyword_set(data) then begin
    widget_control,event.top,get_uvalue=data
endif

;; ### just plot current image? ###
index=(*data).current_image

allobjects=widget_info((*data).check_mode_list_id,/droplist_select)
(*data).mode='checks'

;; set the plotting window
widget_control,(*data).image_id,get_value=win_id
wset,win_id
(*data).display_mode='checks'

refims=(*(*data).images)[(*data).refi]
if keyword_set(allobjects) then nstars=n_elements(*refims.objx) $
else nstars=n_elements((*refims.refx)[0,*])
nimages=n_elements( (*(*data).images).imname )  ;; ### set to 1 if not using other images ###

;; get the relative flux in each aper
rphot_get_relative_flux,data,fluxes,efluxes,allobjects=allobjects,imagei=index
nobjects=(size(fluxes))[3]

;; find the ratio of the flux to total flux in each aperture
;; (call biggest aperture the total flux)
maxrad=max((*data).radscale,wtot)
wuse=where((*data).radscale gt 0 and (*data).radscale ne maxrad,nratios)
ratios=dblarr(nratios,nimages,nobjects)
eratios=dblarr(nratios,nimages,nobjects)
for i=0,nratios-1 do begin
    ratios[i,*,*]=fluxes[wuse[i],*,*]/fluxes[wtot,*,*]
    eratios[i,*,*]=sqrt( (efluxes[wuse[i],*,*]/fluxes[wtot,*,*])^2.0 + (efluxes[wtot,*,*]*fluxes[wuse[i],*,*]/(fluxes[wtot,*,*])^2.0)^2.0 )
endfor

col=getcolor(/load)
colors=[col.cyan,col.magenta,col.yellow,col.orange,col.green,col.pink]
ncolors=n_elements(colors)
mags=-2.5*alog10(fluxes[wtot,index,*])+(*data).zp[wtot]
plot,mags,ratios[0,index,*],yr=[0,1.2],/nodata,title=(*(*data).images)[index].imname
chisqdofs=strarr(nratios)
for i=0,nratios-1 do begin
    ;;oploterr,mags,ratios[i,index,*],eratios[i,index,*],4
    oplot,mags,ratios[i,index,*],color=colors[wuse[i] mod ncolors],ps=4

    ;; get the chisq
    w=where(finite(ratios[i,index,*]) eq 1 and finite(eratios[i,index,*]) eq 1 and eratios[i,index,*] ne 0,nw)
    if nw gt 0 then begin
        bias=median(ratios[i,index,w])
        chisqdofs[i]=string(total( ((ratios[i,index,w]-bias)/eratios[i,index,w])^2.0 )/nw,format='(f6.3)')
    endif
endfor
legend,(*data).photnames[wuse]+' chisq/dof='+chisqdofs,colors=colors[wuse mod ncolors],psym=4,/bottom,/right

return

;; ### skip for now ###
ans=''
read,ans,prompt='Press enter for histograms: '

;; plot histograms
rmin=0
rmax=1.2
rbin=0.05
nbins=(rmax-rmin)/rbin
bins=rmin+findgen(nbins+1)*rbin
x=rmin+findgen(200)/200*rmax
plot,[0],[0],xr=[rmin,rmax],yr=[0,1.1],ys=1,xs=1,/nodata
for i=0,nratios-1 do begin
    hist=histogram(ratios[i,index,*],min=rmin,max=rmax,bin=rbin)
    oplot,bins,hist/float(max(hist)),ps=10,color=colors[wuse[i] mod ncolors]
endfor

end


;; ********************************************************************************
pro rphot_get_relative_flux,data,flux,eflux,allobjects=allobjects,imagei=imagei,inds=inds,psys=psys,target=target
COMPILE_OPT IDL2

;; return the flux and error for all images normalized to the refim
;; for refstars or all objects

if keyword_set(target) then begin
    if n_elements(psys) eq 0 then psys=(*data).usesys
    psys=psys[0] ;; *** only returns 1 system for now ***

    ;; get the target flux
    r=(*(*data).images).ratio[psys]
    dr=(*(*data).images).eratio[psys]
    f=(*(*data).images).counts[psys]
    df=(*(*data).images).ecounts[psys]
    flux=f/r
    eflux=sqrt( (df/r)^2.0 + (dr*f/r^2.0)^2.0 )
    return
endif

if n_elements(psys) gt 0 then nphot=n_elements(psys) $
else begin
    nphot=(*data).nphot
    psys=indgen(nphot)
endelse
refims=(*(*data).images)[(*data).refi]
if n_elements(inds) gt 0 then begin
    nstars=n_elements(inds)
endif else if keyword_set(allobjects) then begin
    nstars=n_elements(*refims.objx)
endif else begin
    nstars=n_elements((*refims.refx)[0,*])
endelse
if nstars gt 1 then print,nstars,format='("Getting relative fluxes for ",i5," objects...")'

;; loop over each image, normalize the flux
nimages=n_elements( (*(*data).images).imname )
flux=fltarr(nphot,nimages,nstars)+!values.f_nan
eflux=fltarr(nphot,nimages,nstars)+!values.f_nan
if n_elements(imagei) ne 0 then begin
    istart=imagei
    iend=imagei
endif else begin
    istart=0
    iend=nimages-1
endelse
for i=istart,iend do begin
    ims=(*(*data).images)[i]

    ;; make sure this image has been processed
    if finite(ims.counts[0]) eq 0 then continue

    ;; grab the target/refstar/object counts
    if keyword_set(allobjects) then begin
        f=*ims.objcounts
        df=*ims.objecounts
    endif else begin
        f=*ims.refcounts
        df=*ims.refecounts
    endelse


    ;; limit to specific objects
    if n_elements(inds) gt 0 then begin
        f=f[*,inds]
        df=df[*,inds]
    endif

    ;; convert aper to relative flux
    for j=0,nphot-1 do begin
        r=ims.ratio[psys[j]]
        flux[j,i,*]=f[psys[j],*]/r
        
        dr=ims.eratio[psys[j]]
        eflux[j,i,*]=sqrt( (df[psys[j],*]/r)^2.0 + (dr*f[psys[j],*]/r^2.0)^2.0 )
    endfor
endfor

end

;; ********************************************************************************
pro rphot_fit_lc,event
COMPILE_OPT IDL2

;; fit power-laws to the target and plot. Only the
;; (*data).usesys data is used.

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=fittype

;; see if we're still blind
if (*data).blind ne 0 then begin
    print,"RPHOT: You can't see the light curve until you turn off the blinding"
    return
endif

;; use exposure midpoint
etburst=(*(*data).images).efftime/2.0
tburst=((*(*data).images).mjd-(*data).mjd)*24.0*3600.0+etburst

;; get the target data
rphot_get_relative_flux,data,flux,eflux,/target,psys=psys

;; filter out invalid data
w=where(finite(flux) eq 1 and finite(eflux) eq 1 and (*(*data).images).sumind ge 0,ndata)
if ndata eq 0 then begin
    print,'RPHOT: No valid data to fit!'
    return
endif
tburst=tburst[w]
etburst=etburst[w]
flux=flux[w]
eflux=eflux[w]

;; run the fit
(*data).ndata=ndata
case fittype of
    'fitbreak': begin
        ;; calculate alpha1, alpha2, tbreak
        fitbreak,tburst,etburst,flux,eflux,f0,smooth,tbreak,alpha1,alpha2,ealpha1,ealpha2,etbreak,chisq
        ;;fitbreak,tburst,etburst,flux,eflux,smooth,alpha1,alpha2,eta,f0,tbreak,chisq
        (*data).alpha1=alpha1
        (*data).alpha2=alpha2
        (*data).smooth=smooth
        ;;(*data).eta=eta
        (*data).f0=f0
        (*data).tbreak=tbreak
        (*data).smoothchisq=chisq
        (*data).ealpha1[*]=ealpha1
        (*data).ealpha2[*]=ealpha2
        (*data).etbreak[*]=etbreak

    end

    else: begin
        ;; calculate alpha, offset
        fitalpha,tburst,etburst,flux,eflux,alpha,offset,chisq,ealpha
        (*data).alpha=alpha
        (*data).ealpha=ealpha
        (*data).offset=offset
        (*data).chisq=chisq
    end
endcase
    
;; show the fit
rphot_show_fit,data=data,fittype=fittype

end

;; ********************************************************************************
pro rphot_show_fit,event,data=data,fittype=fittype,ps=ps
COMPILE_OPT IDL2

if not keyword_set(data) then begin
    widget_control,event.top,get_uvalue=data
    widget_control,event.id,get_uvalue=fittype
endif

if keyword_set(ps) then begin
    set_plot,'ps'
    device,/landscape,filename=(*data).basedir+'rphot_'+fittype+'.ps',bits_per_pixel=8,/color
endif
col=getcolor(/load)

;; use the main window
if keyword_set(ps) eq 0 then widget_control,(*data).image_id,get_value=win_id

;; plot the target light curve
(*data).plot_mode='target'
rphot_display_plot,data,wset=win_id,nowset=ps
if not keyword_set(ps) then (*data).display_mode='fit'

;; use exposure midpoint
etburst=(*(*data).images).efftime/2.0
tburst=((*(*data).images).mjd-(*data).mjd)*24.0*3600.0+etburst
t=logspace(1,10*max(tburst),100)
ndata=(*data).ndata
case fittype of
    'fitalpha': begin
        model=(*data).offset*t^(*data).alpha
        oplot,t,-2.5*alog10(model)+(*data).zp[(*data).usesys],color=col.magenta,thick=2

        xyouts,0.72,0.85,'Alpha = '+nicetext((*data).alpha,3)+' +/- '+nicetext((*data).ealpha,3),/norm
        ;;s=textoidl('\chi^{2}')
        xyouts,0.70,0.9,'chisq/dof = '+nicetext((*data).chisq,1)+'/('+strtrim(ndata,2)+'-1) = '+nicetext((*data).chisq/(ndata-1.0),3),/norm
    end
    'fitbreak': begin
        alpha1=(*data).alpha1
        alpha2=(*data).alpha2
        smooth=(*data).smooth
        ;;eta=(*data).eta
        f0=(*data).f0
        tbreak=(*data).tbreak
        chisq=(*data).smoothchisq
        zp=(*data).zp[(*data).usesys]

        ;; show the smoothly broken fit
        model=f0*2.0^(1/smooth)*[ (t/tbreak)^(-smooth*alpha1) + (t/tbreak)^(-smooth*alpha2) ]^(-1/smooth)
        ;;model=f0*(t^(alpha1*smooth) + eta^(-smooth)*t^(alpha2*smooth))^(-1.0/smooth)
        oplot,t,-2.5*alog10(model)+zp,color=col.cyan,thick=2

        ;; show the break time
        ymin=!y.crange[0]
        arrow,tbreak,ymin-0.5,tbreak,ymin-0.2,/data,color=col.magenta,thick=3,hsize=!d.x_size/100
        xyouts,tbreak,ymin-0.6,nicetext(tbreak,1),align=0.5
        
        ;; show chisq
        ;;s=textoidl('\chi^{2}')
        ;;xyouts,0.7,0.9,'chisq/dof = '+nicetext(chisq,1)+'/('+strtrim(ndata,2)+'-3) = '+nicetext(chisq/(ndata-3.0),3),/norm
        xyouts,0.7,0.9,'chisq/dof = '+nicetext(chisq,1),/norm

        ;; give the alphas
        xyouts,0.8,0.85,'Alpha1 = '+nicetext((*data).alpha1,2),/norm
        xyouts,0.8,0.80,'Alpha2 = '+nicetext((*data).alpha2,2),/norm

        ;; give smoothness
        xyouts,0.8,0.75,'Smooth = '+nicetext(smooth,1),/norm
        
    end
    else: begin
        print,'RPHOT: Unknown fit type '+fittype
        return
    endelse
endcase

if keyword_set(ps) then begin
    device,/close
    set_plot,'x'
endif


end

;; ##################
;; ##################
;; ##################
;; ##################
;; ##################

;; ********************************************************************************
pro rphot_toggel_objects,event
COMPILE_OPT IDL2

;; Turns display of the target, refstars, calib stars, and objects on
;; and off (the circles on the image).

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=type

case type of
    'target': begin
        if (*data).show_target eq 1 then begin
            (*data).show_target=0
            widget_control,event.id,set_value='Show Target'
        endif else begin
            (*data).show_target=1
            widget_control,event.id,set_value='Hide Target'
        endelse
    end
    'refstars': begin
        if (*data).show_refstars eq 1 then begin
            (*data).show_refstars=0
            widget_control,event.id,set_value='Show Refstars'
        endif else begin
            (*data).show_refstars=1
            widget_control,event.id,set_value='Hide Refstars'
        endelse
    end
    'calibs': begin
        if (*data).show_calibs eq 1 then begin
            (*data).show_calibs=0
            widget_control,event.id,set_value='Show Calib Stars'
        endif else begin
            (*data).show_calibs=1
            widget_control,event.id,set_value='Hide Calib Stars'
        endelse
    end
    else: begin
        if (*data).show_objects eq 1 then begin
            (*data).show_objects=0
            widget_control,event.id,set_value='Show Objects'
        endif else begin
            (*data).show_objects=1
            widget_control,event.id,set_value='Hide Objects'
        endelse
    end
endcase

rphot_display_image,data
rphot_display_closeup,data

end


;; ********************************************************************************
pro rphot_done,event
COMPILE_OPT IDL2

;; shuts down rphot helper widgets when the user clicks "done"

widget_control,event.top,get_uvalue=data

;; blank the widget id
widget_control,event.id,get_uvalue=type
case type of
    'select_objects': begin
        ;; erase all data using old target
        rphot_wipe_data,data,/keepref,/keepk

        ;; do photometry
        refims=(*(*data).images)[(*data).refi]
        if (*data).just_one eq 0 then begin
            ;; get the psf
            if refims.fwhm eq 0 then begin
                rphot_get_psf,data,refims
                rphot_get_psf,data,refims
            endif

            ;; clip down objects to just those near refstars
            rphot_clip_refim_objects,refims

            ;; do the photometry
            rphot_do_photometry,data

            ;; read in cobjfile
            pho=mrdfits(refims.cobjfile,1)

            ;; match up refstars
            close_match,(*refims.refx)[0,*],(*refims.refy)[0,*],pho.x,pho.y,m1,m2,refims.fwhm,1,missed1

            ;; set ballpark zps
            if m1[0] ne -1 then begin
                print,'RPHOT: setting ZPs to APPROXIMATE values...'
                for i=0,(*data).nphot-1 do begin
                    zps=pho[m2].m+2.5*alog10((*refims.refcounts)[i,m1])
                    (*data).zp[i]=median(zps)
                endfor
            endif
        endif 

        ;; clear select mode
        (*data).select_objects_id=0
        (*data).mode='zoom'
    end
    'cancel_select': begin
        (*data).select_objects_id=0
        (*data).mode='zoom'
    end
    'show_image': (*data).show_image_id=0
    else:
endcase

;; good-bye
widget_control,event.top,/destroy

end

;; ********************************************************************************
pro rphot_save,event
COMPILE_OPT IDL2

;; saves the current *data structure (excluding the actual images and
;; widget_ids) using IDL's save routine.

widget_control,event.top,get_uvalue=data

file=dialog_pickfile(filter='*.sav',title='Save Photometry Data As',/write,file="rphot.sav",path=(*data).basedir)
if file eq '' then return

rphot_data=*data

;; don't save the images
for i=0,n_elements((*rphot_data.images).imname)-1 do begin
    *(*rphot_data.images)[i].image=0
endfor

;; dont't save the widget_ids
tags=tag_names(rphot_data)
for i=0,n_elements(tags)-1 do begin
    if strpos(tags[i],'_ID') ne -1 then begin
        rphot_data.(i)=0
    endif
endfor

save,rphot_data,filename=file

end 

;; ********************************************************************************
pro rphot_restore,event
COMPILE_OPT IDL2

;; restorse and IDL save file with data from a previous rphot
;; session. You start up right where you left off. If rpho.pro has
;; been alterned since the save, this may not work too well
;; (specifically, if the structure members change, bad things can
;; happen).

widget_control,event.top,get_uvalue=data

;; record current widget ids
tags=tag_names((*data))
ids=lonarr(n_elements(tags))-1
for i=0,n_elements(tags)-1 do begin
    if strpos(tags[i],'_ID') ne -1 then begin
        ids[i]=(*data).(i)
    endif
endfor

file=dialog_pickfile(filter='*.sav',title='Load Photometry Data',/read,file="rphot.sav",path=(*data).basedir)
if file eq '' then return

;; ##### check if the file exists #####

;; load the data file (stored in rphot_data variable)
restore,file

;; erase current *data values
for i=0,n_elements( (*(*data).images).imname)-1 do begin
    n_tags=n_tags((*(*data).images)[i])
    for j=0,n_tags-1 do begin
        info=size( (*(*data).images)[i].(j) )
        type=info[n_elements(info)-2]
        if type eq 10 then begin
            undefine,*(*(*data).images)[i].(j)
            ptr_free,(*(*data).images)[i].(j)
        endif
    endfor
endfor
ptr_free,(*data).substars
ptr_free,(*data).images
undefine,*(*data).calib.ra
undefine,*(*data).calib.dec
undefine,*(*data).calib.mag
undefine,*(*data).calib.emag
undefine,*(*data).calib.use
undefine,*(*data).calib.color
ptr_free,(*data).calib.ra
ptr_free,(*data).calib.dec
ptr_free,(*data).calib.mag
ptr_free,(*data).calib.emag
ptr_free,(*data).calib.use
ptr_free,(*data).calib.color

;; apply existing widget values
for i=0,n_elements(ids)-1 do begin
    if ids[i] ne -1 then begin
        rphot_data.(i)=ids[i]
    endif
endfor

;; set data to loaded file
blah=*data
struct_assign,rphot_data,blah,/nozero,/verbose
*data=blah
;;*data=rphot_data

;; ### update all the displayed settings so they match the saved
;; session ###

end 

;; ********************************************************************************
pro rphot_all_done,event
COMPILE_OPT IDL2

;; shuts down rphot cleanly--frees all the pointers.

;; free memory
widget_control,event.top,get_uvalue=data

for i=0,n_elements( (*(*data).images).imname)-1 do begin
    n_tags=n_tags((*(*data).images)[i])
    for j=0,n_tags-1 do begin
        info=size( (*(*data).images)[i].(j) )
        type=info[n_elements(info)-2]
        if type eq 10 then begin
            undefine,*(*(*data).images)[i].(j)
            ptr_free,(*(*data).images)[i].(j)
        endif
    endfor
endfor
ptr_free,(*data).images
undefine,*(*data).calib.ra
undefine,*(*data).calib.dec
undefine,*(*data).calib.mag
undefine,*(*data).calib.emag
undefine,*(*data).calib.use
ptr_free,(*data).calib.ra
ptr_free,(*data).calib.dec
ptr_free,(*data).calib.mag
ptr_free,(*data).calib.emag
ptr_free,(*data).calib.use
ptr_free,(*data).plotdatax
ptr_free,(*data).plotdatay
ptr_free,(*data).plotdataind
ptr_free,data

;; good-bye
widget_control,event.top,/destroy

end

;; ********************************************************************************
function rphot_new_image,imname,nphot
COMPILE_OPT IDL2

;; creates a new structure to hold image data. Tries to find the cobj
;; file associated with the imname.

if keyword_set(imname) then begin
    ;; find the cobjfile
    dir=strmid(imname,0,strpos(imname,'/',/REVERSE_SEARCH)-5)+'prod/'
    file=strmid(imname,strpos(imname,'/',/REVERSE_SEARCH)+1)
    file=strmid(file,0,strpos(file,'.fit'))+'obj.fit'
    cobjfile=dir+file
endif else cobjfile=''

temp = {                                                   $
         imname: imname,                                   $
         timestamp: 0.0d,                                  $
         image: ptr_new(0),                                $
         cobjfile: cobjfile,                               $
         sumind: 0L,                                       $
         mjd: 0.0d,                                        $
         exp: 0.0d,                                        $
         satcounts: 0L,                                    $
         satflux: 0.0d,                                    $
         satmag: 0.0d,                                     $
         ronoise: 0.0d,                                    $
         gain: 3.0d,                                       $
         nx: 0L,                                           $
         ny: 0L,                                           $
         xsub: [0L,0L],                                    $
         ysub: [0L,0L],                                    $
         clip: [0,0,0,0],                                  $
         zoom: [0,0,0,0],                                  $
         skymode: 0.0d,                                    $
         skysig: 0.0d,                                     $
         span: 0.0d,                                       $
         zero: 0.0d,                                       $
         kx: ptr_new(-1),                                  $
         ky: ptr_new(-1),                                  $
         crval: [0.0,0.0],                                 $
         rdkx: ptr_new(-1),                                $
         rdky: ptr_new(-1),                                $
         ra: -1.0d,                                        $
         dec: -1.0d,                                       $
         x: dblarr(nphot)-1,                               $
         y: dblarr(nphot)-1,                               $
         counts: dblarr(nphot)+!values.d_nan,              $
         ecounts: dblarr(nphot)+!values.d_nan,             $
         refra: ptr_new(-1),                               $
         refdec: ptr_new(-1),                              $
         refx: ptr_new(dblarr(nphot)-1),                   $
         refy: ptr_new(dblarr(nphot)-1),                   $
         refcounts: ptr_new(dblarr(nphot)+!values.d_nan),  $
         refecounts: ptr_new(dblarr(nphot)+!values.d_nan), $
         flags: ptr_new(0),                                $
         objra: ptr_new(-1),                               $
         objdec: ptr_new(-1),                              $
         objx: ptr_new(-1),                                $
         objy: ptr_new(-1),                                $
         objcounts: ptr_new(dblarr(nphot)+!values.d_nan),  $
         objecounts: ptr_new(dblarr(nphot)+!values.d_nan), $
         sky: !values.d_nan,                               $   ; make this an nphot element array
         skynoise: !values.d_nan,                          $   ; make this an nphot element array
         fwhm: 0.0d,                                       $
         ;;rad: 3.5d,                                        $
         ratio:  dblarr(nphot)+1,                          $
         eratio: dblarr(nphot),                            $
         psf: ptr_new(0),                                  $
         gauss: dblarr(5),                                 $
         psfmag: 0.0d,                                     $
         psfrad: 0.0d,                                     $
         fitrad: 0.0d,                                     $
         mask: ptr_new(-1),                                $
         medres: 0.0,                                      $
         efftime: 0.0d                                     $
       }

return,temp

end

;; ********************************************************************************
function rphot_copy_image,oldimage,nphot
COMPILE_OPT IDL2

;; returns a new image structure with all the fields coppied over from
;; oldimage (new pointers, same old data).

image=rphot_new_image(oldimage.imname,nphot)

n_tags=n_tags(image)
for i=0,n_tags-1 do begin
    info=size( image.(i) )
    type=info[n_elements(info)-2]
    if type eq 10 then *image.(i)=*oldimage.(i) $
    else image.(i)=oldimage.(i)
endfor

return,image

end

; ********************************************************************************
pro rphot_change_mode,event
COMPILE_OPT IDL2

;; Lets the user switch cleanly between zoom, adjust (span/zero), and
;; examine modes.

widget_control,event.top,get_uvalue=data
mode=((*data).mode_list)[widget_info((*data).mode_list_id,/droplist_select)]

rphot_change_mode_to,data,strlowcase(mode)

end

; ********************************************************************************
pro rphot_change_mode_to,data,mode
COMPILE_OPT IDL2

;; switch the current mode and update the widget display

widget_control,(*data).examine_options_id,map=0
widget_control,(*data).adjust_options_id,map=0
widget_control,(*data).zoom_options_id,map=0
widget_control,(*data).pmode_options_id,map=0
widget_control,(*data).pcheck_options_id,map=0
widget_control,(*data).analysis_options_id,map=0
(*data).mode=mode

case mode of
    'zoom': begin
        widget_control,(*data).zoom_options_id,map=1
    end
    'examine': begin
        widget_control,(*data).examine_options_id,map=1
    end
    'zero/span': begin
        widget_control,(*data).adjust_options_id,map=1
    end
    'photometry': begin
        widget_control,(*data).pmode_options_id,map=1
    end
    'checks': begin
        widget_control,(*data).pcheck_options_id,map=1
    end
    'analysis': begin
        widget_control,(*data).analysis_options_id,map=1
    end
    else: 
endcase

end

; ********************************************************************************
pro rphot_change_plot_mode,event
COMPILE_OPT IDL2

;; lets the user change the x and y plot format

index=widget_info(event.id,/droplist_select)

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=type

case type of
    'xmode': begin
        case index of
            0: (*data).plot_xmode='index'
            1: (*data).plot_xmode='mjd'
            2: (*data).plot_xmode='tburst'
            else:
        end
    end
    'xlog': (*data).plot_xlog=index
    'ymode': begin
        case index of
            0: (*data).plot_ymode='flux'
            1: (*data).plot_ymode='mag'
            else:
        end
    end
    else: 
endcase

rphot_display_plot,data

end

; ********************************************************************************
pro rphot_image_adjusted,event
COMPILE_OPT IDL2

;; redisplays the image when the span or zero changes.

widget_control,event.top,get_uvalue=data
widget_control,event.id,get_uvalue=type

ims=(*(*data).images)[(*data).current_image]

case type of
    'zero': rphot_set_zero,data,value=event.value
    'span': rphot_set_span,data,value=event.value
    'reset': begin
        rphot_set_zero,data,zero=ims.skymode-1.5*ims.skysig
        rphot_set_span,data,span=8*ims.skysig
    end
    else: 
endcase

rphot_display_image,data,(*(*data).images)[(*data).current_image].imname

end


;; ********************************************************************************
pro rphot_set_zero,data,value=value,zero=zero
COMPILE_OPT IDL2

;; value is an integer from 0 to 200
;; if value is set, set the image zero to zeros[value]
;; if zero is set, reflect the change on the widget value

barlen=200
ims=(*(*data).images)[(*data).current_image]
zeros=linespace(ims.skymode-10*ims.skysig,ims.skymode+10*ims.skysig,barlen+1)

if n_elements(value) gt 0 then begin
    (*(*data).images)[(*data).current_image].zero=zeros[value]
endif else if n_elements(zero) gt 0 then begin
    (*(*data).images)[(*data).current_image].zero=zero
    blah=min(abs(zeros-zero),value)
    widget_control,(*data).zero_id,set_value=value
endif

end

;; ********************************************************************************
pro rphot_set_span,data,value=value,span=span
COMPILE_OPT IDL2

;; value is an integer from 0 to 200
;; if value is set, set the image span to spans[value]
;; if span is set, reflect the change on the widget value

barlen=200
ims=(*(*data).images)[(*data).current_image]
spans=linespace(0.5*ims.skysig,20*ims.skysig,barlen+1)

if n_elements(value) gt 0 then begin
    (*(*data).images)[(*data).current_image].span=spans[value]
endif else if n_elements(span) gt 0 then begin
    (*(*data).images)[(*data).current_image].span=span
    blah=min(abs(spans-span),value)
    widget_control,(*data).span_id,set_value=value
endif

end


;; ********************************************************************************
pro rphot_save_lc_data,event
COMPILE_OPT IDL2

;; prints the lightcurve data to a file

;; get the output file name
widget_control,event.top,get_uvalue=data
file=dialog_pickfile(filter='*.dat',title='Save Light Curve Data As',/write,file="lightcurve.dat",path=(*data).basedir)
if file eq '' then return

;; save the data
rphot_display_plot,data,save_data=file


end

;; ********************************************************************************
pro rphot_save_lc_plot,event
COMPILE_OPT IDL2

;; outpurs the lightcurve to a file

;; get the output file name
widget_control,event.top,get_uvalue=data
file=dialog_pickfile(filter='*.ps',title='Save Light Curve Plot As',/write,file="lightcurve.ps",path=(*data).basedir)
if file eq '' then return

;; save the plot
rphot_display_plot,data,save_plot=file

end



;; ********************************************************************************
;; ********************************************************************************
pro rphot,data,imlist=imlist,refname=refname,name=name,small=small,targetra=ra,targetdec=dec $
          ,refra=refra,refdec=refdec,radecfile=radecfile,fixrad=fixrad,basedir=basedir,inskyrad=skyrad1,outskyrad=skyrad2
COMPILE_OPT IDL2

;+
; NAME:
;       RPHOT
; PURPOSE:
;    RPHOT is a widget designed to preform relative photometry on ROTSE
;    images. Its goal is to make the process of creating a light curve
;    as simple as possible for the user. The location of the target and
;    the refernece stars are automatically found as the user scrolls from
;    image to image, as are the object counts and relative image
;    zeropoints. As a completely automatic routine would eventually find
;    the limits of its usefulness, a pointer to the entire data
;    structure is maintained letting the user do things "by hand" as
;    necessary. 
;       
; TYPE:
; 	
; CALLING SEQUENCE:
;       rphot,data [,imlist=imlist, refname=refname, name=name]
; INPUTS:
;       
; OPTIONAL INPUTS:
; 	imlist --> list of image names to load
;       refname --> name of the reference image for the relative photometry
;       name --> name of the target
; KEYWORDS:
; 
; OUTPUTS:
;       data --> a pointer to the data structure
; COMMON BLOCKS:
; 	
; SIDE EFFECTS:
; 	
; EXAMPLES:
;
; PROCEDURE:
; 	
; MODIFICATION HISTORY:
;       Written by Robert Quimby, August 2003
;       Cleaned up a bit, RQ 11/2004
;       Added DAOPHOT PSF-fitting, multiple apertures, photometry
;       checks, RQ May 2005
;-

if N_params() lt 1 then begin
    print,'Syntax - rphot,data [,imlist=imlist, refname=refname, name=name]'
    return
endif

if not keyword_set(name) then name='Target'
if not keyword_set(basedir) then basedir=''

;; define circular plotting symbols
a=linespace(0,2*!pi,30)
usersym,1.5*cos(a),1.5*sin(a)

if not keyword_set(fixrad) then fixrad=3.5
if not keyword_set(skyrad1) then skyrad1=1.5 else skyrad1=float(skyrad1)
if not keyword_set(skyrad2) then skyrad2=4.0 else skyrad2=float(skyrad2)

;; photometry systems to try
;; [0] must be fixed radius(=fixrad)
;; [1] must be PSF-fit
;; negative values = fixed pixel size for all images
;; positive values = scale individual image FWHM by this much
sigtofwhm=2*sqrt(2*alog(2))
radscale=[-1.0*fixrad,-1.0*fixrad,1.0/sigtofwhm,1.7/sigtofwhm,2.0/sigtofwhm,1.0,2.0]
photnames=[nicetext(fixrad,1)+' pix Fixed Aper','PSF-fit','1.0 Sigma Aper','1.7 Sigma Aper','2.0 Sigma Aper','1 FWHM Aper','2 FWHM Aper']
nphot=n_elements(photnames)

;; draw window sizes (in pixels NxN)
if keyword_set(small) then image_size=[505,400] else image_size=[705,600]
if keyword_set(small) then closeup_size=[125,125] else closeup_size=[200,200]
if keyword_set(small) then plot_size=[375,125] else plot_size=[500,200]

;; *** this is the top level widget ***
base=widget_base(column=1,/base_align_center,title='ROTSE Photometry Console',mbar=menubar)

;; file menu widget base
file_menu=widget_button(menubar,VALUE='File',/MENU)
but=widget_button(file_menu,value='Save...',event_pro='rphot_save')
but=widget_button(file_menu,value='Restore...',event_pro='rphot_restore')
but=widget_button(file_menu,value='Save LC plot...',event_pro='rphot_save_lc_plot')
but=widget_button(file_menu,value='Save LC data...',event_pro='rphot_save_lc_data')
but=widget_button(file_menu,value='Save Match Struct...',event_pro='rphot_save_match_struct')
but=widget_button(file_menu,value='Save Target/Refstar RA DEC...',event_pro='rphot_save_radec')
but=widget_button(file_menu,value='EXIT',event_pro='rphot_all_done')

;; load menu widget base
load_menu=widget_button(menubar,VALUE='Load',/MENU)
but=widget_button(load_menu,value='Choose Images...',event_pro='rphot_choose_images')
but=widget_button(load_menu,value='Add Images...',event_pro='rphot_add_images')
but=widget_button(load_menu,value='Choose Ref Image...',event_pro='rphot_choose_refim')

;; object menu widget base
object_menu=widget_button(menubar,VALUE='Object',/MENU)
but=widget_button(object_menu,value='Choose Target...',event_pro='rphot_choose_object',uval=1)
but=widget_button(object_menu,value='Choose Refstars...',event_pro='rphot_choose_object',uval=0)
but=widget_button(object_menu,value='Add Objects...',event_pro='rphot_choose_object',uval=3)
but=widget_button(object_menu,value='Choose SubStars...',event_pro='rphot_choose_object',uval=2)
but=widget_button(object_menu,value='Calibrate...',event_pro='rphot_get_calib')
but=widget_button(object_menu,value='Get Counts',event_pro='rphot_get_counts')

;; display menu widget base
display_menu=widget_button(menubar,VALUE='Display',/MENU)
but=widget_button(display_menu,value='Display Image...',event_pro='rphot_show_image')
but=widget_button(display_menu,value='Hide Objects',event_pro='rphot_toggel_objects',uval='objects')
but=widget_button(display_menu,value='Hide Refstars',event_pro='rphot_toggel_objects',uval='refstars')
but=widget_button(display_menu,value='Hide Calib Stars',event_pro='rphot_toggel_objects',uval='calibs')
but=widget_button(display_menu,value='Hide Target',event_pro='rphot_toggel_objects',uval='target')

;; help button
help_menu=widget_button(menubar,VALUE='Help',/MENU,/help)
help=widget_button(help_menu,VALUE='Help!')

;; the mode options line
mode_options=widget_base(base,row=1,/base_align_left)
mode_list=['Zoom','Zero/Span','Examine','Photometry','Checks','Analysis']
mode_list_id=widget_droplist(mode_options,value=mode_list,event_pro='rphot_change_mode')
options=widget_base(mode_options,/base_align_left)

;; zooming
zoom_options=widget_base(options,row=1,/base_align_left)
but=widget_button(zoom_options,value='Zoom In 2x',event_pro='rphot_adjust_zoom',uval='in2x')
but=widget_button(zoom_options,value='Zoom Out 2x',event_pro='rphot_adjust_zoom',uval='out2x')
but=widget_button(zoom_options,value='Auto Zoom',event_pro='rphot_adjust_zoom',uval='auto')
but=widget_button(zoom_options,value='Zoom All',event_pro='rphot_adjust_zoom',uval='all')

;; examining objects
examine_options=widget_base(options,row=1,/base_align_left,map=0)
plot_mode_list=widget_droplist(examine_options,value=['Image Index','MJD','tburst'] $
                               ,event_pro='rphot_change_plot_mode',title='X-axis',uvalue='xmode')
plot_mode_list=widget_droplist(examine_options,value=['Linear','Log'] $
                               ,event_pro='rphot_change_plot_mode',uvalue='xlog')
plot_mode_list=widget_droplist(examine_options,value=['Flux','Magnitude'] $
                               ,event_pro='rphot_change_plot_mode',title='Y-axis',uvalue='ymode')
but=widget_button(examine_options,value='Redraw',event_pro='rphot_change_plot_mode',uval='redraw')

;; image span/zero
size=200
adjust_options=widget_base(options,row=1,/base_align_left,map=0)
zero=widget_slider(adjust_options,title='Zero',/SUPPRESS_VALUE,xsize=size,event_pro='rphot_image_adjusted' $
                   ,uvalue='zero',value=size/2,minimum=0,maximum=size)
span=widget_slider(adjust_options,title='Span',/SUPPRESS_VALUE,xsize=size,event_pro='rphot_image_adjusted' $
                   ,uvalue='span',value=size/2,minimum=0,maximum=size)
but=widget_button(adjust_options,value='Reset',event_pro='rphot_image_adjusted',uval='reset')

;; Photometry mode
pmode_options=widget_base(options,row=1,/base_align_left,map=0)
phot_mode_list_id=widget_droplist(pmode_options,value=photnames $
                                   ,event_pro='rphot_change_phot_mode',title='')
but=widget_button(pmode_options,value='Unblind',event_pro='rphot_unblind')
but=widget_button(pmode_options,value='Un-Bin',event_pro='rphot_bin_data',uval='unbin')
but=widget_button(pmode_options,value='Log Bin',event_pro='rphot_bin_data',uval='log')
but=widget_button(pmode_options,value='10/Bin',event_pro='rphot_bin_data',uval='10')
but=widget_button(pmode_options,value='No Bad',event_pro='rphot_bin_data',uval='nobad')
but=widget_button(pmode_options,value='No REF',event_pro='rphot_bin_data',uval='noref')
but=widget_button(pmode_options,value='Reset INDs',event_pro='rphot_bin_data',uval='reset')

;; Photometry checks
pcheck_options=widget_base(options,row=1,/base_align_left,map=0)
check_mode_list_id=widget_droplist(pcheck_options,value=['Refstars','All Objects'] $
                                   ,event_pro='rphot_check_phot_mode',title='',uvalue='objmode')
but=widget_button(pcheck_options,value='Mag vs. RMS',event_pro='rphot_check_mag_rms')
but=widget_button(pcheck_options,value='RMS vs. RMS',event_pro='rphot_check_rms_rms')
but=widget_button(pcheck_options,value='RMS vs. Mederr',event_pro='rphot_check_rms_mederr')
but=widget_button(pcheck_options,value='Mag vs. Chisq',event_pro='rphot_do_check',uval='mag_chisq')
but=widget_button(pcheck_options,value='PSF',event_pro='rphot_check_psf',uval='psf')

;; Target Analysis
analysis_options=widget_base(options,row=1,/base_align_left,map=0)
but=widget_button(analysis_options,value='Fit Alpha',event_pro='rphot_fit_lc',uval='fitalpha')
but=widget_button(analysis_options,value='Fit Break',event_pro='rphot_fit_lc',uval='fitbreak')
but=widget_button(analysis_options,value='Show Alpha',event_pro='rphot_show_fit',uval='fitalpha')
but=widget_button(analysis_options,value='Show Break',event_pro='rphot_show_fit',uval='fitbreak')


;; window for displaying images
image_id=widget_draw(base,xsize=image_size[0],ysize=image_size[1],uvalue='image' $
                     ,/button_events,event_pro='rphot_image_clicked',frame=3)

;; bottom row for draw widgets
bottom=widget_base(base,row=1,/base_align_center)

;; object closeup view
closeup_id=widget_draw(bottom,xsize=closeup_size[0],ysize=closeup_size[1],uvalue='closeup' $
                       ,/button_events,event_pro='rphot_closeup_clicked',frame=1)
;; plot widget
plot_id=widget_draw(bottom,xsize=plot_size[0],ysize=plot_size[1],uvalue='plot' $
                    ,/button_events,event_pro='rphot_plot_clicked',frame=1)

;; through out image names with no data or no cobjfile
rphot_clean_imlist,data,imlist

;; put together the input inmage names
if keyword_set(imlist) eq 0 then imlist=['']
if keyword_set(refname) eq 0 then refname=''
imlist=[imlist,refname]
imlist=imlist[uniq(imlist,sort(imlist))]

n_images=n_elements(imlist)
images=[rphot_new_image(imlist[0],nphot)]
for i=1,n_images-1 do begin
    images=[images,rphot_new_image(imlist[i],nphot)]
endfor
refi=(where(imlist eq refname))[0]

;; struct for calibration data
calib={ filter: '',            $
        ra: ptr_new(0.0d),     $
        dec: ptr_new(0.0d),    $
        mag: ptr_new(0.0d),    $
        emag: ptr_new(0.0d),   $
        use: ptr_new(-1),      $
        refmag: ptr_new(0.0d), $
        color: ptr_new(0.0d)   $
      }

;; struct for stars to subtract
substars={                              $
           ra: -1.0d,                   $
           dec: -1.0d,                  $
           x: -1.0d,                    $ ; X-value on refim
           y: -1.0d,                    $ ; Y-value on refim
           counts: -1.0d,               $ ; flux (refim equivelent)
           ecounts: -1.0d               $ ; flux error (refim equivelent)
         }

;; *** record the widget values, image data, etc ***
temp = {                                     $
         name: name,                         $ ; target name
         main_id: base,                      $
         image_id: image_id,                 $
         closeup_id: closeup_id,             $
         plot_id: plot_id,                   $
         show_image_id: 0L,                  $
         select_objects_id: 0L,              $
         select_radius_id: 0L,               $
         select_minsn_id: 0L,                $
         ra_id: 0L,                          $
         dec_id: 0L,                         $
         span_id: span,                      $
         zero_id: zero,                      $
         imlist_id: 0L,                      $
         mode_list_id: mode_list_id,         $
         mode_list: mode_list,               $
         image_clip: !p.clip,                $
         closeup_clip: !p.clip,              $
         plot_clip: !p.clip,                 $
         zoom_options_id: zoom_options,      $
         examine_options_id: examine_options,$
         adjust_options_id: adjust_options,  $
         pmode_options_id: pmode_options,    $
         pcheck_options_id: pcheck_options,  $
         analysis_options_id: analysis_options,$
         just_one: 0L,                       $
         refname: refname,                   $
         refi: refi,                         $
         refstari: 0L,                       $
         objecti: 0L,                        $
         current_image: 0L,                  $
         mode: 'zoom',                       $
         plot_mode: 'target',                $
         plot_xmode: 'index',                $
         plot_ymode: 'flux',                 $
         plot_xlog: 0,                       $
         closeup_mode: 'image',              $
         show_objects: 1,                    $
         show_refstars: 1,                   $
         show_target: 1,                     $
         show_calibs: 1,                     $
         phot_mode_list_id: phot_mode_list_id,$
         check_mode_list_id: check_mode_list_id,$
         check_all: 1,                       $
         images: ptr_new(images),            $
         psf_npix: 15,                       $
         psf_grow: 5,                        $
         calib: calib,                       $
         zp: dblarr(nphot),                  $
         mjd: 0.0d,                          $
         doskysub: 1,                        $
         dodao: 1,                           $
         usesys: 0,                          $
         dosum: 0,                           $
         blind: 1,                           $
         nphot: nphot,                       $
         photnames: photnames,               $
         radscale: radscale,                 $
         ndata: 0L,                          $
         alpha: !values.d_nan,               $
         ealpha: !values.d_nan,              $
         offset: !values.d_nan,              $
         chisq: 0.0,                         $
         alpha1: !values.d_nan,              $
         alpha2: !values.d_nan,              $
         smooth: !values.d_nan,              $
         eta: !values.d_nan,                 $
         f0: !values.d_nan,                  $
         tbreak: !values.d_nan,              $
         smoothchisq: 0.0,                   $
         fixrad: abs(radscale[0]),           $
         plotdatax: ptr_new(-1),             $
         plotdatay: ptr_new(-1),             $
         plotdataind: ptr_new(-1),           $
         warnings: ptr_new(''),              $
         basedir: basedir,                   $
         display_mode: 'image',              $
         ealpha1: [-1.0,-1.0],               $
         ealpha2: [-1.0,-1.0],               $
         esmooth: [-1.0,-1.0],               $
         etbreak: [-1.0,-1.0],               $
         skyrad1: skyrad1,                   $ ; inner sky radius / (aper radius)
         skyrad2: skyrad2,                   $ ; outter sky radius / (aper radius)
         nsubstars: 0,                       $
         substars: ptr_new(substars)         $
       }

data = ptr_new(temp,/no_copy)
widget_control,base,set_uvalue=data

;; were we given a file with the RA and DECs of all the refstars and
;; target?
if keyword_set(radecfile) then begin
    readcol,radecfile,ras,decs,format='(d,d)',/silent
    ra=ras[0]
    dec=decs[0]
    refra=ras[1:*]
    refdec=decs[1:*]
endif

;; were we passed the refstar RAs and DECs?
if keyword_set(refname) and n_elements(refra) gt 0 and n_elements(refdec) gt 0 then begin
    ;; get the refims
    refims=(*(*data).images)[(*data).refi]

    ;; set the refstar RAs, DECs
    ;;rphot_rd2xy,refims.cobjfile,refra,refdec,xs,ys
    rphot_rd2xy,crval,rdkx,rdky,refra,refdec,xs,ys,cobjfn=refims.cobjfile

    blank=dblarr(n_elements(xs))-1
    *refims.refx=transpose([[xs],[blank]])
    *refims.refy=transpose([[ys],[blank]])
    *refims.refra=refra
    *refims.refdec=refdec
endif

;; were we passed the target RA,DEC?
if keyword_set(refname) and n_elements(ra) gt 0 and n_elements(dec) gt 0 then begin
    ;; get the refims
    refims=(*(*data).images)[(*data).refi]

    ;; set the target RA, DEC
    ;;rphot_rd2xy,refims.cobjfile,ra,dec,x,y
    rphot_rd2xy,crval,rdkx,rdky,ra,dec,x,y,cobjfn=refims.cobjfile

    refims.x[0]=x
    refims.y[0]=y
    refims.ra=ra
    refims.dec=dec
        
    ;; record
    (*(*data).images)[(*data).refi]=refims
endif

;; were we passed both the target and the refstar positions?
if keyword_set(refname) and n_elements(ra) gt 0 and n_elements(dec) gt 0 $
  and n_elements(refra) gt 0 and n_elements(refdec) gt 0 then begin
    ;; load ref
    rphot_load_image,data,refname

    ;; clip down objects to just those near refstars
    rphot_clip_refim_objects,refims
endif

;; *** show everything ***
widget_control,base,/realize
xmanager,'rphot',base,/no_block

end
