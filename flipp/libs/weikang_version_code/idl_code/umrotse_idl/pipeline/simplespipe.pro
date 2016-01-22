pro simplespipe, filename, dark=dark, flat=flat, correct=correct
;+
; NAME:
;       SIMPLESPIPE
; PURPOSE:
;	Process all images described in file using sextractor
;
; CALLING SEQUENCE:
;       simplepipe, filename
;
; INPUTS:
;       filename; logfile with simple format
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
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - simplespipe, filename, dark=dark, flat=flat
        return
 endif
 
 openr, 1, filename

 name=''
 type=''
 string=''
 n=1
 rextract_setup,ps
 while not eof(1) do begin

	readf,1,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	type=strtrim(info(1))
	if (type eq 'sky') then begin
	    print, ""
	    print, "Processing file:",name,"   Number:",n
	    im=mrdfits(name,0,hdr)
	    extime=sxpar(hdr,"EXPTIME")

	    ;remove bias first
	    print, "Removing bias"
	    rbias, im, im
	    ;If a dark frame is passed, use that too
	    if (keyword_set(dark)) then begin
	        ;If a dark frame is passed, use that too
		print, "Correcting for dark"
		im=im-dark*extime
	    end

	    ;Insert flattening here 
	    if (keyword_set(flat)) then begin
		Print, "Applying flat"
		im=im/flat
	    end

	    ;Write out the clean frame, KEEP THE HEADER! 
	    ; BUT FIX BZERO!
	    sxaddpar,hdr,'BZERO',0
	    namearray=str_sep(name,'.')
	    outfile=namearray(0)+"_c.fit"
	    print, "Writing corrected frame to file:",outfile
	    writefits,outfile,im,hdr		

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
	end

	if (type eq 'clean') then begin
     	    namearray=str_sep(name,'.')
    	    imfile=namearray(0)+"_c.fit"
	    print, "Will process corrected frame:",imfile
	    namearray=str_sep(name,'.')
	    catfile=namearray(0)+"_sobj.fit"
	    print, "Will be writing objects to file:",catfile
	    ps.catalog_name=catfile
 	    rextract,ps,imfile
	    n=n+1
	end

	if (type eq 'ctio') then begin
	    par_dir=getenv('EXTRACT_PAR')
	    if (par_dir eq "") then begin
	       par_dir='/sdss/products/idltools/rotse/rotse_idl/pipeline'
 	    endif
	    ps.parameters_name=par_dir+'/ctio.par'
	    ps.gain='2.9'
	    ps.pixel_scale='2.304'
	    ps.seeing_fwhm='3.0'
	    ps.detect_thresh='1.0'
	    ps.analysis_thresh='1.5'
     	    namearray=str_sep(name,'.')
	    print, "Will process corrected frame:",name
	    namearray=str_sep(name,'.')
	    catfile=namearray(0)+"."+namearray(1)+"_sobj.fits"
	    print, "Will be writing objects to file:",catfile
	    ps.catalog_name=catfile
	    skyfile=namearray(0)+"."+namearray(1)+"_sky.fits"
	    print, "Will be writing minibackground to file:",skyfile	
	    ps.checkimage_type='minibackground'
	    ps.checkimage_name=skyfile
 	    rextract,ps,name
	    n=n+1
	end

 endwhile
 close, 1

 return
 end

