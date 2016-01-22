pro simpledark, filename, dark
;+
; NAME:
;       SIMPLEDARK
; PURPOSE:
;	Process all dark images described in file associated with field 
;	number
;
; CALLING SEQUENCE:
;       simpledark, filename, dark
;
; INPUTS:
;       filename; simple logfile
;
; OUTPUTS:
;	dark; dark frame produced
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
;
; PROCEDURE:
;	the file 
;
; REVISION HISTORY:
;	Tim McKay	UM	9/23/97
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - simpledark, filename, dark'
        return
 endif
 
 openr, 1, filename

 name=''
 type=''
 string=''
 n=0
 result=findgen(2015,2015)
 result(*,*)=0
 while not eof(1) do begin

	readf,1,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	type=strtrim(info(1))
	if (type eq 'dark') then begin
	    print, ""
	    print, "Processing file:",name
	    im=mrdfits(name,0,hdr)
	    extime=sxpar(hdr,"EXPTIME")
	    print,"Exposure time =",extime
	    if (extime gt 0) then begin
	      rbias, im, im
	      im = im / extime
	      result=result+im	
	      n=n+1
	    endif
	end

 endwhile
 close, 1

 if (n gt 0) then begin
	print, "Found ",n," dark frames to use"
	dark=result/n
        ;Now assemble an output name...
        namearray=str_sep(name,"_")
	cam=strmid(namearray(2),0,2)
	outname=namearray(0)+"_masterdark_"+cam+".fit"
	print,"Writing the assembled dark frame to: ",outname
	writefits,outname,dark
 endif
 if (n eq 0) then begin
	print, "Didn't find any dark frames to use!"
	return
 endif
	
 return
 end
