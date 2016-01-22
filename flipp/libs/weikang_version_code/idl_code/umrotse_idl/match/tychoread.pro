pro tychoread,tychofile,data,brighterthan=brighterthan
;+
; NAME:
;	TYCHOREAD
;
; PURPOSE:
;	Read in the relevant parts of the tycho catalog
;
; CATEGORY:
;	Catalog software
;
; CALLING SEQUENCE:
;	tychoread,tychofile,data
;
; INPUTS:
;	tychofile: Name of a tycho catalog format file
;
; OUTPUTS:
;	data:	Array containing A1.0 catalog data.  e.g.:
;	 RA (deg)  2000  Dec (deg)  B mag  V mag    Var
;	 ------------  -----------  -----  -----  -----  
;	   267.148225   -37.177994   22.8   18.1      1     
;	   267.148233   -37.326064   23.9   18.7      0
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;	01/03/97 Written by E. Deutsch (as a10read.pro)
;	08/21/98 Modified for tycho by Tim Mckay
;
;-


; -- Not enough parameters?  Show the call sequence -------------------
  if (n_params(0) lt 2) then begin
    print,'Call> tychoread,tychofile,data'
    return
  endif

  if (n_elements(brighterthan) eq 0) then brighterthan=99

;  if (not exist(tychofile)) then begin
;    print,'ERROR: '+tychofile+' not found.'
;    return
;    endif
  spawn,'wc '+tychofile,results
  tmp1=lonarr(3)
  reads,results,tmp1
  nlines=tmp1(0)

  star=create_struct("ra",0D,"dec",0D,"bmag",0.0,"vmag",0.0,"varflag",0)
  data=replicate(star,nlines)
  openr,1,tychofile
  lin=''
  i2=0L
  while not EOF(1) do begin
    readf,1,lin,format=(A149)
    ra=float(strmid(lin,13,12))
    dec=float(strmid(lin,26,12))
    bmag=float(strmid(lin,91,6))
    vmag=float(strmid(lin,104,6))
    vs=strmid(lin,146,1)
    if (vs ne ' ') then begin
	varflag=1
    endif else begin
	varflag=0
    endelse
    data(i2).ra=ra
    data(i2).dec=dec
    data(i2).bmag=bmag
    data(i2).vmag=vmag
    data(i2).varflag=varflag
    i2=i2+1
  endwhile
  close,1

  print,strn(i2),' objects in file'

  return


end



