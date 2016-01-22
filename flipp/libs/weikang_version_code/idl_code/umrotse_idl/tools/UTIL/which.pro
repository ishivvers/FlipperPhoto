pro which,proc_name
;+
; NAME:
;	WHICH
;
; PURPOSE:
;	Determine in which library/directory the procedure or function
;	specified is located in the !PATH.  This is useful for finding
;	out which library a certain procedure comes from, particularly
;	when there are duplicates.  This is similar to the unix
;	'which' command.
;
; CALLING SEQUENCE:
;    WHICH, [ proc_name ]          ;Find PROC_NAME in !PATH and display
;
; OPTIONAL INPUT:
;	proc_name - Character string giving the name of the IDL procedure or 
;		function.  Do not give an extension.   If omitted, 
;		the program will prompt for PROC_NAME.
;
; OUTPUTS:
;	None.
;
; SIDE EFFECTS
;	None.
;
; PROCEDURE:
;	The system variable !PATH is parsed into individual libraries or 
;	directories.   Each library or directory is then searched for the
;	procedure name.  If not found in !PATH,
;	then the ROUTINES.HELP file is checked to see if it is an intrinsic
;	IDL procedure.
;
; EXAMPLE:
;	Find out where the procedure CURVEFIT lives.
;
;	IDL> which, 'curvefit'
;
; RESTRICTIONS:
;	None.
;
; REVISION HISTORY:
;	29-MAY-94  Modified from getpro.pro by E. Deutsch
;	14-JUL-95  Fixed for IDL 4.0
;-

  On_error,2                           ;Return to caller on error
  os = !VERSION.OS                     ;VMS or Unix operating system

  if (n_params() eq 0) then begin 	     ;Prompt for procedure name?
    proc_name = ' ' 
    read,'Enter name of procedure to look for: ',proc_name     
  endif else zparcheck, 'which', proc_name, 1, 7, 0, 'Procedure name'

  fdecomp, proc_name, disk, dir, name      ;Don't want file extensions
  name = strtrim( name, 2 )  


;Set up separate copy commands for VMS and Unix

  if (os eq "vms") then begin   
    sep = ',' & dirsep = '' & name = strupcase(name)
  endif else begin
    sep = ':' & dirsep = '/'
    endelse   

  temp = !PATH                     ;Get current IDL path of directories
  if (os eq "vms") then temp = strupcase(temp)


;    Loop over each directory in !PATH until procedure name found

  found=0
  while (temp ne '') do begin   
    dir = gettok( temp, sep)

    if strmid(dir,0,1) EQ '@' then begin          ;Text Library?
      if (os ne "vms") then message, $
        '!path contains a invalid VMS directory specification',/cont $
      else begin
        libname = strmid( dir,1,strlen(dir)-1 )         ;Remove the "@" symbol
        spawn,'library/extract='+name+'/out='+name+'.pro '+libname,out,count=i
        if (i eq 0) then begin                           ;Success?
          message,name + '.PRO extracted from ' + libname,/INF
          return
          endif
        endelse
     endif else begin                              ;Directory
       a = findfile(dir + dirsep + name+'.pro',COUNT=i)
       if (I ge 1) then begin                     ;Found by FINDFILE?
         if (found eq 0) then print,'Using: '+dir+dirsep+name+'.pro'
         if (found eq 1) then print,'Also in: '+dir+dirsep+name+'.pro'
         found=1
         endif
       endelse
    endwhile

  if (found eq 1) then return

; At this point !PATH has been searched and the procedure has not been found
; Now check if it is an intrinsic IDL procedure or function
;

; Deutsch changed 7/14/95

; No such file in our directories. Removed this check Erin Scott Sheldon

;  openr,inunit,'$IDL_OLD/help/routines.help',/GET_LUN ;Open help files

;  n = 0L
;  WHILE (n eq 0) do BEGIN              ;Code added for new V3.1 help files
;	dummy = ""
;	readf, inunit, dummy 
;	dd = byte(strcompress(dummy,/REMOVE_ALL))

	;Is the first character a number (between '0' and '9')?
;	IF (dd(0) GE 48 and dd(0) LE 57 ) THEN $
;		n = fix(dummy)
;  endWHILE

; Deutsch added 7/14/95
;  readf, inunit, dummy 

;  lv2_topics = strarr(n)                                  
;  readf, inunit, lv2_topics

; Deutsch changed 7/14/95
;  lv2_topics = strtrim( strmid( lv2_topics, 0, 15), 2)
;  for i1=0,n-1 do lv2_topics(i1)=strtrim(strmid(lv2_topics(i1), $
;    strpos(lv2_topics(i1),':')+1,15),2)

;  test = where(lv2_topics EQ strupcase(name), count)

;  if count EQ 0 then begin   
;    message,'Procedure '+NAME+' not found in the !PATH search string',/INF
;  endif else begin     
;    message,'Procedure '+NAME+' is an intrinsic IDL procedure',/INF
;  endelse
 
  message,'Procedure '+NAME+' not found in the !PATH search string',/INF

  return

end 
  
