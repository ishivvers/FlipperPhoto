pro coaddpipe, filename
;+
; NAME:
;       COADDPIPE
; PURPOSE:
;	Process all images described in file using sextractor 
;	Tuned for the deeprange project data
;
; CALLING SEQUENCE:
;       drpipe, filename
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
;	Tim McKay	UM	6/69/98
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - coaddpipe, filename
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

	if (type eq 'coadd') then begin
	    par_dir=getenv('EXTRACT_PAR')
	    if (par_dir eq "") then begin
	       par_dir='/sdss/products/idltools/rotse/rotse_idl/pipeline'
 	    endif
	    ps.parameters_name=par_dir+'/rotse.par'
     	    namearray=str_sep(name,'.')
	    print, "Will process corrected frame:",name
	    namearray=str_sep(name,'.')
	    catfile=namearray(0)+"_sobj.fits"
	    print, "Will be writing objects to file:",catfile
	    ps.catalog_name=catfile
	    skyfile=namearray(0)+"_sky.fits"
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




