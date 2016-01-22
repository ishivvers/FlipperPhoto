pro write_cobjk, c, h, cal_list, imhdr, nomod=nomod,pixscale=pixscale,tel=tel

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

if not keyword_set(tel) then begin
  tel='KAIT'
endif

; Do a couple of basic checks on the calibration.  If it was very ugly, do not overwrite the header.
  goodcal=1
  if (h.zp_sigma gt 0.5) then begin ; first warning
      if (h.dec_high - h.dec_low) gt 9.0 then begin                      
          goodcal=0             ; there was an obvious problem with the matching
      endif
  endif

; Write the new-style cobj file, which has the form:
;  Extension 0:  Actual image header with dummy image
;  Extension 1:  cobj structure
;  Extension 2:  cal structure and the fits header variables put into the structure
;                        Also, an array with the sky values is inserted if _sky.fit is available.
  
      ;This first command creates the file and sticks a little dummy data 
      ;in the zero extension. This allows me to write the image header into
      ;this file
  sxaddpar,imhdr,'PIXSCALE',pixscale,' pixel scale of image',after='EXPTIME'
  dummyhdr=imhdr
  writefits,c.cobj,indgen(10,10),dummyhdr
      ;Now add the actual calibrated list to extension 1...
  mwrfits,cal_list,c.cobj
  ; Extract the header variables into a structure. Start with the first one...
  sxdelpar,imhdr,['DATE']
  i=1
  varname=strtrim(strmid(imhdr(i),0,8))
  varval=sxpar(imhdr,varname)
  if (size(varval,/type) eq 4) then varval=double(varval)
  head_struct=create_struct(varname,varval)
      ;We will loop over the header to the last variable
  i=2
  while (i lt n_elements(imhdr) and strtrim(strmid(imhdr(i),0,8)) ne 'END') do begin
      varname=strtrim(strmid(imhdr(i),0,8))
      if ((varname ne 'MJD') and (varname ne 'COMMENT') and (varname ne '') and (varname ne 'HISTORY')) then begin
          varval=sxpar(imhdr,varname)
          ;if (varname eq 'DATE-OBS') then varname = 'DATE_OBS'
          ;replace '-' as '_' becasue '-' is not allowed in the struct
          strreplace,varname,'-','_'
          if (size(varval,/type) eq 4) then varval=double(varval) ;convert any floats to doubles 
          head_struct=create_struct(head_struct,varname,varval)
      endif
      i=i+1
  endwhile

  exptime=sxpar(imhdr,'exptime')
  ; Check if "mjd" or "jd" was in the image header...and make sure 'mjd' is not = 0.
  mjd = sxpar(imhdr,'mjd')
  if (mjd eq 0) then jd = sxpar(imhdr,'jd')
  if (!err ne 0) then begin
    ;add by zwk for kait
    case tel of 
    'KAIT': begin
      ;get date time information for kait 
      date=sxpar(imhdr,'DATE-OBS')
      uttime=sxpar(imhdr,'UT')
      day=strmid(date,0,2)
      month=strmid(date,3,2)
      year=strmid(date,6,4)
      hour=strmid(uttime,0,2)
      minute=strmid(uttime,3,2)
      second=strmid(uttime,6,2)
      print,year,month,day,hour,minute,second
      ;;; Note by zwk on 130510, here the mjd get from juldate is actually RJD, need to 
      ;;; minus 0.5 more to get real MJD
      juldate,[float(year),float(month),float(day),float(hour),float(minute),float(second)],mjd
      mjd=mjd-0.5d
      filter=sxpar(imhdr,'FILTERS')
      filter=strtrim(filter,2)
      ;juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], mjd
      ;!err=0
      end
    'LOT': begin
      ;print,'processing LOT mjd'
      ;DATE-OBS= '2012-02-11T11:57:33' /YYYY-MM-DDThh:mm:ss observation start, UT
      date=sxpar(imhdr,'DATE-OBS')
      year=strmid(date,0,4)
      month=strmid(date,5,2)
      day=strmid(date,8,2)
      hour=strmid(date,11,2)
      minute=strmid(date,14,2)
      second=strmid(date,17,2)
      ;print,year,month,day,hour,minute,second
      ;;; Note by zwk on 130510, here the mjd get from juldate is actually RJD, need to 
      ;;; minus 0.5 more to get real MJD
      juldate,[float(year),float(month),float(day),float(hour),float(minute),float(second)],mjd
      mjd=mjd-0.5d
      filter=sxpar(imhdr,'FILTER')
      filter=strtrim(filter,2)
      end
    'SP104' : begin
      ;get date time information for SP104
      date=sxpar(imhdr,'DATE-OBS')
      uttime=sxpar(imhdr,'TIME-BEG')
      year=strmid(date,0,4)
      month=strmid(date,5,2)
      day=strmid(date,8,2)
      hour=strmid(uttime,0,2)
      minute=strmid(uttime,3,2)
      second=strmid(uttime,6,2)
      ;print,year,month,day,hour,minute,second
      ;;; Note by zwk on 130510, here the mjd get from juldate is actually RJD, need to 
      ;;; minus 0.5 more to get real MJD
      juldate,[float(year),float(month),float(day),float(hour),float(minute),float(second)],mjd
      mjd=mjd-0.5d
      exptime=sxpar(imhdr,'EXPOSURE')
      filter=sxpar(imhdr,'FILTER')
      filter=strtrim(filter,2)
      end
    'Nickel' : begin
      ;get date time information for Nickel
      date=sxpar(imhdr,'DATE-STA')
      uttime=sxpar(imhdr,'DATE-STA')
      if date eq 0 then begin
        date=sxpar(imhdr,'DATE-BEG')
        uttime=sxpar(imhdr,'DATE-BEG')
      endif
      year=strmid(date,0,4)
      month=strmid(date,5,2)
      day=strmid(date,8,2)
      hour=strmid(uttime,11,2)
      minute=strmid(uttime,14,2)
      second=strmid(uttime,17,2)
      ;print,year,month,day,hour,minute,second
      ;;; Note by zwk on 130510, here the mjd get from juldate is actually RJD, need to 
      ;;; minus 0.5 more to get real MJD
      juldate,[float(year),float(month),float(day),float(hour),float(minute),float(second)],mjd
      mjd=mjd-0.5d
      exptime=sxpar(imhdr,'EXPOSURE')
      ;filter=sxpar(imhdr,'FILTER')
      filter=sxpar(imhdr,'FILTNAM')
      filter=strtrim(filter,2)
      end
    else: print,'Warining : unknown telescope!'
    endcase
  endif

  tempexptime=sxpar(imhdr,'exptime')
  if (tempexptime eq 0) then begin
    head_struct=create_struct(head_struct,'exptime',double(exptime))
  endif
  if not tag_exist(head_struct,'filter') then head_struct=create_struct(head_struct,'filter',filter)
  efftime = sxpar(imhdr,'efftime')
  if (efftime eq 0) then begin
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
  extast,imhdr,astr
  rac=h.rac
  decc=h.decc
  astr.crval = [rac,decc]
  ad2xy,cal_list.ra,cal_list.dec,astr,xc,yc
  polywarp,cal_list.x,cal_list.y,xc,yc,1,kx,ky 

  ;stats_and_header=create_struct(stats_and_header,'RAC',newrac,'DECC',newdecc,'KX',kx,'KY',ky)
  stats_and_header=create_struct(stats_and_header,'KX',kx,'KY',ky)
  stats_and_header=create_struct(stats_and_header,'SAT_MAG',satmag,'NOBJ_BADPIX', nbad)
  stats_and_header=create_struct(stats_and_header,'sky',sky)
  ; Now put the stats and the header variables in extension 2...
  stats_and_header.fname=c.root+'_c.fit'
  mwrfits,stats_and_header,c.cobj
  h = stats_and_header
  spawn, 'chmod 666 '+c.cobj
END 

