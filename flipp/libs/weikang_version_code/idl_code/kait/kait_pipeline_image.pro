pro kait_pipeline_image,fitimagename

if n_params() eq 0 then begin
    print,'kait_pipeline_image,fitimagename'
    return
endif

if fitimagename[0] eq '' then begin
  print,'No image inputer, doing nothing!'
  exit
endif

;pipeline_dir='/kait/pipeline/'
operation_dir='/kait/web/operation/'
datastorage_dir='/kait/oridata/'

for i=0,n_elements(fitimagename)-1 do begin
  print,'Working on : ',fitimagename[i]
  ;Figure out the jpeg file name if not given
  strs=strsplit(fitimagename[i],'/')
  oribasename=strmid(fitimagename[i],strs[n_elements(strs)-1],strlen(fitimagename[i]))
  strreplace,oribasename,'.fits',''
  strreplace,oribasename,'.fit',''
  strreplace,oribasename,'.fts',''
  strreplace,oribasename,'.FITS',''
  strreplace,oribasename,'.FIT',''
  strreplace,oribasename,'.FTS',''
  
  image=mrdfits(fitimagename[i],0,hdr,/fscale,/silent)
  
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
  plotdim=[550,550]
  
  ;Add UT time, figure out correct title
  objectname=sxpar(hdr,'OBJECT')
  objectname=strtrim(objectname,2)
  strreplace,objectname,' ','_'
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
  
  filter=sxpar(hdr,'FILTERS')
  filter=strtrim(filter,2)
  if filter eq '' then filter='X'
  
  ra=sxpar(hdr,'RA')
  ra=strmid(ra,0,8)
  dec=sxpar(hdr,'DEC')
  dec=strmid(dec,0,9)
  strreplace,dec,'.',''
  ha=sxpar(hdr,'HA')
  ha=string(ten(ha),format='(f6.3)')
  
  ;check if the thumnaild date directory is there or not, just mkdir anyway
  date1dir=operation_dir+'/thumb_archive/'+year2+month+day
  if not file_test(date1dir) then begin
    print,date1dir
    cmd='mkdir '+date1dir
    spawn,cmd
    ;this is for updating the date on operation page
    cmd="sed -i 's/<option selected>/<option selected>"+year2+month+day+"\n        <option>/' /kait/web/operation/index.html"
    spawn,cmd
  endif
  date2dir=datastorage_dir+'/'+year2+month+day
  if not file_test(date2dir) then begin
    print,date2dir
    cmd='mkdir '+date2dir
    spawn,cmd
  endif
  
  ;newfilenamebase=year2+month+day+'_'+objectname+'_'+oribasename+'_'+filter+'_c'
  newfilenamebase=year2+month+day+'_'+objectname+'_'+oribasename+'_'+filter
  
  jpegname=date1dir+'/'+newfilenamebase+'.jpg'
  fitname=date2dir+'/'+newfilenamebase+'.fit'
  ;titlename=year+'-'+month+'-'+day+' '+hour+':'+minute+':'+second
  titlename=year2+month+day+'T'+hour+':'+minute+':'+second+' r'+ra+' d'+dec+' ha'+ha
  touchtag=year2+month+day+hour+minute+'.'+second
  ;print,year,month,day,hour,minute,second
  ;print,newfilenamebase
  ;print,fitname
  ;print,jpegname
  ;print,titlename
  ;print,touchtag
  
  ;make jpeg thumbnails
  ss_regions_to_jpeg,image,jpegname=jpegname,quality=70,dim=plotdim,title=titlename
  
  ;move data to be archived
  cmd='mv -f '+fitimagename[i]+'  '+fitname
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
  
end
