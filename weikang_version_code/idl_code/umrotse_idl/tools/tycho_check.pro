pro tycho_check, cal
;+
; NAME:	tycho_check
;
; CALLING SEQUENCE: tycho_check, cal
;
; INPUTS:	cal: a structure from tychocal_test
;
; OUTPUTS:	
;			  
; INPUT KEYWORDS:
;			
; PROCEDURE: 	Compares photometry of objects to their tycho information
;
; REVISION HISTORY:  
;	Tim McKay		UM		1/28/99	
;******************************************************************************
if N_params() eq 0 then begin
        print,'Syntax - tycho_check, cal'
        return
 endif

 k=where(cal.vmag lt 20 and cal.vmag gt 0)

 c=cal(k)

 !p.multi=[0,2,2]
 plot,c.bmag-c.vmag,c.m,psym=3,xrange=[-3,3],yrange=[5,15]
 plot,c.rmag-c.m,c.m,psym=3,xrange=[-3,3],yrange=[5,15]
 plot,c.x,c.rmag-c.m,psym=3,yrange=[-3,3]
 plot,c.y,c.rmag-c.m,psym=3,yrange=[-3,3]
 !p.multi=[0,1,1]

 print,'Found matches for ',strtrim(string(n_elements(k))),' objects'
 print,'Median R mag difference is ',strtrim(string(median(c.rmag-c.m)))
 print,'Median V mag difference is ',strtrim(string(median(c.vmag-c.m)))
 print,'Median B mag difference is ',strtrim(string(median(c.bmag-c.m)))


 return
 end

