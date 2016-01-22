pro a10read,a10file,data,brighterthan=brighterthan
;+
; NAME:
;	A10READ
;
; PURPOSE:
;	Compare coordinates of stars in a GSC (gsclist) file and a USNO-A1.0
;	(a10list) file.
;
; CATEGORY:
;	Catalog software
;
; CALLING SEQUENCE:
;	a10read,a10file,data
;
; INPUTS:
;	a10file: The filename of an USNO-A1.0 extraction
;		which contains the target field and the surrounding region.
;
; OUTPUTS:
;	data:	Array containing A1.0 catalog data.  e.g.:
;	 RA (deg)  2000  Dec (deg)  B mag  R mag  Field  GSC?  Err?  Zone
;	 ------------  -----------  -----  -----  -----  ----  ----  ----
;	   267.148225   -37.177994   22.8   18.1    393     0     0   525
;	   267.148233   -37.326064   23.9   18.7    393     0     0   525
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;	01/03/97 Written by E. Deutsch
;
;-


; -- Not enough parameters?  Show the call sequence -------------------
  if (n_params(0) lt 2) then begin
    print,'Call> a10read,a10file,data'
    print,"e.g.> a10read,'KA2.a10list',data"
    return
    endif

  if (n_elements(brighterthan) eq 0) then brighterthan=99

  if (not exist(a10file)) then begin
    print,'ERROR: '+a10file+' not found.'
    return
    endif
  spawn,'wc '+a10file,results
  tmp1=lonarr(3)
  reads,results,tmp1
  nlines=tmp1(0)
  openr,1,a10file
  lin='' & readf,1,lin & readf,1,lin
  d1=dblarr(8)
  data=dblarr(8,nlines) & i=0L & i2=0L
  while not EOF(1) do begin
    readf,1,d1
    if (max(d1(2:3)) lt brighterthan) then begin
      data(*,i)=d1
      i=i+1
      endif
    i2=i2+1
    endwhile
  close,1
  data=data(*,0:i-1)

  print,strn(i2),' objects in file'
  print,strn(i),' objects selected'

  return


end



