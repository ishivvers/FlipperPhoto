pro tycho_regmatch_begin,name1,name2,ral,rah,decl,dech,match,stat,pair=pair
;+
; NAME:	TYCHO_REGMATCH_BEGIN
;
; CALLING SEQUENCE: tycho_regmatch_begin,name1,name2,ral,rah,decl,dech,
;				match,pair=pair
;
; INPUTS:	name1, name2: names of cobj files to use
;		ral,rah,decl,deh: ra and dec limits to keep
; OUTPUTS:	match: the new tycho match structure
;	
; INPUT KEYWORDS:
;		pair: set this if you want to save ONLY the matches from
;			this pair...
;			
; PROCEDURE:	The purpose of this function is to set up the template for
;	adding subsequent observations of this region of the sky. To that end
;	the observations fed in here should be two observations which are 
;	nearly contemporary, and which both nicely cover the region requested.
;	This second restriction will be relaxed soon, but the way the code is
;	now it is required.
;	
; REVISION HISTORY:  
;	Tim McKay		UM	10/28/98
;	06-05-00	Bob Kehoe -- fix RA/Dec averaging to account for varying 
;				     number of observations per object, allow 
;				     consecutive matching, standardize to
;				     make_match_struct, added several variables
;				     to match struct, converted to reading stats 
;				     struct instead of image header,
;       09-06-00        Don Smith -- added a backwards-compatability check to make
;                                    sure that the structures read in from the cobj
;                                    data files contain all the correct fields,
;       10-12-00	Bob Kehoe -- patched to handle RA = 360deg. problem, a more
;				     sophisticated approach will be necessary in the 
;				     future

 if N_params() eq 0 then begin
        print,'Syntax - tycho_regmatch_begin,name1,name2,ral,rah,decl,dech,match,stat,pair=pair'
	return
 endif

;Figure out where everything is.....
  cobj_dir=getenv('ROTSE_CDIR')
  if (cobj_dir eq "") then begin
	cobj_dir='./'
  endif else begin
	cobj_dir=cobj_dir+'/'
  endelse

;First read in the two image lists. 

 l1=mrdfits(cobj_dir+name1,1,hdr)
 l2=mrdfits(cobj_dir+name2,1,hdr)
 st1 = mrdfits(cobj_dir+name1,2,hdr)
 st2 = mrdfits(cobj_dir+name2,2,hdr)

;Make sure that these structures match the most recent format

 update_match_stru,l1,st1
 update_match_stru,l2,st2

 diff = st1.rac - st2.rac
 if (abs(diff) gt 350.0 and abs(diff) lt 370.0) then begin
    if (diff lt 0) then l2.ra = l2.ra - 360.0 
    if (diff gt 0) then l2.ra = l2.ra + 360.0
 ENDIF

;Now define the parts of these lists which are within the selected region on
;the sky.

 n1=where(l1.ra gt ral and l1.ra lt rah and l1.dec gt decl and l1.dec lt dech)
 n2=where(l2.ra gt ral and l2.ra lt rah and l2.dec gt decl and l2.dec lt dech)

;Reduce the lists to just these parts of the list
 l1=l1(n1)
 l2=l2(n2)

;Now actually match these pieces of the two structures
 close_match_radec,l1.ra,l1.dec,l2.ra,l2.dec,m1,m2,0.005,1.0,miss1

;Keep ALL the objects only if the pair keyword is not set......
 if not keyword_set(pair) then begin

;Find the number of objects which match and don't
    nmisses1=N_elements(miss1)
    nmatches=N_elements(m1)
    n2=n_elements(l2)
    miss2=lindgen(n2)
    remove,m2,miss2
    nmisses2=n_elements(miss2)
    nobj=nmatches+nmisses1+nmisses2
    print,"Objects:",nobj,"  nmatches:",nmatches
    print,"   nmisses1:",nmisses1,"   nmisses2:",nmisses2

; Create and stuff match structure...

    match = make_match_struct(2, nobj, extended=1)
    match.numobs = 1
    match.jd[0] = st1.mjd
    match.exptime[0] = st1.exptime
    match.imagename[0] = st1.filename
    match.kx[0,*,*] = st1.kx
    match.ky[0,*,*] = st1.ky
    match.rac[0] = st1.rac
    match.decc[0] = st1.decc
    match.ral=ral
    match.rah=rah
    match.decl=decl
    match.dech=dech
    match.jd[1] = st2.mjd
    match.exptime[1] = st2.exptime
    match.imagename[1] = st2.filename
    match.kx[1,*,*] = st2.kx
    match.ky[1,*,*] = st2.ky
    match.rac[1] = st2.rac
    match.decc[1] = st2.decc

    match.numobs[0:nmatches-1] = match.numobs[0:nmatches-1] + 1
    match.ra(0:nmatches-1)=(l1(m1).ra+l2(m2).ra)/2.0
    match.dec(0:nmatches-1)=(l1(m1).dec+l2(m2).dec)/2.0

    match.m(0,0:nmatches-1)=l1(m1).m
    match.merr(0,0:nmatches-1)=l1(m1).merr
    match.flags(0,0:nmatches-1)=l1(m1).flags
    match.dra(0,0:nmatches-1)=l1(m1).ra
    match.ddec(0,0:nmatches-1)=l1(m1).dec
    match.rflags(0,0:nmatches-1)=l1(m1).rflags
    match.msys(0,0:nmatches-1)=l1(m1).msys200

    match.m(1,0:nmatches-1)=l2(m2).m
    match.merr(1,0:nmatches-1)=l2(m2).merr
    match.flags(1,0:nmatches-1)=l2(m2).flags
    match.dra(1,0:nmatches-1)=l2(m2).ra
    match.ddec(1,0:nmatches-1)=l2(m2).dec
    match.rflags(1,0:nmatches-1)=l2(m2).rflags
    match.msys(1,0:nmatches-1)=l2(m2).msys200
    find_consec,stat[1].mjd,stat.mjd,iconsec
    if ((size(iconsec))[1] gt 0) then begin
       iconsec = match_names(stat[iconsec].filename, match.imagename)
       num_consec = (size(iconsec))[1]
       if ((size(iconsec))[0] ne 0 and num_consec gt 0) then begin
          try_consec = where(match.consec eq 0, count)
	  if (count gt 0) then begin
	     for k = 0,num_consec-1 do begin
		index = where(match.m[iconsec[k],try_consec] gt -1.0, count)
		if (count gt 0) then match.consec[try_consec[index]] = 1
             endfor
	  endif
       endif
    endif

    print, "Stuffing objects only in image 1"

    match.ra(nmatches:nmatches+nmisses1-1)=l1(miss1).ra
    match.dec(nmatches:nmatches+nmisses1-1)=l1(miss1).dec
    match.m(0,nmatches:nmatches+nmisses1-1)=l1(miss1).m
    match.merr(0,nmatches:nmatches+nmisses1-1)=l1(miss1).merr
    match.flags(0,nmatches:nmatches+nmisses1-1)=l1(miss1).flags
    match.dra(0,nmatches:nmatches+nmisses1-1)=l1(miss1).ra
    match.ddec(0,nmatches:nmatches+nmisses1-1)=l1(miss1).dec
    match.msys(0,nmatches:nmatches+nmisses1-1)=l1(miss1).msys200
    match.rflags(0,nmatches:nmatches+nmisses1-1)=l1(miss1).rflags

    print, "Stuffing objects only in image 2"

    match.ra(nmatches+nmisses1:nobj-1)=l2(miss2).ra
    match.dec(nmatches+nmisses1:nobj-1)=l2(miss2).dec
    match.m(1,nmatches+nmisses1:nobj-1)=l2(miss2).m
    match.merr(1,nmatches+nmisses1:nobj-1)=l2(miss2).merr
    match.flags(1,nmatches+nmisses1:nobj-1)=l2(miss2).flags
    match.dra(1,nmatches+nmisses1:nobj-1)=l2(miss2).ra
    match.ddec(1,nmatches+nmisses1:nobj-1)=l2(miss2).dec
    match.msys(1,nmatches+nmisses1:nobj-1)=l2(miss2).msys200
    match.rflags(1,nmatches+nmisses1:nobj-1)=l2(miss2).rflags

 endif else begin
;   Find the number of objects which match and don't
    nmisses1=N_elements(miss1)
    nmatches=N_elements(m1)
    n2=n_elements(l2)
    miss2=lindgen(n2)
    remove,m2,miss2
    nmisses2=n_elements(miss2)
    nobj=nmatches+nmisses1+nmisses2
    print,"Objects:",nobj,"  nmatches:",nmatches
    print,"   nmisses1:",nmisses1,"   nmisses2:",nmisses2
    print,"Keeping only the matches!!!!!!!!"
    nobj=nmatches

; Create and stuff match structure...

    match = make_match_struct(2, nobj, extended=1)
    match.numobs = 2
    match.jd[0] = st1.mjd
    match.exptime[0] = st1.exptime
    match.imagename[0] = st1.filename
    match.kx[0,*,*] = st1.kx
    match.ky[0,*,*] = st1.ky
    match.rac[0] = st1.rac
    match.decc[0] = st1.decc
    match.ral=ral
    match.rah=rah
    match.decl=decl
    match.dech=dech
    match.jd[1] = st2.mjd
    match.exptime[1] = st2.exptime
    match.imagename[1] = st2.filename
    match.kx[1,*,*] = st2.kx
    match.ky[1,*,*] = st2.ky
    match.rac[1] = st2.rac
    match.decc[1] = st2.decc

    match.ra(0:nmatches-1)=(l1(m1).ra+l2(m2).ra)/2.0
    match.dec(0:nmatches-1)=(l1(m1).dec+l2(m2).dec)/2.0

    match.m(0,0:nmatches-1)=l1(m1).m
    match.merr(0,0:nmatches-1)=l1(m1).merr
    match.flags(0,0:nmatches-1)=l1(m1).flags
    match.dra(0,0:nmatches-1)=l1(m1).ra
    match.ddec(0,0:nmatches-1)=l1(m1).dec
    match.msys(0,0:nmatches-1)=l1(m1).msys200
    match.rflags(0,0:nmatches-1)=l1(m1).rflags

    match.m(1,0:nmatches-1)=l2(m2).m
    match.merr(1,0:nmatches-1)=l2(m2).merr
    match.flags(1,0:nmatches-1)=l2(m2).flags
    match.dra(1,0:nmatches-1)=l2(m2).ra
    match.ddec(1,0:nmatches-1)=l2(m2).dec
    match.msys(1,0:nmatches-1)=l2(m2).msys200
    match.rflags(1,0:nmatches-1)=l2(m2).rflags
 endelse

 return
end













