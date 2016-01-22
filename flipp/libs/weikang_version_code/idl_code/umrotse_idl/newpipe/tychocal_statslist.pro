pro tychocal_statslist, list, stats_all, files=files
;+
; NAME:	TYCHOCAL_STATSLIST
;
; CALLING SEQUENCE:	tychocal_statslist, file, stats_all, files=0/1
;
; INPUTS:	file: list of "stats" files from tychocal_list
;
; OUTPUTS:	
;		stats_all: collated structure of them all....
;
; INPUT KEYWORDS:
;		files: flags whether input list is array of file names or 
;		       the name of a list file
;
; PROCEDURE:	reads in individual stats files and collates them
;
; REVISION HISTORY:  
;	Tim McKay		UM	11/14/98	created
;       Eli Rykoff		UM	4/7/00
;		updated to work with either cal files or new cobj files
;	Bob Kehoe  00-04-14  --  allow input array of file names
;       Eli Rykoff 00-05-02  --  fixed structure stuffing mismatch bug
;******************************************************************************
;-

  if N_params() lt 2 then begin
        print,'Syntax - tychocal_statslist, list, stats_all, files=files'
        return
  endif

  if not keyword_set(files) then begin
     openr,1,list
     ntot = 0
     name = ''
     while not eof(1) do begin
        readf,1,name,format='(a60)'
        ntot = ntot + 1
     endwhile
     close,1
     names = strarr(ntot)
     openr,1,list
     for k = 0,ntot-1 do begin
        readf, 1, name, format='(a60)'
        info=str_sep(name," ")
        names[k]=info(0)
     endfor
     close,1
  endif else begin
     names = list
     tmp = size(names)
     ntot = tmp[1]
  endelse

; determine whether we have cal files or cobj files in the list
  print,names[0]
  filetype=(str_sep(names[0],'_'))(3)
  fitsextension=0
  if (filetype eq 'cobj.fit') then fitsextension=2
  if (filetype eq 'cal.fit') then fitsextension=1
  if fitsextension eq 0 then begin
     print,'The list does not have the proper file types.'
     return
  endif
  
  stats = mrdfits(names[0], fitsextension, hdr)
  stats_all = replicate(stats, ntot)
  stats_all(0) = stats
  template=stats
  for k = 1, ntot-1 do begin
    print, "Processing file:",names[k],"   Number:", k
    struct_assign,mrdfits(names[k], fitsextension),template  ;stuff the structure into the template
    stats_all(k)=template
  endfor

  return
end











