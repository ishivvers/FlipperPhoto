pro tycho_select,data,rac,decc,outdata,size=size
;+
; NAME:
;	TYCHO_SELECT
;
; PURPOSE:
;	Select objects from the tycho data structure within some error
;	box
;
; CATEGORY:
;	Catalog software
;
; CALLING SEQUENCE:
;	tycho_select,data,rac,decc,outdata,size=size
;
; INPUTS:
;	data: the tycho data structure, inc ra,dec,bmag,vmag,varflag
;
; OUTPUTS:
;	outdata: smaller structure containing all objects within
;	a box of size "size" 
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;	08/21/98 Written by Tim Mckay
;
;-

  if (n_params(0) lt 4) then begin
    print,'Call> tycho_select,data,rac,decc,outdata,size=size'
    return
  endif

  if keyword_set(size) then begin
	decsize=size
  endif else begin
	decsize=8.0
  endelse

  rasize=decsize/cos(!dtor*decsize)

  declow=decc-decsize/2.0
  dechigh=decc+decsize/2.0
  if (dechigh gt 90.0) then dechigh=90.0

  if (dechigh gt 88.0) then begin
	ralow=0.0
	rahigh=360.0
  endif else begin
  	rasize=decsize/(2*cos(!dtor*dechigh))
  	ralow=rac-rasize
	rahigh=rac+rasize
  endelse
  
  ;Handle ra wrapping and make selection

  if (ralow ge 0 and rahigh le 360) then begin
	k = where(data.ra gt ralow and data.ra lt rahigh and $
		data.dec gt declow and data.dec lt dechigh)
  endif
  if (ralow gt 0 and rahigh gt 360) then begin
	rahigh=rahigh-360.
	k = where((data.ra gt ralow or data.ra lt rahigh) and $
		(data.dec gt declow and data.dec lt dechigh))
   endif
   if (ralow lt 0 and rahigh lt 360) then begin
	ralow=ralow+360.
	k = where((data.ra gt ralow or data.ra lt rahigh) and $
		(data.dec gt declow and data.dec lt dechigh))
   endif

   help,k
   print,ralow,rahigh,declow,dechigh

   sinfo=size(k)
   if (sinfo(0) ne 0) then begin
	nobj=sinfo(1)
	outdata=replicate(data(0),nobj)
   	outdata=data(k)
   endif else begin
	print,"No objects found!"
   endelse
   return
   end	




