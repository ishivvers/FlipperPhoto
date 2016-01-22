pro tychocal_list, tcat, file, keep=keep, skip=skip, rskip=rskip,$
	iter=iter, subr=subr, fail=fail, ebox=ebox, plots=plots, $
	rac=rac, decc=decc, caltest=caltest, logfile=logfile, $
        writecal=writecal,badpixfile=badpixfile
;+
; NAME:	TYCHOCAL_LIST
;
; CALLING SEQUENCE:	tychocal_list, tcat, file
;
; INPUTS:	tcat: tycho catalog structure
;		file: list of object structures from sextractor
;
; OUTPUTS:	
;	
;
; INPUT KEYWORDS:
;		keep: how many to triangle match
;		skip: how many to skip at bright end
;		iter: how many iterations of the fit to data
;		subr: fraction of image to use for triangle match
;               fail: returns 1 if no match is made else 0
;		ebox: size (in pixels) of final error box
;		plots: set this if you want to see the calibrated plots
;		rac: ra center of the frame
;		decc: dec center of the frame
;		logfile: file to write logging information to
;		writecal: set this to write out the _cal file.
;		badpixfile: set this to a specific bad pixel file name;
;			otherwise it tries to find one.
;			
; PROCEDURE:	reads in individual sobj sextractor output files and 
;		calibrates them using the tycho catalog
;
; REVISION HISTORY:  
;	Tim McKay		UM	10/25/98
;	Tim McKay		UM	11/4/98
;		Added reference to environment variables for data location
;  	Eli Rykoff		UM	5/30/00
;		Updates wcs information; outputs header info into cobj file ext. 2
;		Reads in bad pixel map.
;	Eli Rykoff		UM	6/5/00
;		Works well with any input file with date as mjd,jd or GMTTIME.
;		Will not crash when a bad pixel file is unavailable
;******************************************************************************
;-

 if N_params() eq 0 then begin
        print,'Syntax -tychocal_list, tcat, file, keep=keep, skip=skip, rskip=rskip, iter=iter, subr=subr, fail=fail, ebox=ebox, plots=plots, rac=rac, decc=decc, caltest=caltest, logfile=logfile, writecal=writecal,badpixfile=badpixfile'
        return
 endif


  if not keyword_set(skip) then begin
	skip=0
  end
  if not keyword_set(rskip) then begin
	rskip=0
  end
  if not keyword_set(keep) then begin
	keep=30
  end
  if not keyword_set(iter) then begin
	iter=8
  end
  if not keyword_set(subr) then begin
	subr=0.5
  end
  if not keyword_set(ebox) then begin
	ebox=1.0
  end
  if not keyword_set(plots) then begin
	plots=0.0
  endif else begin
	plots=1.0
  endelse

;Now figure out where everything is.....
  im_dir=getenv('ROTSE_IMDIR')
  if (im_dir eq "") then begin
	im_dir='.'
  endif
  sobj_dir=getenv('ROTSE_SDIR')
  if (sobj_dir eq "") then begin
	sobj_dir='.'
  endif
  cobj_dir=getenv('ROTSE_CDIR')
  if (cobj_dir eq "") then begin
	cobj_dir='.'
  endif
;  bp_dir=getenv('ROTSE_BPDIR')
;  if (bp_dir eq "") then begin
;        bp_dir='.'
;  endif

  openr,1,file
  n=1
  name=''
  while not eof(1) do begin

    readf,1,name,format='(a60)'
    info=str_sep(name," ")
    name=info(0)
    print, ""
    print, "Processing file:",name,"   Number:",n
    obj_list=mrdfits(sobj_dir+'/'+name,1)
    sobjhdr=headfits(sobj_dir+'/'+name)

;Now get the correct header from the image 
    narr=str_sep(name,'_sobj.')
    imname=im_dir+'/'+narr(0)+'_c.fit'
    imhdr=headfits(imname)

    if not keyword_set(badpixfile) then begin
       bpfile = get_badpix_mapname(imhdr) 
    endif else begin
       bpfile = get_badpix_mapname(imhdr,badpixfile=badpixfile)
    endelse

    if bpfile eq '' then begin
       bpfound=0
       xystruct=create_struct('x',-10,'y',-10,'type',byte(0),'median',0,'rms',0)
       badpix=replicate(xystruct,10)
       bpexptime=80
       whichbpfile='no_badpixel_file'
    endif else begin
       bpfound=1
       badpix=mrdfits(bpfile,1)
       bphdr=headfits(bpfile)
       bpexptime=sxpar(bphdr,'EXPTIME')
       whichbpfile=bpfile
    endelse

  if keyword_set(rac) then begin

     raci=rac
     decci=decc
     if keyword_set(caltest) then begin
      tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	skip=skip,rskip=rskip,subr=subr,fail=fail,iter=iter,$
	rac=raci,decc=decci
     endif else begin
      tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,skip=skip,$
	rskip=rskip,subr=subr,fail=fail,iter=iter,plots=plots,rac=raci,$
	decc=decci
     endelse

;If it fails, try a couple of other parameter settings before giving up...
     if (fail eq 1) then begin
	print,'Failed once, trying other settings (subr=0.5)'
        if keyword_set(caltest) then begin
	  tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	  skip=skip,rskip=rskip,subr=0.5,fail=fail,iter=iter,rac=raci,$
	  decc=decci
        endif else begin
	  tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,$
	  skip=skip,rskip=rskip,subr=0.5,fail=fail,iter=iter,plots=plots,$
	  rac=raci,decc=decci
	endelse
      endif
      if (fail eq 1) then begin
	print,'Failed twice, trying other settings (subr=0.2)'
        if keyword_set(caltest) then begin
	   tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.2,fail=fail,iter=iter,rac=raci,$
	   decc=decci
        endif else begin
	   tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.2,fail=fail,iter=iter,plots=plots,$
	   rac=raci,decc=decci
	endelse
      endif
      if (fail eq 1) then begin
	print,'Failed thrice, trying other settings (subr=0.1)'
        if keyword_set(caltest) then begin
	   tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.1,fail=fail,iter=iter,rac=raci,$
	   decc=decci
        endif else begin
	   tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.1,fail=fail,iter=iter,plots=plots,$
	   rac=raci,decc=decci
	endelse
      endif

    endif else begin	; endif for keyword_set(rac)

     if keyword_set(caltest) then begin
      tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	skip=skip,rskip=rskip,subr=subr,fail=fail,iter=iter
     endif else begin
       tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,skip=skip,$
	rskip=rskip,subr=subr,fail=fail,iter=iter,plots=plots
     endelse

;If it fails, try a couple of other parameter settings before giving up...
      if (fail eq 1) then begin
	print,'Failed once, trying other settings (subr=0.5)'
        if keyword_set(caltest) then begin
	  tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	  skip=skip,rskip=rskip,subr=0.5,fail=fail,iter=iter
        endif else begin
	  tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,$
	  skip=skip,rskip=rskip,subr=0.5,fail=fail,iter=iter,plots=plots
	endelse
      endif
      if (fail eq 1) then begin
	print,'Failed twice, trying other settings (subr=0.2)'
        if keyword_set(caltest) then begin
	   tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.2,fail=fail,iter=iter
        endif else begin
	   tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.2,fail=fail,iter=iter,plots=plots
	endelse
      endif
      if (fail eq 1) then begin
	print,'Failed thrice, trying other settings (subr=0.1)'
        if keyword_set(caltest) then begin
	   tychocal_test,imhdr,tcat,obj_list,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.1,fail=fail,iter=iter
        endif else begin
	   tychocal_s,imhdr,sobjhdr,tcat,obj_list,badpix,bpexptime,cal_list,cal_stats,keep=keep,$
	   skip=skip,rskip=rskip,subr=0.1,fail=fail,iter=iter,plots=plots
	endelse
      endif
    endelse
   

;Now write the calibrated structure out. Do the very ugly thing to make
;the image header get written to this file....
    if (fail ne 1) then begin
      ;Get the elevation for the stats file
      elev=sxpar(imhdr,'elev')
      if (!err ne 0) then begin
	elev=0.0
      endif

; Find the new ra center, dec center, and WCS stuff:
      newrac=(min(cal_list.ra)+max(cal_list.ra))/2.0     
      newdecc=(min(cal_list.dec)+max(cal_list.dec))/2.0
      convert2xy,cal_list.ra,cal_list.dec,xc,yc,rac=newrac,decc=newdecc


      polywarp,xc,yc,cal_list.x,cal_list.y,1,kx,ky       ; wcs can only use 1st order rotations
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
     if (cal_stats.zp_sigma gt 0.5) then begin     ; first warning
        if (cal_stats.dec_high - cal_stats.dec_low) gt 9.0 then begin                      
           goodcal=0			; there was an obvious problem with the matching
        endif
     endif

; Update the image header, imhdr:
   if (goodcal eq 1) then begin
      print,'Updating WCS information in fits header...'
      sxaddpar,imhdr,'CRPIX1',crpix1
      sxaddpar,imhdr,'CRPIX2',crpix2
      sxaddpar,imhdr,'CRVAL1',newrac
      sxaddpar,imhdr,'CRVAL2',newdecc
      if (pc_header eq 0) then begin      
            sxdelpar,imhdr,['CROTA2']
            sxaddpar,imhdr,'PC001001',pc001001,' coordinate description matrix','CAM_ID'
            sxaddpar,imhdr,'PC002002',pc002002,' coordinate description matrix','CAM_ID'
            sxaddpar,imhdr,'PC001002',pc001002,' coordinate description matrix','CAM_ID'
            sxaddpar,imhdr,'PC002001',pc002001,' coordinate description matrix','CAM_ID'
            ; now to update the image file and header, the slow way:
            im=readfits(imname,oldhdr)
            imnameout=im_dir+'/'+narr(0)+'_c.fit'
            bzero=sxpar(imhdr,'BZERO')
	    bscale=sxpar(imhdr,'BSCALE')
	    int_im=fix(round((im - bzero)/bscale))
            writefits,imnameout,int_im,imhdr
     endif else begin
            sxaddpar,imhdr,'PC001001',pc001001
            sxaddpar,imhdr,'PC002002',pc002002
            sxaddpar,imhdr,'PC001002',pc001002
            sxaddpar,imhdr,'PC002001',pc002001
            ; now to overwrite the fits header, the fast way:
            imnameout=im_dir+'/'+narr(0)+'_c.fit'
            modfits,imnameout,0,imhdr
     endelse
   endif        

; Write the new-style cobj file, which has the form:
;  Extension 0:  Actual image header with dummy image
;  Extension 1:  cobj structure
;  Extension 2:  cal structure and the fits header variables put into the structure
;                        Also, an array with the sky values is inserted if _sky.fit is available.

      fname=cobj_dir+'/'+narr(0)+'_cobj.fit'
      ;This first command creates the file and sticks a little dummy data 
      ;in the zero extension. This allows me to write the image header into
      ;this file
      dummyhdr=imhdr
      writefits,fname,indgen(10,10),dummyhdr
      ;Now add the actual calibrated list to extension 1...
      mwrfits,cal_list,fname
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
              if (size(varval,/type) eq 4) then varval=double(varval)	   ;convert any floats to doubles 
              head_struct=create_struct(head_struct,varname,varval)
	   endif
           i=i+1
      endwhile
      ; Change the filename in the structure to the proper _c filename:
      head_struct.filename=narr(0)+'_c.fit'
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
	'SEXSATLV',0.0,'SEXMGZPT',0.0,'SEXNDET',0.0,'SEXNFIN',0.0,'BADPIXFILE','')
      sex_head_struct.sexgain=sxpar(sobjhdr,'SEXGAIN')
      sex_head_struct.sexbkgnd=sxpar(sobjhdr,'SEXBKGND')
      sex_head_struct.sexbkdev=sxpar(sobjhdr,'SEXBKDEV')
      sex_head_struct.sexbkthd=sxpar(sobjhdr,'SEXBKTHD')
      sex_head_struct.sexsatlv=sxpar(sobjhdr,'SEXSATLV')
      sex_head_struct.sexmgzpt=sxpar(sobjhdr,'SEXMGZPT')
      sex_head_struct.sexndet=sxpar(sobjhdr,'SEXNDET')
      sex_head_struct.sexnfin=sxpar(sobjhdr,'SEXNFIN')
      sex_head_struct.badpixfile=whichbpfile(0)
      ; Put these structures together
      stats_and_header=create_struct(head_struct,sex_head_struct,cal_stats)
      ;update the 'elev' data:
      stats_and_header.elev=elev
      ;finally, create a two-dimensional array from the _sky.fit file, if it exists.
      skyfname=cobj_dir+'/'+narr(0)+'_sky.fit'
      sky=readfits(skyfname)
      if (sky(0,0) eq -1) then begin     ; the file does not exist, create a dummy array of -1s
	  print,"Non-fatal error: The sky file is unavailable."
          sky=replicate(-1,64,65)
      endif
      stats_and_header=create_struct(stats_and_header,'sky',sky)
      ;Now put the stats and the header variables in extension 2...
      mwrfits,stats_and_header,fname

; The cal file will still be written by default to maintain backward compatibility, and for easy access.
      ;Now write out the file associated with the "stats" for this
      ;calibration. For now cheese out and write fits...
      if keyword_set(writecal) then begin
         fname=cobj_dir+'/'+narr(0)+'_cal.fit'
         writefits,fname,indgen(10,10),dummyhdr
         mwrfits,stats_and_header,fname
      endif      
     

; Write to the logfile, if it exists
      if keyword_set(logfile) then begin
      	get_lun,lun
      	openu,lun,logfile,/append
	get_juldate,jd
	jdstring=strtrim(string(jd,format='(f16.8)'),2)
        if (bpfound eq 1) then begin
	  printf,lun,name+'  calibrated '+jdstring
	endif else begin
           printf,lun,name+'  calibrated '+jdstring+' with no badpixel checking.'
        endelse
	close,lun
	free_lun,lun
      endif

    endif else begin
	   print,"Tychocal_s failed to return a calibrated list for: ",name
; Write to the logfile, if it exists
      	   if keyword_set(logfile) then begin
      		get_lun,lun
      		openu,lun,logfile,/append
		get_juldate,jd
		jdstring=strtrim(string(jd,format='(f16.8)'),2)
		printf,lun,name+'  FAILED '+jdstring
		close,lun
		free_lun,lun
      	   endif
    endelse
    
    n=n+1    

  endwhile

  fail=0
  close,1
  return
  end








