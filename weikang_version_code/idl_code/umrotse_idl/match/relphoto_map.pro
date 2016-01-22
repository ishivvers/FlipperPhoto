pro relphoto_map, match, n1, n2, nmags, map=map, nbox=nbox, frac=frac
;+
; NAME:	relphoto_map
;
; CALLING SEQUENCE:	relphoto_map, match, n1, n2, map
;
; INPUTS:	match: match structure produced by catmatch_s or addmatch_s
;		n1: index of reference observation
;		n2: index of observation to calibrate
;
; OUTPUTS:	map: map of photometric offset at each location
;	
; INPUT KEYWORDS:
;		nbox: number of boxes in which to do the calibration
;			(16 means use a 16x16 grid...)
;			
; PROCEDURE:	Does observation to observation relative offsets which are
;		variable across the frame
;
; REVISION HISTORY:  
;	Tim McKay		UM		7/31/98
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - relphoto_map, match, n1, n2, nmags, map=map, nbox=nbox'
        return
 endif

 if not keyword_set(nbox) then begin
	nbox=10
 endif
 if not keyword_set(frac) then begin
	frac=0.5
 endif

 info=size(match.m)
 nmags=findgen(2,info(2))
 nmags(0,*)=match.m(n1,*)
 nmags(1,*)=match.m(n2,*)

 rac=match.rac
 decc=match.decc

 convert2xy,match.ra,match.dec,x,y,rac=rac,decc=decc

 xmax=max(x)
 xmin=min(x)
 ymax=max(y)
 ymin=min(y)

 xrange=xmax-xmin
 yrange=ymax-ymin

 xbin=xrange/nbox
 ybin=yrange/nbox

 map=findgen(3,nbox,nbox)

 ;First find a global offset....
 k=where(match.m(n1,*) gt 8 and match.m(n1,*) lt 30 and $
		match.m(n2,*) gt 8 and match.m(n2,*) lt 30) 
 info=size(k)
 if (info(0) ne 0 and info(1) gt 1) then begin
   n=info(1)*frac
   if (n gt 1) then begin
     magdiff=match.m(n1,k(0:n))-match.m(n2,k(0:n))
   endif else begin
     magdiff=match.m(n1,k)-match.m(n2,k)
   endelse
   stats=moment(magdiff)
   global_offset=stats(0)
 endif else begin
   print,'No objects overlap'
 endelse

 for nx=0,nbox-1,1 do begin
   for ny=0,nbox-1,1 do begin
 	xlow=xmin+nx*xbin
	xhigh=xmin+(nx+1)*xbin
	ylow=ymin+ny*ybin
	yhigh=ymin+(ny+1)*ybin
	k=where(x ge xlow and x lt xhigh and y ge ylow and y lt yhigh $
		and match.m(n1,*) gt 8 and match.m(n1,*) lt 30 and $
		match.m(n2,*) gt 8 and match.m(n2,*) lt 30)
	info=size(k)
	if (info(0) ne 0 and info(1) gt 20) then begin
	 n=info(1)*frac
	 if (n gt 1) then begin
	   magdiff=match.m(n1,k(0:n))-match.m(n2,k(0:n))
	 endif else begin
	   ;magdiff=match.m(n1,k)-match.m(n2,k)
	 endelse
	 stats=moment(magdiff)
	 map(0,nx,ny)=stats(0)
	 map(1,nx,ny)=stats(1)
	 map(2,nx,ny)=n
	 if (stats(1) gt 1.0) then begin
		help,k
		print,nx,ny
		plothist,magdiff
		wait,3
	 endif
	 nmags(1,k)=nmags(1,k)+stats(0)
	endif else begin
	 map(0,nx,ny)=global_offset
	 map(1,nx,ny)=0.0
	 map(2,nx,ny)=0.0
	endelse
  endfor
 endfor
 
 return
 end	







