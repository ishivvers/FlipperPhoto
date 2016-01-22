pro tycho_regmatch_addpair,match,name1,name2,nmatch
;+
; NAME:	TYCHO_REGMATCH_ADDPAIR
;
; CALLING SEQUENCE: tycho_regmatch_addpair,match,name1,name2,nmatch
;
; INPUTS:	match: a match structure from tycho_regmatch_begin
;		name1: a new tycho calibrated sextractor output filename
;		name2: second member of an observation pair
; OUTPUTS:	nmatch: the new, larger, tycho match structure
;	
; INPUT KEYWORDS:
;			
; PROCEDURE:	The purpose of this function is to add an pair of 
;	observations to a tycho field template. It should allow you to
;	input a file which has minor (or no) overlap with this field
;	and handle it gracefully. 
;	
; REVISION HISTORY:  
;	Tim McKay		UM	11/5/98
;	06-05-00	Bob Kehoe -- fix RA/Dec averaging to account for varying 
;				     number of observations per object, standardize
;				     to make_match_struct, added several variables
;				     to match struct, converted to reading stats 
;				     struct instead of image header
;	10-12-00	Bob Kehoe -- patch RA=360 problem
;================================================================================

 if N_params() eq 0 then begin
        print,'Syntax - tycho_regmatch_addpair,match,name1,name2,nmatch'
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
; diff = match.stat.rac - st1.rac
diff = match.rac(0) - st1.rac
 if (abs(diff) gt 350.0 and abs(diff) lt 370.0) then begin
    if (diff lt 0) then l1.ra = l1.ra - 360.0 
    if (diff gt 0) then l1.ra = l1.ra + 360.0
 endif
 l2=mrdfits(cobj_dir+name2,1,hdr)
 st2 = mrdfits(cobj_dir+name2,2,hdr)
; diff = match.stat.rac - st2.rac
 diff = match.rac(0) - st2.rac
 if (abs(diff) gt 350.0 and abs(diff) lt 370.0) then begin
    if (diff lt 0) then l2.ra = l2.ra - 360.0 
    if (diff gt 0) then l2.ra = l2.ra + 360.0
 endif

;Make sure that these structures match the most recent format

 update_match_stru,l1,st1
 update_match_stru,l2,st2

;Now define the parts of these lists which are within the selected region on
;the sky.

 ral=match.ral
 rah=match.rah
 decl=match.decl
 dech=match.dech
 n1=where(l1.ra gt ral and l1.ra lt rah and l1.dec gt decl and l1.dec lt dech)
 n2=where(l2.ra gt ral and l2.ra lt rah and l2.dec gt decl and l2.dec lt dech)

;Check to see whether any detected objects fall with these limits
 if ((size(n1))(1) lt 300) then begin
	print,"This observation has too few objects with the limits of this match."
	nmatch=match
	return
 endif
 if ((size(n2))(1) lt 300) then begin
	print,"This observation has too few objects with the limits of this match."
	nmatch=match
	return
 endif

;Reduce the lists to just these parts of the list
 l1=l1(n1)
 l2=l2(n2)

;First, match the two lists together......
 close_match_radec,l1.ra,l1.dec,l2.ra,l2.dec,m1,m2,0.005,1.0,miss1

;Now reduce the lists to include JUST the ones which match.....
 l1=l1(m1)
 l2=l2(m2)

;Now actually match these from one list to the master 
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
 nobs=N_elements(match.jd)+2
 print, "Number of observations=",nobs,"      Number of objects=",nobj

; Create new match structure and stuff with old structure.
; Add new info. later.

  nmatch = make_match_struct(nobs, nobj, old=match, extended=1)
  nmatch.kx[nobs-2,*,*] = st1.kx
  nmatch.ky[nobs-2,*,*] = st1.ky
  nmatch.rac[nobs-2] = st1.rac
  nmatch.decc[nobs-2] = st1.decc
  nmatch.jd[nobs-2] = st1.mjd
  nmatch.imagename[nobs-2] = st1.filename
  nmatch.exptime[nobs-2] = st1.exptime
  nmatch.kx[nobs-1,*,*] = st2.kx
  nmatch.ky[nobs-1,*,*] = st2.ky
  nmatch.rac[nobs-1] = st2.rac
  nmatch.decc[nobs-1] = st2.decc
  nmatch.jd[nobs-1] = st2.mjd
  nmatch.imagename[nobs-1] = st2.filename
  nmatch.exptime[nobs-1] = st2.exptime

; Now add the matches, be careful about maintaining the average ra,dec....
  if((size(m2))(0) ne 0) then begin
    nmatch.ra(m1)=((match.ra(m1)*(nmatch.numobs[m1])+l1(m2).ra+l2(m2).ra)/$
				(nmatch.numobs[m1]+2))
    nmatch.dec(m1)=((match.dec(m1)*(nmatch.numobs[m1])+l1(m2).dec+l2(m2).dec)/$
				(nmatch.numobs[m1]+2))
    nmatch.numobs[m1] = nmatch.numobs[m1] + 2
    nmatch.m(nobs-2,m1)=l1(m2).m
    nmatch.merr(nobs-2,m1)=l1(m2).merr
    nmatch.flags(nobs-2,m1)=l1(m2).flags
    nmatch.dra(nobs-2,m1)=l1(m2).ra
    nmatch.ddec(nobs-2,m1)=l1(m2).dec
    nmatch.msys(nobs-2,m1)=l1(m2).msys200
    nmatch.rflags(nobs-2,m1)=l1(m2).rflags

    nmatch.m(nobs-1,m1)=l2(m2).m
    nmatch.merr(nobs-1,m1)=l2(m2).merr
    nmatch.flags(nobs-1,m1)=l2(m2).flags
    nmatch.dra(nobs-1,m1)=l2(m2).ra
    nmatch.ddec(nobs-1,m1)=l2(m2).dec
    nmatch.msys(nobs-1,m1)=l2(m2).msys200
    nmatch.rflags(nobs-1,m1)=l2(m2).rflags
  endif

;Now stuff in objects found ONLY in this image....
  print, ""
  print, "Stuffing misses from image"
  nmatch.numobs[template_obj:nobj-1] = 2
  nmatch.ra(template_obj:nobj-1)=l1(miss2).ra
  nmatch.dec(template_obj:nobj-1)=l1(miss2).dec
  nmatch.m(nobs-2,template_obj:nobj-1)=l1(miss2).m
  nmatch.merr(nobs-2,template_obj:nobj-1)=l1(miss2).merr
  nmatch.flags(nobs-2,template_obj:nobj-1)=l1(miss2).flags
  nmatch.dra(nobs-2,template_obj:nobj-1)=l1(miss2).ra
  nmatch.ddec(nobs-2,template_obj:nobj-1)=l1(miss2).dec
  nmatch.msys(nobs-2,template_obj:nobj-1)=l1(miss2).msys200
  nmatch.rflags(nobs-2,template_obj:nobj-1)=l1(miss2).rflags

  nmatch.m(nobs-1,template_obj:nobj-1)=l2(miss2).m
  nmatch.merr(nobs-1,template_obj:nobj-1)=l2(miss2).merr
  nmatch.flags(nobs-1,template_obj:nobj-1)=l2(miss2).flags
  nmatch.dra(nobs-1,template_obj:nobj-1)=l2(miss2).ra
  nmatch.ddec(nobs-1,template_obj:nobj-1)=l2(miss2).dec
  nmatch.msys(nobs-1,template_obj:nobj-1)=l2(miss2).msys200
  nmatch.rflags(nobs-1,template_obj:nobj-1)=l2(miss2).rflags

  return
end






