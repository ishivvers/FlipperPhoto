pro rotsepipe, camera,data_dir, cal_dir
;+
; NAME:
;       ROTSEPIPE
; PURPOSE:
;	Process all images described in file using sextractor
;
; CALLING SEQUENCE:
;       rotsepipe, filename
;
; INPUTS:
;	camera; letter of desired carera
;       data_dir; directory in which the data live
;	cal_dir; directory in which the cal files live
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
;
; PROCEDURE:
;	the file 
;
; REVISION HISTORY:
;	Tim McKay	UM	1/29/97
;	Tim McKay	UM	6/17/98
;				Altered from simplespipe
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - rotsepipe, camera, data_dir, cal_dir
        return
 endif
 
 if (camera ne 'a' and camera ne 'b' and camera ne 'c' and $
	camera ne 'd') then begin
	print,'Illegal camera name:',camera
	return
 endif

; First, load the appropriate cal files
 print,'Loading calibration files for camera '+camera+'....'
 dname=cal_dir+'/dark0050_'+camera+'.fit'
 print,'Reading '+dname
 drk0050=mrdfits(dname,0,hdr)
 dname=cal_dir+'/dark0250_'+camera+'.fit'
 print,'Reading '+dname
 drk0250=mrdfits(dname,0,hdr)
 dname=cal_dir+'/dark1250_'+camera+'.fit'
 print,'Reading '+dname
 drk1250=mrdfits(dname,0,hdr)
 fname=cal_dir+'/flat'+camera+'.fit'
 print,'Reading '+fname
 flat=mrdfits(fname,0,hdr)

 cd,data_dir

; Now make a file including all the files you want to process
 cmd = ''
 cmd = 'ls -1 *1'+camera+'???.fit* > templist.txt'
 spawn,cmd

; Create a log file
 fname=data_dir+'/rotsepipe_'+camera+'.log'
 get_lun,lun
 openw,lun,fname
 printf,lun,'This is a rotsepipe log file for camera '+camera
 printf,lun,'The data directory was:'+data_dir
 printf,lun,'The cals directory was:'+cal_dir
 close,lun
 free_lun,lun



 openr, 1, 'templist.txt'

 name=''
 type=''
 string=''
 n=1
 rextract_setup,ps
 while not eof(1) do begin

	readf,1,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	print, ""
	print, "Processing file:",name,"   Number:",n
	im=mrdfits(name,0,hdr)
	extime=sxpar(hdr,"EXPTIME")
	time=sxpar(hdr,"GMTTIME")
	ts=str_sep(time,' ')
	t=float(ts)
	juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], jd
	print,jd
	sxaddpar,hdr,'JD',jd,format='f15.8'

	;Now apply the appropriate dark
	if (extime eq 5) then begin
		print, "Correcting for 5 second dark"
		im=im-drk0050
	end
	if (extime eq 25) then begin
		print, "Correcting for 25 second dark"
		im=im-drk0250
	end
	if (extime eq 125) then begin
		print, "Correcting for 125 second dark"
		im=im-drk1250
	end


	;Insert flattening here 
	if (keyword_set(flat)) then begin
		Print, "Applying flat"
		im=im/flat
	end

	im=im(15:2047,2:2034)

	;Write out the clean frame, KEEP THE HEADER! 
	; BUT FIX BZERO!
	sxaddpar,hdr,'BZERO',0
	namearray=str_sep(name,'.')
	outfile=namearray(0)+"_c.fit"
	print, "Writing corrected frame to file:",outfile
	writefits,outfile,im,hdr		

	sky,im,sval,serr
	fname=data_dir+'/rotsepipe_'+camera+'.log'
	get_lun,lun
        openu,lun,fname
	printf,lun,outfile,extime,sval,serr
	close,lun
	free_lun,lun

	;If you just want to correct frames set this.....
	if (not keyword_set(correct)) then begin
	      namearray=str_sep(name,'.')
	      catfile=namearray(0)+"_sobj.fit"
	      print, "Will be writing objects to file:",catfile
	      ps.catalog_name=catfile
	      skyfile=namearray(0)+"_sky.fit"
	      print, "Will be writing minibackground to file:",skyfile	
	      ps.checkimage_type='minibackground'
	      ps.checkimage_name=skyfile
 	      rextract,ps,outfile
	endif
	n=n+1

 endwhile
 close, 1
 spawn,'rm templist.txt'

 return
 end

