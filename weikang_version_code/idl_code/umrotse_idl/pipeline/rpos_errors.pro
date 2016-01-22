pro rpos_errors, x1,y1,x2,y2,m1,m2,kx,ky
;+
; NAME:	RPOSERRORS
;
; CALLING SEQUENCE:	rpos_errors, x1,y1,x2,y2,m1,m2,kx,ky
;
; INPUTS:	x1,y1:Coordinates in image 1
;		x2,y2:Coordinates in image 2
;		m1: indices of matched objects from image 1
;		m2: indices of matched objects from image 2
;		kx,ky: Transformation from 2 to 1
;		
;
; OUTPUTS:	Plots
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Plots xdiff vs. ydiff
;
; REVISION HISTORY:  
;	Tim McKay		UM		10/30/97	
;	Tim McKay		UM		4/16/98 Altered for kmap
;******************************************************************************

kmap,x2,y2,xx,yy,kx,ky

xdiff=x1(m1)-xx(m2)
ydiff=y1(m1)-yy(m2)

!p.multi=[0,2,2]
!p.title="Position errors for this fit"
!x.title="X offsets"
!y.title="Y offsets"
plot,xdiff,ydiff,psym=3
!y.title="X position"
plot,xdiff,x1(m1),psym=3
!x.title="Y offsets"
!y.title="Y position"
plot,ydiff,y1(m1),psym=3
!x.title="X offsets"
!y.title="Y position"
plot,xdiff,y1(m1),psym=3
!p.multi=[0,1,1]
!p.title=""
!x.title=""
!y.title=""


return 
end
