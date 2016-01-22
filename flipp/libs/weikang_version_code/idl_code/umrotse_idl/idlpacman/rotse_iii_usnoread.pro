pro rotse_iii_usnoread, ra, dec, size, cat
;+
; NAME:	rotse_iii_usnoread
;
; CALLING SEQUENCE:	rotse_iii_usnoread, ra, dec, size, cat, maglim=maglim
;
; INPUTS:	ra: ra of field center
;		dec: dec of field center
;		size: field size (radius in degrees)
;		cat: name of structure to load
;
; OUTPUTS:	cat: structure loaded with output
;	
; INPUT KEYWORDS:
;			
; PROCEDURE:	Uses Eli Rykoff's USNO database to load appropriate USNO
;		stars more quickly. It also crops the lists in the
;		appropriate way for calibration of square images.
;		Automatically gets everything to 15th magnitude.
;
; REVISION HISTORY:  
;	Tim McKay		UM		4/30/98	
;	Tim McKay		UM		2/6/01
;		Modified to read the correct square projected field....
;	Tim McKay		UM		9/18/01
;		Modified to use the USNO database
;******************************************************************************

  if N_params() eq 0 then begin
        print,'Syntax - rotse_iii_usnoread, ra, dec, size, cat, maglim=maglim '
        return
  endif

  extract_usno_db, ra, dec, size, cat

  ;Now fill with information from USNO
  astr_struct_new,1.85,astr
  astr.crval=[double(ra),double(dec)]
  rd2xy,cat.ra,cat.dec,astr,xc,yc

  inpic=where(xc gt -1024 and xc lt 1024 and yc gt -1024 and yc lt 1024)
  xc=xc(inpic)
  yc=yc(inpic)
  nobj=n_elements(inpic)
  cat=cat(inpic)

 return
 end





