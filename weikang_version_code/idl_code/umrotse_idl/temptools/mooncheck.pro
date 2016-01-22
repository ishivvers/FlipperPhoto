pro mooncheck,filename,outfile
;+
; NAME:
;       MOONCHECK
; PURPOSE:
;      Quick analysis of moon sky frames....
;
; CALLING SEQUENCE:
;       mooncheck, filename
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
;	Tim McKay	UM	2/15/98
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - mooncheck, filename, outfile'
        return
 endif
 
 openr, inunit, filename, /get_lun

 name=''
 type=''
 string=''
 n=1
 openw,outunit,outfile,/get_lun

 print,inunit,outunit,filename,outfile
 print,eof(inunit),'   end of file'

 while not eof(inunit) do begin

	readf,inunit,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	type=strtrim(info(1))
	if (type eq 'sky') then begin
	    print, ""
	    print, "Processing file:",name,"   Number:",n
	    im=mrdfits(name,0,hdr)
	    sky,im,sval,serr
	    printf,outunit,name,sval,serr
	end

 endwhile
 close, inunit
 close, outunit

 return
 end

