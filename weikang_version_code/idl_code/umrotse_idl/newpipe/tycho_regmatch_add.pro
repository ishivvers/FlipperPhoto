pro tycho_regmatch_add,match,name1,stat,nmatch
;+
; NAME:	TYCHO_REGMATCH_ADD
;
; CALLING SEQUENCE: tycho_regmatch_add,match,name1,nmatch
;
; INPUTS:	match: a match structure from tycho_regmatch_begin
;		name1: a new tycho calibrated sextractor output filename
; OUTPUTS:	nmatch: the new, larger, tycho match structure
;	
; INPUT KEYWORDS:
;
; PROCEDURE:	The purpose of this function is to add an additional 
;	observation to a tycho field template.  It allows you to
;	input a file which has minor (or no) overlap with this field
;	and handle it gracefully. 
;	
; REVISION HISTORY:  
;	Tim McKay		UM	10/30/98
;	06-05-00	Bob Kehoe -- fix RA/Dec averaging to account for varying 
;				     number of observations per object, allow 
;				     consecutive matching, standardize to
;				     make_match_struct, added several variables
;				     to match struct, converted to reading stats 
;				     struct instead of image header
;	10-12-00	Bob Kehoe -- patched RA=360 problem
;================================================================================

 if N_params() eq 0 then begin
        print,'Syntax - tycho_regmatch_add,match,name1,stat,nmatch'
	return
 endif

;Figure out where everything is.....
  cobj_dir=getenv('ROTSE_CDIR')
  if (cobj_dir eq "") then begin
	cobj_dir='./'
  endif else begin
	cobj_dir=cobj_dir+'/'
  endelse

;First read in the image list. 

 l1=mrdfits(cobj_dir+name1,1,hdr) 
 st1 = mrdfits(cobj_dir+name1,2,hdr)
;diff = match.stat.rac - st1.rac
 diff = match.rac(0) - st1.rac
 if (abs(diff) gt 350.0 and abs(diff) lt 370.0) then begin
    if (diff lt 0) then l1.ra = l1.ra - 360.0 
    if (diff gt 0) then l1.ra = l1.ra + 360.0
 endif
 
;Now define the parts of these lists which are within the selected region on
;the sky.

 ral=match.ral
 rah=match.rah
 decl=match.decl
 dech=match.dech
 n1=where(l1.ra gt ral and l1.ra lt rah and l1.dec gt decl and l1.dec lt dech)

;Check to see whether any detected objects fall with these limits
 if ((size(n1))(1) lt 300) then begin
	print,"This observation has too few objects with the limits of this match.."
	print,"Nobjects = ",(size(n1))(1)
	nmatch=match
	return
 endif

;Reduce the lists to just these parts of the list
 l1=l1(n1)

;Now actually match these pieces of the two structures
 close_match_radec,match.ra,match.dec,l1.ra,l1.dec,m1,m2,0.005,1.0,miss1

;Find the number of objects which match and don't
 print,"  "
 print, "Stuffing matches"
 template_obj=N_elements(match.ra)
 n2=N_elements(l1.ra)
 miss2=lindgen(n2)
 if((size(m2))(0) ne 0) then begin
   remove,m2,miss2
 endif
 nmisses=N_elements(miss2)
 nobj=template_obj+nmisses
 nobs=N_elements(match.jd)+1
 print, "Number of observations=",nobs,"      Number of objects=",nobj

; Create new match structure and stuff first part with old structure.
; Add new information last.

  nmatch = make_match_struct(nobs, nobj, old=match, extended=1)
  nmatch.kx[nobs-1,*,*] = st1.kx
  nmatch.ky[nobs-1,*,*] = st1.ky
  nmatch.rac[nobs-1] = st1.rac
  nmatch.decc[nobs-1] = st1.decc
  nmatch.jd[nobs-1] = st1.mjd
  nmatch.imagename[nobs-1] = st1.filename
  nmatch.exptime[nobs-1] = st1.exptime

; Now add the matches, be careful about maintaining the average ra,dec....
  if((size(m2))(0) ne 0) then begin
    nmatch.ra(m1)=((match.ra(m1)*(nmatch.numobs[m1])+l1(m2).ra)/(nmatch.numobs[m1]+1))
    nmatch.dec(m1)=((match.dec(m1)*(nmatch.numobs[m1])+l1(m2).dec)/(nmatch.numobs[m1]+1))
    nmatch.numobs[m1] = nmatch.numobs[m1] + 1
    nmatch.m(nobs-1,m1)=l1(m2).m
    nmatch.merr(nobs-1,m1)=l1(m2).merr
    nmatch.flags(nobs-1,m1)=l1(m2).flags
    nmatch.dra(nobs-1,m1)=l1(m2).ra
    nmatch.ddec(nobs-1,m1)=l1(m2).dec
    nmatch.msys(nobs-1,m1)=l1(m2).msys200
    nmatch.rflags(nobs-1,m1)=l1(m2).rflags
    istat = match_names(nmatch.imagename[nobs-1],stat.filename)
    find_consec,stat[istat].mjd,stat.mjd,iconsec
    if ((size(iconsec))[1] gt 0) then begin
       iconsec = match_names(stat[iconsec].filename, nmatch.imagename)
       num_consec = (size(iconsec))[1]
       if ((size(iconsec))[0] ne 0 and num_consec gt 0) then begin
          try_consec = where(nmatch.consec[m1] eq 0, count)
	  if (count gt 0) then begin
	     try_consec = m1[try_consec]
	     for k = 0,num_consec-1 do begin
		index = where(nmatch.m[iconsec[k],try_consec] gt -1.0, count)
		if (count gt 0) then nmatch.consec[try_consec[index]] = 1
             endfor
	  endif
       endif
    endif
  endif

;Now stuff in objects found ONLY in this image....
  print, ""
  print, "Stuffing misses from image"
  nmatch.numobs[template_obj:nobj-1] = 1
  nmatch.ra(template_obj:nobj-1)=l1(miss2).ra
  nmatch.dec(template_obj:nobj-1)=l1(miss2).dec
  nmatch.m(nobs-1,template_obj:nobj-1)=l1(miss2).m
  nmatch.merr(nobs-1,template_obj:nobj-1)=l1(miss2).merr
  nmatch.flags(nobs-1,template_obj:nobj-1)=l1(miss2).flags
  nmatch.dra(nobs-1,template_obj:nobj-1)=l1(miss2).ra
  nmatch.ddec(nobs-1,template_obj:nobj-1)=l1(miss2).dec
  nmatch.msys(nobs-1,template_obj:nobj-1)=l1(miss2).msys200
  nmatch.rflags(nobs-1,template_obj:nobj-1)=l1(miss2).rflags

  return
end






