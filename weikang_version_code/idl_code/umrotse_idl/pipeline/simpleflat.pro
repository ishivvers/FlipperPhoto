pro simpleflat, filename, flat,dark=dark 
;+
; NAME:
;       SIMPLEFLAT
; PURPOSE:
;	Process all listed images described in file to make flat
;	Frames should already be bias and dark subtracted
;	Header should include exposure times!
;
; CALLING SEQUENCE:
;       simpleflat, filename, flat
;
; INPUTS:
;       filename; simple logfile
;
; OUTPUTS:
;	flat; flat frame produced
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
;
;	dark: use this if you wish to feed in a dark for dark subtraction
;
; PROCEDURE:
;	the file 
;
; REVISION HISTORY:
;	Tim McKay	UM	9/23/97
;	Tim McKay	UM	10/27/97
;		Added frame corrections so this can be run standalone...
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - simpleflat, filename, flat, dark=dark'
        return
 endif
 
 openr, 1, filename

 name=''
 type=''
 string=''
 n=0

 while not eof(1) do begin
	readf,1,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	type=strtrim(info(1))
	if (type eq 'flat') then n=n+1
 endwhile
 close, 1
 if (n eq 0) then begin
	print, "There are no flat frames listed!"
	return
 endif
 print, "Found ",n," frames to use"
 result=findgen(2015,2015,n)
 help, result
 openr,1,filename
 n=0
 while not eof(1) do begin
	readf,1,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	type=strtrim(info(1))
	if (type eq 'flat') then begin
	    print, ""
	    print, "Processing file:",name,"   Number:",n
	    im=mrdfits(name,0,hdr)
	    extime=sxpar(hdr,"EXPTIME")
	    ;Now clean it up, remove bias first
	    print, "Removing bias"
	    rbias, im, im
	    ;If a dark frame is passed, use that too
	    if (keyword_set(dark)) then begin
		print, "Correcting for dark"
		im=im-dark*extime
	    end
	    im = im / extime
	    ;Second check to make sure its normalized
	    sky,im,sky,skyerr
	    print, "Sky found =",sky
	    im=im/sky
	    result(*,*,n)=im	
	    n=n+1
	end
 endwhile
 close, 1

 if (n gt 0) then begin
	print, "Found ",n," flat frames to use"
	medarr, result, flat
	;Second check to make sure its normalized
	sky,flat,sky,skyerr
	print, "Average found in flat =",sky
	flat=flat/sky
        ;Now assemble an output name...
        namearray=str_sep(name,"_")
	cam=strmid(namearray(2),0,2)
	outname=namearray(0)+"_masterflat_"+cam+".fit"
	print,"Writing the assembled dark frame to: ",outname
	writefits,outname,flat
    end
 if (n eq 0) then print, "Didn't find any flat frames to use!"
	

 return
 end

