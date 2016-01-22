pro kait_pipeline

;if n_params() eq 0 then begin
;    print,'kait_pipeline'
;    return
;endif

pipeline_dir='/kait/pipeline/'
operation_dir='/kait/web/operation/'
datastorage_dir='/kait/oridata/'

while (1) do begin

  f0=findfile(pipeline_dir+'/*.Z')
  nb=n_elements(f0)
  if nb ne 0 and f0[0] ne '' then begin
    for i=0,nb-1 do begin
      ;print,f0[i]
      unzipfile=f0[i]
      strreplace,unzipfile,'.Z',''
      cmd="gunzip "+f0[i]
      print,cmd
      spawn,cmd
    endfor
  endif

  f1=findfile(pipeline_dir+'/*.fts')
  f2=findfile(pipeline_dir+'/*.grid')
  
  f=[f1,f2]
  
  nb=n_elements(f)
  if nb eq 0 then begin
    print,'No new file found, doing nothing'
    return
  endif
  
  for i=0,nb-1 do begin
  
    if f[i] eq '' then break
    print,'Working on : ',f[i]
    ;Figure out the jpeg file name if not given
    strs=strsplit(f[i],'/')
    oribasename=strmid(f[i],strs[n_elements(strs)-1],strlen(f[i]))
    strreplace,oribasename,'.fits',''
    strreplace,oribasename,'.fit',''
    strreplace,oribasename,'.fts',''
    strreplace,oribasename,'.FITS',''
    strreplace,oribasename,'.FIT',''
    strreplace,oribasename,'.FTS',''
    
    image=mrdfits(f[i],0,hdr,/fscale,/silent)
    
    sky,image,sky,skyerr,/silent
    sigmaL=-1.0
    sigmaH=5.0
    slow=sky+skyerr*sigmaL
    shigh=sky+skyerr*sigmaH
    
    ;cmd="fits2jpeg -fits "+fitsfilename+" -jpeg "+jpegname+" -min "+string(slow) + " -max "+string(shigh)+" -quality "+string(quality)
    ;if keyword_set(nonLinear) then cmd=cmd+' -nonLinear'
    ;;print,cmd
    ;spawn,cmd
    
    ;This is another option to get jpeg, also easy
    ;Generate the thumbnail for operation page, doesn't need to be very big
    plotdim=[500,500]
    
    ;Add UT time, figure out correct title
    objectname=sxpar(hdr,'OBJECT')
    objectname=strtrim(objectname,2)
    date=sxpar(hdr,'DATE-OBS')
    date=strtrim(date,2)
    uttime=sxpar(hdr,'UT')
    uttime=strtrim(uttime,2)
    day=strmid(date,0,2)
    month=strmid(date,3,2)
    year=strmid(date,6,4)
    year2=strmid(date,8,2)
    hour=strmid(uttime,0,2)
    minute=strmid(uttime,3,2)
    second=strmid(uttime,6,2)
    
    ;check if the thumnaild date directory is there or not, just mkdir anyway
    date1dir=operation_dir+'/thumb_archive/'+year2+month+day
    if not file_test(date1dir) then begin
      print,date1dir
      cmd='mkdir '+date1dir
      spawn,cmd
    endif
    date2dir=datastorage_dir+'/'+year2+month+day
    if not file_test(date2dir) then begin
      print,date2dir
      cmd='mkdir '+date2dir
      spawn,cmd
    endif
  
    newfilenamebase=year2+month+day+'_'+objectname+'_'+oribasename+'_c'
  
    jpegname=date1dir+'/'+newfilenamebase+'.jpg'
    fitname=date2dir+'/'+newfilenamebase+'.fit'
    titlename=year+'-'+month+'-'+day+' '+hour+':'+minute+':'+second
    touchtag=year2+month+day+hour+minute+'.'+second
    ;print,fitname
    ;print,jpegname
    ;print,titlename
    ;print,touchtag
  
    ;make jpeg thumbnails
    ss_regions_to_jpeg,image,jpegname=jpegname,quality=70,dim=plotdim,title=titlename
  
    ;move data to be archived
    cmd='mv -f '+f[i]+'  '+fitname
    ;print,cmd
    spawn,cmd
    cmd='touch -c -t '+touchtag+'  '+jpegname
    ;print,cmd
    spawn,cmd
    cmd='touch -c -t '+touchtag+'  '+fitname
    ;print,cmd
    spawn,cmd
    cmd='gzip -f '+fitname
    ;print,cmd
    spawn,cmd
  
  endfor

print,'sleeping 60 second ...'
wait, 60
endwhile

end
