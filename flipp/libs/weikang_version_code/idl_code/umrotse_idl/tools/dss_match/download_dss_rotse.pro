pro download_dss_rotse,ra,dec,radius,dss_name=dss_name,nosave=nosave, $
  dss_image=dss_image,dss_hdr=dss_hdr,date=date,plot=plot,fail=fail

if n_params() lt 3 then begin
    print,'syntax- download_dss_rotse,ra,dec,radius,dss_name=dss_name,nosave=nosave,dss_image=dss_image,dss_hdr=dss_hdr,date=date,plot=plot,fail=fail'
    return
endif

fail = 0

if n_elements(date) eq 0 then date = '000000'

if n_elements(dss_name) eq 0 then begin
    ;; generate dss_name
    dss_name = generate_rotse3_fname(date,'dss',ra,dec,'x')
endif

full_dss_name=find_rotse3_image(dss_name,path=['.','image'],/noarchive,fail=ffail)

if (ffail eq 1) then begin    
    ;; we need to download it
    print,'Downloading DSS image...'

    ;; this needs some checks

    i=0
    imfound = 0
    while (i lt 2 and (not imfound)) do begin
        if (i eq 0) then begin
            stsci = 1
            eso = 0
        endif else begin
            stsci = 0
            eso = 1
        endelse

        catch, error_status
        if (error_status ne 0) then begin
            print,'Error in querydss!'
        endif else begin

            querydss,[ra,dec],dss_image,dss_hdr,imsize=fix(2.*radius*60.), $
              survey='2r',stsci=stsci,eso=eso

        endelse
        catch,/cancel

        szi=size(dss_image)
        szh=size(dss_hdr)
        if (szi[0] eq 2 and szh[0] eq 1) then begin
            if (szi[1] gt 0 and szi[2] gt 0) then begin
                print,'Download successful.'
                imfound = 1
            endif
        endif

        i=i+1
    endwhile

    if (not imfound) then begin
        print,'Unable to download DSS image.  Sorry!'
        fail = 1
        return
    endif
    
    ;; now, we need to save it (where?)
    if (not keyword_set(nosave)) then begin

        ;; check if an 'image' subdirectory exists

        test=findfile('-d image/',count=ct)
        if (ct gt 0) then begin
            full_dss_name = 'image/' + dss_name + '_c.fit'
        endif else begin
            print,'There does not appear to be an image subdirectory.  Saving in current directory'
            full_dss_name = dss_name + '_c.fit'
        endelse
        
        
        print,'Saving DSS image as '+full_dss_name
        writefits,full_dss_name,dss_image,dss_hdr
    endif
endif else begin
    print,'Reading DSS image...'
    dss_image = readfits(full_dss_name,dss_hdr)
endelse

dss_hdr = dss_hdr[0:100]

if keyword_set(plot) then begin
    plot_dss_image,dss_image,dss_hdr,ra,dec,box=radius
endif

return
end
