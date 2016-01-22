pro plot_ipn, ipn, cobjfile, width=width
;+
; NAME:	PLOT_IPN
;
; CALLING SEQUENCE: plot_ipn, ipn, cobjfile, width=width
;
; INPUTS:	cobjfile: cobj structures
;		ipn: ipn structure (ra dec dist...)
;
; OUTPUTS:	
;	
; INPUT KEYWORDS:
;			width=width, what width (in degrees) to use
;			
; PROCEDURE:	Plots an IPN arc on an already displayed image based on 
;		cobj file....
;
; REVISION HISTORY:  
;	Tim McKay		UM	2/8/99
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - plot_ipn, ipn, cobjfile, width=width'
        return
 endif

 cal=mrdfits(cobjfile,1,hdr)
 convert2xy,cal.ra,cal.dec,xc,yc,rac=rac,decc=decc 
 polywarp,cal.x,cal.y,xc,yc,3,kx,ky

 if not keyword_set(width) then begin 
   convert2xy,ipn.ra,ipn.dec,xc,yc,rac=rac,decc=decc
   kmap,xc,yc,ipnx,ipny,kx,ky
   oplot,ipnx,ipny
 endif

 if keyword_set(width) then begin
   offset=width/(2*1.414)
   convert2xy,ipn.ra+offset,ipn.dec+offset,xc,yc,rac=rac,decc=decc
   kmap,xc,yc,ipnx,ipny,kx,ky
   oplot,ipnx,ipny
   convert2xy,ipn.ra-offset,ipn.dec-offset,xc,yc,rac=rac,decc=decc
   kmap,xc,yc,ipnx,ipny,kx,ky
   oplot,ipnx,ipny
 endif

 return
 end