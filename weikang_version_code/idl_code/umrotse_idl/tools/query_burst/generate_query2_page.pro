pro generate_query2_page,basedir,nameroot,coaddjpeglist,ra,dec,imdir=imdir,cobjdir=cobjdir,box=box

if n_params() lt 4 then begin
    print,'syntax- generate_query2_page,basedir,nameroot,coaddjpeglist,ra,dec,imdir=imdir,cobjdir=cobjdir,box=box'
    return
endif

cd,basedir

if n_elements(imdir) eq 0 then imdir = 'image/'
if n_elements(cobjdir) eq 0 then cobjdir = 'prod/'
if n_elements(box) eq 0 then box = 0.07

;; find the coadd images we have
images = findfile(imdir + '*3?*-*_c.fit', count = numimages)

rabits=sixty(ra/15d)
decbits=sixty(dec)
sign = '+'
if (dec lt 0.0) then sign = '-'

radecstr=string(rabits[0],format='(i2.2)') + $
  string(rabits[1],format='(i2.2)') + $
  string(rabits[2],format='(i2.2)') + sign + $
  string(abs(decbits[0]), format='(i2.2)') + $
  string(decbits[1], format='(i2.2)') + $
  string(decbits[2], format='(i2.2)')

jpegsforlist=['']


;;openw,jlun,coaddjpeglist,/get_lun
;;added = 0

if (numimages eq 0) then begin
    print,'No images for querying...'
    ;; will have to do something here, probably -- and if not in image
endif else begin
    print,'Found ',numimages,' files'

;;    initialized = 0

    for i=0l,numimages-1 do begin
        imname = images[i]

        dirparts=strsplit(imname,'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
        jpgname = nameroot + '-' + radecstr + '-q_' + parts[2] + '.jpg'

        test=findfile(basedir+'/'+jpgname,count=tct)
        tct = 0
        if (tct eq 0) then begin
;;            if (not initialized) then begin
;;                openw,jlun,coaddjpeglist,/get_lun
;;                initialized = 1
;;            endif

            skip = 0
            full_image_name=find_rotse3_image(images[i],path=['.',imdir],fail=fail)
            if (Fail eq 1) then begin
                print,'Could not find image: '+imname
                skip = 1
            endif

            full_cobj_name = find_rotse3_cobj(imname,path=['.',cobjdir],fail=fail)
            if (fail eq 1) then begin
                print,'Could not find cobj: '+imname
                skip = 1
            endif
            
            if (skip eq 0) then begin
                ;; make the jpegs
                cal=mrdfits(full_cobj_name,2)

                ;; modify caption
                nparts=strsplit(jpgname,'_',/extract)
                bparts=strsplit(nparts[0],'-',/extract)
                caption=bparts[0]
                for k=1l,n_elements(nparts)-1 do begin
                    caption=caption+'_'+nparts[k]
                endfor
                
                radec_circle_new,cal,ra,dec,box=box,/finding,radius=0,errad=5, $
                  jpegname=jpgname,dim=[400,400],caption=caption,/compactlabel

                ;; make sure image got made
                test=findfile(jpgname,count=tct)
                if (tct eq 1) then begin
                    jpegsforlist=[jpegsforlist,jpgname]
                endif
                
            endif
        endif else begin
            print,jpgname+' is already there.'
        endelse
        
    endfor

endelse

;; and get the png name
pngname = nameroot + '-' + radecstr + '-qlc.png'


;; now look for the match structure
mtname=findfile(basedir + '/' + nameroot + '*match.fit',count=mct)

fndlc = 0

mjd = 0d
;;timestr = '0000 00 00.00'

if (mct gt 0) then begin
    mt=mrdfits(mtname[0],1)
    st=mrdfits(mtname[0],2)

    ;; 2 pixels
    close_match_radec,ra,dec,mt.ra,mt.dec,m1,m2,0.0009d*2,1
    
    if (m2[0] eq -1) then begin
        print,'Nothing found'

        ;; use the first time in the match structure
        mjd = mt.jd[0]
    endif else begin
        ;; want to use simple_lc_png for this

        if (st[0].trig_tjd gt 10000) then begin
            burst_mjd=double(st[0].trig_tjd) + 40000.0d + st[0].trig_t/(60d*60d*24d)
        endif else begin
            burst_mjd = double(floor(st[0].mjd)) + st[0].trig_t / (60d*60d*24d)
        endelse
        
        allobs=indgen(mt.nobs)
        times=(mt.jd[allobs] - burst_mjd) * 24d * 60d * 60d

        mags=mt.m[allobs,m2[0]]
        magerrs=mt.merr[allobs,m2[0]]
        notin=where(mags lt 0, nnot)
        if (nnot gt 0) then $
          mags[notin] = mt.m_lim[notin]

        simple_lc_png,pngname,times,mags,magerrs

        fndlc = 1
        
        ;; also, use the median time of all observations
        in=where(mags gt 0,nin)
        if (nin eq 1 or nin eq 2) then begin
            mjd = mt.jd[allobs[in[0]]]
        endif else begin
            mjd = median(mt.jd[allobs[in]])
        endelse
    endelse
endif

if (not fndlc) then begin
    ;; put a dummy here

    set_plot,'z'
    device,set_resolution=[600,300]
    xyouts,300,150,'Object Not Found',charsize=3,/device,alignment=0.5

    write_png,pngname,tvrd()

    set_plot,'x'

endif

;; and turn the mjd into a timestring
if (mjd eq 0d) then begin
    timestr='0000 00 00.00'
endif else begin
    caldat,mjd+2400000.5d,month,day,year,hour,minute,second
    fod=(hour + minute/60. + second/3600.)/24d

    timestr=string(year,format='(i4.4)') + ' ' + $
      string(month,format='(i2.2)') + ' ' + $
      string(day,format='(i2.2)') + '.' + string(fix(fod*100.),format='(i2.2)')

endelse


;;and write out the coaddjpeglist

openw,jlun,coaddjpeglist,/get_lun

rabits=sixty(ra/15d)
decbits=sixty(abs(dec))
sign = '+'
if (dec lt 0.0) then sign = '-'
rastr = string(fix(rabits[0]),format='(i2.2)') + ':' + $
  string(fix(rabits[1]),format='(i2.2)') + ':' + $
  string(fix(rabits[2]),format='(i2.2)') + '.' + $
  string(fix((rabits[2] - fix(rabits[2]))*100),format='(i2.2)')
                             
decstr = sign + string(fix(decbits[0]),format='(i2.2)') + ':' + $
  string(fix(decbits[1]),format='(i2.2)') + ':' + $
  string(fix(decbits[2]),format='(i2.2)') + '.' + $
  string(fix((decbits[2] - fix(decbits[2]))*100),format='(i2.2)')

printf,jlun,rastr+' '+decstr
printf,jlun,string(mjd,format='(f13.7)')+' '+timestr
printf,jlun,pngname

printf,jlun,n_elements(jpegsforlist)-1

for i=1l,n_elements(jpegsforlist)-1 do begin
    printf,jlun,jpegsforlist[i]
endfor

free_lun,jlun


return
end

