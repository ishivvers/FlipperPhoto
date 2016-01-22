pro write_cobja, c, h, cal_list, imhdr, nomod=nomod,pixscale=pixscale

  sobjhdr = headfits(c.sobj)

;Get the elevation for the stats file
  elev=sxpar(imhdr,'elev')
  if (!err ne 0) then begin
      elev=0.0
  endif

if not keyword_set(pixscale) then begin
  if (sxpar(imhdr,'PIXSCALE') ne 0) then begin
    pixscale=sxpar(imhdr,'PIXSCALE')
  endif else begin
    ;print,'Warning : PIXSCALE not found, using 0 instead, may cause problems'
    pixscale=0.7965
  endelse
endif

 naxis1=sxpar(imhdr,'NAXIS1')
 naxis2=sxpar(imhdr,'NAXIS2')

; Find the new ra center, dec center, and WCS stuff:
  centX=naxis1/2
  centY=naxis2/2
  diff=abs(cal_list.X-centX)+abs(cal_list.Y-centY)
  diffID=sort(diff)
  centID=diffID[0]
  
  ;print,"ID: ",centID
  newrac=cal_list[centID].ra
  newdecc=cal_list[centID].dec
  crpix1=cal_list[centID].x
  crpix2=cal_list[centID].y
  wcs_matrix_struct,pixscale,astr
  astr.crval = [newrac,newdecc]
  astr.crpix = [crpix1,crpix2]
  kx=h.kx
  ky=h.ky
; the following sets the rotation matrix and offsets for the fits header:
  pc001001=kx(0,1)/(sqrt(kx(0,1)^2+kx(1,0)^2))
  pc001002=kx(1,0)/(sqrt(kx(0,1)^2+kx(1,0)^2))
  pc002001=ky(0,1)/(sqrt(ky(0,1)^2+ky(1,0)^2))
  pc002002=ky(1,0)/(sqrt(ky(0,1)^2+ky(1,0)^2))
;; the following are the x and y offsets.  Note that they are only approximately centered.
;  crpix1=-1*(-kx(1,0)*ky(0,0)+kx(0,0)*ky(1,0))/(-kx(1,0)*ky(0,1)+kx(0,1)*ky(1,0))
;  crpix2=-1*(kx(0,1)*ky(0,0)-kx(0,0)*ky(0,1))/(-kx(1,0)*ky(0,1)+kx(0,1)*ky(1,0))


; First, we need to know which wcs variables have already been put into the fits header:  Updated by zwk, deleted old ones any way, then add new one

; First, for very old images we need to add in _all_ the WCS stuff.
  test_nowcs=sxpar(imhdr,'ctype1')
  if (string(test_nowcs) ne '') then begin
      sxdelpar,imhdr,['CTYPE1', 'CTYPE2', 'CRPIX1','CRVAL1', 'CDELT1', 'CRPIX2','CRVAL2', 'CDELT2', 'PC001001','PC002002','PC001002','PC002001', 'CROTA1', 'CROTA2', 'CSOURCE', 'PIXSCALE', 'WCSDIM', 'CD1_1', 'CD1_2', 'CD2_1', 'CD2_2']
      sxaddpar,imhdr,'CTYPE1','RA---TAN',' RA, TAN projection used',after='BSCALE'
      sxaddpar,imhdr,'CRPIX1',0.0,' pixel at reference point',after='CTYPE1'
      sxaddpar,imhdr,'CRVAL1',0.0,' RA at the reference point',after='CRPIX1'
      sxaddpar,imhdr,'CDELT1',0.0,' increment per pixel (degrees)',after='CRVAL1'
      sxaddpar,imhdr,'CUNIT1','deg',' physical units of axis 1',after='CDELT1'
      sxaddpar,imhdr,'CTYPE2','DEC--TAN',' DEC, TAN projection used',after='CUNIT1'
      sxaddpar,imhdr,'CRPIX2',0.0,' pixel at reference point',after='CTYPE2'
      sxaddpar,imhdr,'CRVAL2',0.0,' DEC at the reference point',after='CRPIX2'
      sxaddpar,imhdr,'CDELT2',0.0,' increment per pixel (degrees)',after='CRVAL2'
      sxaddpar,imhdr,'CUNIT2','deg',' rotation of axis 2',after='CDELT2'
      sxaddpar,imhdr,'PIXSCALE',pixscale,' pixel scale of image',after='CUNIT2'
      sxaddpar,imhdr,'PC001001',0.0,'',after='PIXSCALE'
      sxaddpar,imhdr,'PC002002',0.0,'',after='PC001001'
      sxaddpar,imhdr,'PC001002',0.0,'',after='PC002002'
      sxaddpar,imhdr,'PC002001',0.0,'',after='PC001002'
      ;sxaddpar,imhdr,'CROTA1',0.0,' rotation of axis 1',after='CUNIT2'
      ;sxaddpar,imhdr,'CROTA2',180.0,' physical units of axis 2',after='CROTA1'
  endif

; Do a couple of basic checks on the calibration.  If it was very ugly, do not overwrite the header.
  goodcal=1
  if (h.zp_sigma gt 0.5) then begin ; first warning
      if (h.dec_high - h.dec_low) gt 9.0 then begin                      
          goodcal=0             ; there was an obvious problem with the matching
      endif
  endif

; Update the image header, imhdr:
  if (goodcal eq 1) then begin
      print,'Updating WCS information in fits header...'
      sxaddpar,imhdr,'CRPIX1',crpix1
      sxaddpar,imhdr,'CRPIX2',crpix2
      sxaddpar,imhdr,'CRVAL1',newrac
      sxaddpar,imhdr,'CRVAL2',newdecc
      sxaddpar,imhdr,'CDELT1',astr.cdelt[0]
      sxaddpar,imhdr,'CDELT2',astr.cdelt[1]
      sxaddpar,imhdr,'PC001001',pc001001
      sxaddpar,imhdr,'PC002002',pc002002
      sxaddpar,imhdr,'PC001002',pc001002
      sxaddpar,imhdr,'PC002001',pc002001
      ; now to overwrite the fits header, the fast way:
      if not keyword_set(nomod) then modfits,c.cimg,0,imhdr
  endif        

; Write the new-style cobj file, which has the form:
;  Extension 0:  Actual image header with dummy image
;  Extension 1:  cobj structure
;  Extension 2:  cal structure and the fits header variables put into the structure
;                        Also, an array with the sky values is inserted if _sky.fit is available.
  
      ;This first command creates the file and sticks a little dummy data 
      ;in the zero extension. This allows me to write the image header into
      ;this file
  dummyhdr=imhdr
  writefits,c.cobj,indgen(10,10),dummyhdr
      ;Now add the actual calibrated list to extension 1...
  mwrfits,cal_list,c.cobj
      ; Extract the header variables into a structure. Start with the first one...
  i=1
  varname=strtrim(strmid(imhdr(i),0,8))
  varval=sxpar(imhdr,varname)
  if (size(varval,/type) eq 4) then varval=double(varval)
  head_struct=create_struct(varname,varval)
      ;We will loop over the header to the last variable
  i=2
  while (i lt n_elements(imhdr) and strtrim(strmid(imhdr(i),0,8)) ne 'END') do begin
      varname=strtrim(strmid(imhdr(i),0,8))
      if ((varname ne 'MJD') and (varname ne 'COMMENT') and (varname ne '')) then begin
          varval=sxpar(imhdr,varname)
          ;if (varname eq 'DATE-OBS') then varname = 'DATE_OBS'
          ;replace '-' as '_' becasue '-' is not allowed in the struct
          strreplace,varname,'-','_'
          if (size(varval,/type) eq 4) then varval=double(varval) ;convert any floats to doubles 
          head_struct=create_struct(head_struct,varname,varval)
      endif
      i=i+1
  endwhile
      ; Change the filename in the structure to the proper _c filename:
      ; Check if "mjd" or "jd" was in the image header...and make sure 'mjd' is not = 0.
  mjd = sxpar(imhdr,'mjd')
  if (mjd eq 0) then jd = sxpar(imhdr,'jd')
  if (!err ne 0) then begin
    ;add by zwk for kait
    ;get date time information for kait 
    date=sxpar(imhdr,'DATE-OBS')
    uttime=sxpar(imhdr,'UT')
    day=strmid(date,0,2)
    month=strmid(date,3,2)
    year=strmid(date,6,4)
    hour=strmid(uttime,0,2)
    minute=strmid(uttime,3,2)
    second=strmid(uttime,6,2)
    ;print,year,month,day,hour,minute,second
    juldate,[float(year),float(month),float(day),float(hour),float(minute),float(second)],mjd
      ;juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], mjd
      ;!err=0
  endif
  efftime = sxpar(imhdr,'efftime')
  if (efftime eq 0) then begin
    exptime=sxpar(imhdr,'exptime')
    efftime=exptime
    head_struct=create_struct(head_struct,'efftime',double(efftime))
  endif
  satcnts = sxpar(imhdr,'satcnts')
  if (satcnts eq 0) then head_struct=create_struct(head_struct,'satcnts',double(65535.0))
  bstddev = sxpar(imhdr,'bstddev')
  if (bstddev eq 0) then head_struct=create_struct(head_struct,'bstddev',double(5.0))
  head_struct=create_struct(head_struct,'mjd',double(mjd))
      ; Get a few SExtractor parameters out of the sobj header
  sex_head_struct=create_struct('SEXGAIN',0.0,'SEXBKGND',0.0,'SEXBKDEV',0.0,'SEXBKTHD',0.0, $
                                'SEXSATLV',0.0,'SEXMGZPT',0.0,'SEXNDET',0.0,'SEXNFIN',0.0, $
                                'BADPIXFILE','')
  sex_head_struct.sexgain=sxpar(sobjhdr,'SEXGAIN')
  sex_head_struct.sexbkgnd=sxpar(sobjhdr,'SEXBKGND')
  sex_head_struct.sexbkdev=sxpar(sobjhdr,'SEXBKDEV')
  sex_head_struct.sexbkthd=sxpar(sobjhdr,'SEXBKTHD')
  sex_head_struct.sexsatlv=sxpar(sobjhdr,'SEXSATLV')
  sex_head_struct.sexmgzpt=sxpar(sobjhdr,'SEXMGZPT')
  sex_head_struct.sexndet=sxpar(sobjhdr,'SEXNDET')
  sex_head_struct.sexnfin=sxpar(sobjhdr,'SEXNFIN')
;  sex_head_struct.badpixfile=whichbpfile(0)
  sex_head_struct.badpixfile='no_badpixel_file'
      ; Put these structures together
  stats_and_header=create_struct(head_struct,sex_head_struct,h)
      ;update the 'elev' data:
  ;will deal it later
  ;stats_and_header.elev=elev
      ;finally, create a two-dimensional array from the _sky.fit file, if it exists.
  skyc=c.sobjdir+'/'+c.root+'_sky.fit'
  sky=readfits(skyc)
  if (sky(0,0) eq -1) then begin ; the file does not exist, create a dummy array of -1s
      print,"Non-fatal error: The sky file is unavailable."
      sky=replicate(-1,64,64)
  ENDIF  
  nbad = 0
  sbit = cal_list.flags AND 4
  ibit = where(sbit NE 4)
  satmag = cal_list[ibit[0]].m
 
; create third order kx, ky
  ;;astr_struct_new,1.85,astr
  ;wcs_matrix_struct,pixscale,astr
  ;astr.crval = [newrac,newdecc]
  ;rd2xy,cal_list.ra,cal_list.dec,astr,xc,yc
  ;polywarp,cal_list.x,cal_list.y,xc,yc,3,kx,ky 

  ;stats_and_header=create_struct(stats_and_header,'RAC',newrac,'DECC',newdecc,'KX',kx,'KY',ky)
  stats_and_header=create_struct(stats_and_header,'RAC',newrac,'DECC',newdecc)
  stats_and_header=create_struct(stats_and_header,'SAT_MAG',satmag,'NOBJ_BADPIX', nbad)
  stats_and_header=create_struct(stats_and_header,'sky',sky)
  ; Now put the stats and the header variables in extension 2...
  stats_and_header.fname=c.root+'_c.fit'
  mwrfits,stats_and_header,c.cobj
  h = stats_and_header
  spawn, 'chmod 666 '+c.cobj
END 

