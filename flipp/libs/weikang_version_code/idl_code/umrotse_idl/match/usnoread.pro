pro usnoread, ra, dec, size, cat, maglim=maglim
;+
; NAME:	usnoread
;
; CALLING SEQUENCE:	usnoread, ra, dec, size, cat
;
; INPUTS:	ra: ra of field center
;		dec: dec of field center
;		size: field size (radius in degrees)
;		cat: name of structure to load
;
; OUTPUTS:	cat: structure loaded with output
;	
; INPUT KEYWORDS:
;		maglim: pick only objects with r brighter than this
;			
; PROCEDURE:	Uses wcstools-1.4.0 program scat to produce a list from
;		the USNO A1.0 catalog, then sucks the results into
;		an idl structure
;
; REVISION HISTORY:  
;	Tim McKay		UM		4/30/98	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - usnoread, ra, dec, size, cat, maglim=maglim '
        return
 endif

 ;make the ra string
 hms=strtrim(string(fix(sixty(ra/15.0))),2)
 for i=0,2 do begin
	if (hms(i) eq '0') then hms(i)='00'
 endfor
 ras=hms(0)+':'+hms(1)+':'+hms(2)
 dms=strtrim(string(fix(sixty(dec))),2)
 for i=0,2 do begin
	if (dms(i) eq '0') then dms(i)='00'
 endfor
 decs=dms(0)+':'+dms(1)+':'+dms(2)


 ; First execute the search
 cmd_string='scat -c ua2 -j -d '
 cmd_string=cmd_string+' -r '+strtrim(string(fix(size*3600)),2)+' -o temp -w'
 cmd_string=cmd_string+' -n 130000 '+ras+' '+decs+' J2000'

 if keyword_set (maglim) then begin
	cmd_string=cmd_string+' -m '+string(maglim)
 endif

 print, cmd_string
 spawn,cmd_string,result
 print,' '
 print,'Done with searching, starting to read in the results....'
 print,' '

;That should do it and put the results in "temp.ua2". Now read them in...
 spawn,'wc temp.ua2',results
 tmp1=lonarr(3)
 reads,results,tmp1
 nlines=tmp1(0)
 print,nlines,tmp1

 get_lun,fid
 openr,fid,'temp.ua2'
 lin=''
;First junk the leading 7 lines....
 readf,fid,lin
 readf,fid,lin
 readf,fid,lin
 readf,fid,lin
 readf,fid,lin
 readf,fid,lin
 readf,fid,lin
 readf,fid,lin 
;Now start reading them
 nobj=nlines-8
 print,'Number of objects found is ',ntostr(nobj)
 if (nobj eq 0) then begin
  	print,' '
	print,'WHY ARENT THERE ANY OBJECTS!!!!'
	print,' '
	close,fid
	return
 endif
 cat=create_struct(name='ucat',"ra",0d,"dec",0d,$
	"rmag",0.0,"bmag",0.0)
 cat=replicate(cat,nobj)
 tab = byte(9b)
 for n=long(0),nobj-1 do begin
    readf,fid,lin
;;    info=str_sep(lin,'	')
    info=str_sep(lin,tab)
    cat(n).ra=double(info(1))
    cat(n).dec=double(info(2))
    cat(n).bmag=float(info(3))
    cat(n).rmag=float(info(4))
 end
 
 close,fid
 return
 end


