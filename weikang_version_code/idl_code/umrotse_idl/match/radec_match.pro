pro radec_match,m1,m2,newmatch,angdiff=angdiff
;+
; NAME:	RADEC_MATCH
;
; CALLING SEQUENCE:	radec_match.pro,m1,m2,newmatch
;
; INPUTS:	m1: first match structure
;		m2: second match structure
;
; OUTPUTS:	newmatch: combined structure, merged on (ra,dec)
;	
; INPUT KEYWORDS:
;		angdiff: angular difference (in ") to allow
;			
; PROCEDURE:	Merges the two matched structures into a single list
;		by matching in ra,dec for the whole thing.
;
; REVISION HISTORY:  
;	Tim McKay		UM	6/23/98	Created
;-

 if N_params() eq 0 then begin
        print,'Syntax - radec_match,m1,m2,newmatch'
        return
 endif

 ra1h=m1.ra/15.0
 ra2h=m2.ra/15.0
 dec1=m1.dec
 dec2=m2.dec

 dec=0.5*(mean(dec1)+mean(dec2))

 ;Will search a 60" box for a match....
 decang=0.017
 raang=0.017/(15.0*cos(dec*0.01745329))

 print,raang,decang


 k=where(abs(radiff) lt raang and abs(decdiff) lt decang)
 index=k

 info=size(k)
 print,info
 darr=findgen (info(1))
 if (info(0) eq 0) then begin
	print,'No matching object found!'
	return
 endif
 if (info(1) gt 1 and info(0) ne 0) then begin
	for i=0,info(1)-1,1 do begin
	  gcirc,1,rah,dec,ralh(k(i)),decl(k(i)),dist
	  print,i,k(i),dist
	  print,"       ",rah,dec,ralh(k(i)),decl(k(i))
	  darr(i)=dist
	endfor
 endif
 print,darr

 return
 end

