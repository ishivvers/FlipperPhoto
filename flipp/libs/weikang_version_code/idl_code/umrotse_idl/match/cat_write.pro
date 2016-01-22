pro cat_write, file,data 
;+
; NAME:
;       RDATA_WRITE
; PURPOSE:
;	Crude wrapper for writing out a binary fits table....
;
; CALLING SEQUENCE:
;       rdata_write, file, x, y, f, s, r
;
; INPUTS:
;	file	filename of output fits binary table
;	x	array of x positions from rfind
;	y	array of y positions from rfind
;	f	array of fluxes from rfind
;	s	array of sharpness measures from rfind
;	r	array of roundness measures from rfind
;       
; OUTPUTS:
;	None
;	
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
;
; PROCEDURE:
;	This call is a first cut at something to easily write out the 
;	output of the rfind routine.
;
; REVISION HISTORY:
;	Tim McKay	UM	5/19/97
;	Dave Johnston   UM      6/97 changed from rdata_write
;-
 On_error,2              ;Return to caller

 if N_params() ne 2 then begin
        print,'Syntax - rdata_write, file, data
        return
 endif
ra=data(0,*)
dec=data(1,*)
bmag=data(2,*)
rmag=data(3,*)
field=data(4,*)
gsc=data(5,*)
err=data(6,*)
zone=data(7,*) 

 fxhmake,header,/extend,/date
 fxwrite,file,header
 fxbhmake,header,1,'objdata','Test Object Data Storage'
 fxbaddcol,racol,header,ra,'RA'
 fxbaddcol,deccol,header,dec,'DEC'
 fxbaddcol,bmagcol,header,bmag,'BMAG'
 fxbaddcol,rmagcol,header,rmag,'RMAG'
 fxbaddcol,fieldcol,header,field,'FIELD'
 fxbaddcol,gsccol,header,gsc,'GSC'
 fxbaddcol,errcol,header,err,'ERR'
 fxbaddcol,zonecol,header,zone,'ZONE'
 fxbcreate,unit,file,header
 fxbwrite,unit,ra,racol,1
 fxbwrite,unit,dec,deccol,1
 fxbwrite,unit,bmag,bmagcol,1
 fxbwrite,unit,rmag,rmagcol,1
 fxbwrite,unit,field,fieldcol,1
 fxbwrite,unit,gsc,gsccol,1
 fxbwrite,unit,err,errcol,1
 fxbwrite,unit,zone,zonecol,1
 fxbfinish,unit
 
 return
 end
