pro rel_photo_region, cal1, cal2, rac, decc, raedge, decedge
;+
; NAME:	rel_photo
;
; CALLING SEQUENCE:  rel_photo_region,cal1, cal2, rac, decc, raedge, decedge;
;
; INPUTS:	cal1, cal2: calibrated object structures
;		rac,decc: RA and DEC center of the region to check
;		raedge,decedge: size of box in ra and dec degrees
;
; OUTPUTS:	
;			  
;	
; INPUT KEYWORDS:
;			
; PROCEDURE: 	Compares photometry of objects in a particular region...
;
; REVISION HISTORY:  
;	Tim McKay		UM		4/29/98	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - rel_photo_region, cal1, cal2, rac, decc, raedge, decedge'
        return
 endif

 ral=rac-(raedge/2.0)
 rah=rac+(raedge/2.0)
 decl=decc-(decedge/2.0)
 dech=decc+(decedge/2.0)
 k1=where(cal1.ra gt ral and cal1.ra lt rah and cal1.dec gt decl $
	and cal1.dec lt dech)
 k2=where(cal2.ra gt ral and cal2.ra lt rah and cal2.dec gt decl $
	and cal2.dec lt dech)

 c1=cal1(k1)
 c2=cal2(k2)

 close_match_radec,c1.ra,c1.dec,c2.ra,c2.dec,m1,m2,0.005,1.0,miss1

 help,m1
 print,median(c1(m1).m-c2(m2).m)

 plot,c1(m1).m-c2(m2).m,c1(m1).m,psym=1,xrange=[-3,3],yrange=[5,18]

 return

 end


