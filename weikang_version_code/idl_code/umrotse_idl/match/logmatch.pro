pro logmatch, filename, struct, outfile=outfile
;+
; NAME:
;       LOGMATCH
; PURPOSE:
;	takes a log file and matches all the output structures listed in
;	it to the coordinate frame of the first image....
;
; CALLING SEQUENCE:
;       logmatch, filename, struct
;
; INPUTS:
;       filename; simple logfile
;
; OUTPUTS:
;	struct; final matched object structure
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
;
; PROCEDURE:
;	the file 
;
; REVISION HISTORY:
;	Tim McKay	UM	3/7/98
;-
 On_error,2              ;Return to caller

 if N_params() eq 0 then begin
        print,'Syntax - logmatch, filename, struct'
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
	if (type eq 'sobj') then begin
	    print, ""
	    print, "Processing file:",name
	    if (n eq 0) then begin
	      list1=mrdfits(name,1,hdr1)
	    endif
	    if (n eq 1) then begin
	      list2=mrdfits(name,1,hdr2)
	      twomatch_s2,list1,list2,match,skip=30,iter=2
	    endif
	    if (n gt 1) then begin
	      listnew=mrdfits(name,1,hdr1)
	      addmatch_s2,match,listnew,match,skip=30,iter=2
	    endif
	    n=n+1
	end

 endwhile
 close, 1

 if (n gt 0) then begin
     if (keyword_set(outfile)) then begin
	mwrfits,match,outfile
     endif
 endif
 if (n eq 0) then begin
	print, "Didn't find any dark frames to use!"
	return
 endif

 struct=match
	
 return
 end



