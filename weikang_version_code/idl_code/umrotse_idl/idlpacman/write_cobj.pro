pro write_cobj, c, h, cal_list, imhdr, nomod=nomod

  sobjhdr = headfits(c.sobj)

;Get the elevation for the stats file
  elev=sxpar(imhdr,'elev')
  if (!err ne 0) then begin
      elev=0.0
  endif

; Find the new ra center, dec center, and WCS stuff:
  newrac=(min(cal_list.ra)+max(cal_list.ra))/2.0     
  newdecc=(min(cal_list.dec)+max(cal_list.dec))/2.0
;  convert2xy,cal_list.ra,cal_list.dec,xc,yc,rac=newrac,decc=newdecc
  astr_struct_new,1.85,astr
  astr.crval = [newrac,newdecc]
  rd2xy,cal_list.ra,cal_list.dec,astr,xc,yc
  polywarp,xc,yc,cal_list.x,cal_list.y,1,kx,ky ; wcs can only use 1st order rotations
; the following sets the rotation matrix and offsets for the fits header:
  pc001001=kx(0,1)
  pc001002=kx(1,0)
  pc002001=ky(0,1)
  pc002002=ky(1,0)
; the following are the x and y offsets.  Note that they are only approximately centered.
  crpix1=-1*(-kx(1,0)*ky(0,0)+kx(0,0)*ky(1,0))/(-kx(1,0)*ky(0,1)+kx(0,1)*ky(1,0))
  crpix2=-1*(kx(0,1)*ky(0,0)-kx(0,0)*ky(0,1))/(-kx(1,0)*ky(0,1)+kx(0,1)*ky(1,0))

; First, we need to know which wcs variables have already been put into the fits header:
  pc_header=0
  test_pc=sxpar(imhdr,'pc001001')
  if (!err eq 0) then pc_header=1

; First, for very old images we need to add in _all_ the WCS stuff.
  test_nowcs=sxpar(imhdr,'ctype1')
  if (string(test_nowcs) ne 'RA---TAN') then begin
      sxdelpar,imhdr,['CRPIX1','CRVAL1','CRPIX2','CRVAL2','PC001001','PC002002','PC001002','PC002001']
      pc_header=0
      sxaddpar,imhdr,'CTYPE1','RA---TAN',' RA, TAN projection used',after='LONGITUD'
      sxaddpar,imhdr,'CRPIX1',0.0,' pixel at reference point',after='CTYPE1'
      sxaddpar,imhdr,'CRVAL1',0.0,' RA at the reference point',after='CRPIX1'
      sxaddpar,imhdr,'CDELT1',0.0,' increment per pixel (degrees)',after='CRVAL1'
      sxaddpar,imhdr,'CUNIT1','deg',' physical units of axis 1',after='CDELT1'
      sxaddpar,imhdr,'CTYPE2','DEC--TAN',' DEC, TAN projection used',after='CUNIT1'
      sxaddpar,imhdr,'CRPIX2',0.0,' pixel at reference point',after='CTYPE2'
      sxaddpar,imhdr,'CRVAL2',0.0,' DEC at the reference point',after='CRPIX2'
      sxaddpar,imhdr,'CDELT2',0.0,' increment per pixel (degrees)',after='CRVAL2'
      sxaddpar,imhdr,'CUNIT2','deg',' physical units of axis 2',after='CDELT2'

      mount=sxpar(imhdr,'mount')
      if (mount eq 'Epoch-Instruments Equatorial') then begin
          sxaddpar,imhdr,'cdelt1',0.004
          sxaddpar,imhdr,'cdelt2',0.004
      endif
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
      if ((varname ne 'MJD') and (varname ne 'COMMENT')) then begin
          varval=sxpar(imhdr,varname)
          if (varname eq 'DATE-OBS') then varname = 'DATE_OBS'
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
      time = sxpar(imhdr,"GMTTIME")
      ts = str_sep(time,' ')
      t = float(ts)
      juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], mjd
      !err=0
  endif
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
  stats_and_header.elev=elev
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
  astr_struct_new,1.85,astr
  astr.crval = [newrac,newdecc]
  rd2xy,cal_list.ra,cal_list.dec,astr,xc,yc
  polywarp_rotse_iii,cal_list.x,cal_list.y,xc,yc,3,kx,ky 

  stats_and_header=create_struct(stats_and_header,'RAC',newrac,'DECC',newdecc,'KX',kx,'KY',ky)
  stats_and_header=create_struct(stats_and_header,'SAT_MAG',satmag,'NOBJ_BADPIX', nbad)
  stats_and_header=create_struct(stats_and_header,'sky',sky)
  ; Now put the stats and the header variables in extension 2...
  stats_and_header.fname=c.root+'_c.fit'
  mwrfits,stats_and_header,c.cobj
  h = stats_and_header
  spawn, 'chmod 666 '+c.cobj
END 

