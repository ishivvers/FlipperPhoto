pro radec_circle_new,st,ra,dec,sts=sts,obs=obs,image=image,file=file,box=box,radius=radius,finding=finding,jpegname=jpegname,dim=dim,rarr1=rarr1,darr1=darr1,rarr2=rarr2,darr2=darr2,errad=errad,putfname=putfname,noskysub=noskysub,nolabel=nolabel,number1=number1,number2=number2,caption=caption,alternum=alternum,compactlabel=compactlabel,quality=quality

if n_params() eq 0 then begin
    print,'syntax- radec_circle_new,st,ra,dec,sts=sts,obs=obs,image=image,file=file,box=box,radius=radius,finding=finding,jpegname=jpegname,dim=dim,rarr1=rarr1,darr1=darr1,rarr2=rarr2,darr2=darr2,errad=errad,putfname=putfname,noskysub=noskysub,nolabel=nolabel,number1=number1,number2=number2,caption=caption,alternum=alternum,compactlabel=compactlabel,quality=quality'
    return
endif

if n_elements(quality) eq 0 then quality = 75

dname = !d.name


if tag_exist(st,'bitpix') then begin
    struct_type = 'cal'
endif else if tag_exist(st,'imagename') then begin
    struct_type = 'match'
    if n_elements(obs) eq 0 then begin
        print,'You need to specify the observation number with a match structure.'
        return
    endif else if obs gt n_elements(st.jd) then begin
        print,'Observation value out of range.'
        return
    endif
endif else begin
    print,'st not a valid structure type'
    return
endelse

if struct_type eq 'cal' then begin
    rac = st.rac
    decc = st.decc
    kx = reform(st.kx)
    ky = reform(st.ky)
    mjd = st.mjd
    imagename = st.filename
    sky = st.sky
    pixscale=st.cdelt1
endif else begin
    rac = st.rac[obs]
    decc = st.decc[obs]
    kx = reform(st.kx[obs,*,*])
    ky = reform(st.ky[obs,*,*])
    mjd = st.jd[obs]
    imagename = st.imagename[obs]
    if (n_elements(sts) gt 0) then begin
        sky = reform(sts[obs].sky)
        pixscale=sts[obs].cdelt1
    endif else begin
        noskysub = 1
        pixscale = 1.85/2048.
    endelse
endelse

if n_elements(image) eq 0 then begin
    if n_elements(file) eq 0 then begin
        fname = find_rotse3_image(imagename,fail=fail,path='image')
        if (fail) then begin
            print,'Image '+ imagename + ' not found.'
            return
        endif
        fname=fname[0]
    endif else begin
        fname=findfile(file,count=count)
        if (count eq 0) then begin
            print,'File not found: ',file
            return
        endif
        fname=fname[0]
    endelse
    thisimage=readfits(fname)
endif else if (size(image))[0] ne 2 then begin
    print,'image not a valid two-dimensional array.'
    return
endif else begin
    thisimage = image
endelse

if not keyword_set(noskysub) then begin
    if tag_exist(st,'imsub') then begin
        cparts=strsplit(st.imsub,',',/extract)
        xparts=strsplit(cparts[0],':',/extract)
        yparts=strsplit(cparts[1],':',/extract)

        xsub=[long(xparts[0]),long(xparts[1])]
        ysub=[long(yparts[0]),long(yparts[1])]
    endif

    sub_sky,thisimage,sky,newimage,xsub=xsub,ysub=ysub
    thisimage=newimage
endif

if n_elements(jpegname) ne 0 then begin
    set_plot,'z'
    if n_elements(dim) ne 2 then dim = [1024,1024]
    device,set_resolution=dim
    jpeg=1
endif

if not keyword_set(finding) then begin
    title = '(RA,DEC)=('+ntostr(ra,9)+','+$
      ntostr(dec,9)+') ; MJD = '+string(mjd,format='(F12.5)')

    setupplot
;;!p.charsize=0.5
 
    plot_rotse3_image,thisimage,rac,decc,kx,ky,ra,dec,title=title,box=box,radius=radius, $
                      jpeg=jpeg,rarr1=rarr1,darr1=darr1,rarr2=rarr2,darr2=darr2,jps=jps, $
                      errad=errad,fail=fail,nolabel=nolabel,number1=number1,number2=number2, $
                      caption=caption,alternum=alternum,pixscale=pixscale
  
endif else begin
    setupplot

    if n_elements(radius) eq 0 then radius=-1
    plot_rotse3_image,thisimage,rac,decc,kx,ky,ra,dec,box=box,radius=radius, $
                      /nolabel,lims=lims,rotate=1,skylims=skylims,fail=fail, $
                      jpeg=jpeg,rarr1=rarr1,darr1=darr1,rarr2=rarr2,darr2=darr2,jps=jps, $
                      errad=errad,number1=number1,number2=number2,caption=caption,alternum=alternum,pixscale=pixscale

    if (fail eq 0 and not keyword_set(nolabel)) then begin

        if (keyword_set(jpeg)) then begin
            tv,jps[0,*,*]
            annotate_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,mjd,rotate=1, $
              putfname=putfname,imagename=imagename,dim=dim,compactlabel=compactlabel
            jps[0,*,*] = tvrd()
            tv,jps[1,*,*]
            annotate_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,mjd,rotate=1, $
              putfname=putfname,imagename=imagename,dim=dim,compactlabel=compactlabel
            jps[1,*,*] = tvrd()
            tv,jps[2,*,*]
            annotate_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,mjd,rotate=1, $
              putfname=putfname,imagename=imagename,dim=dim,compactlabel=compactlabel
            jps[2,*,*] = tvrd()
        endif else begin
            annotate_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,mjd,rotate=1, $
              putfname=putfname,imagename=imagename,compactlabel=compactlabel
        endelse
       
    endif

endelse

if n_elements(jpegname) ne 0 and fail eq 0 then begin
    write_jpeg,jpegname,jps,/true,quality=quality
endif

set_plot,dname

return
end
