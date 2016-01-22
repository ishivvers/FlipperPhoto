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
;

 if N_params() eq 0 then begin
        print,'Syntax - tycho_regmatch_addpair,match,name1,name2,nmatch'
	return
 endif

;Figure out where everything is.....
  im_dir=getenv('ROTSE_IMDIR')
  if (im_dir eq "") then begin
	im_dir='./'
  endif else begin
	im_dir=im_dir+'/'
  endelse
  cobj_dir=getenv('ROTSE_CDIR')
  if (cobj_dir eq "") then begin
	cobj_dir='./'
  endif else begin
	cobj_dir=cobj_dir+'/'
  endelse


;First read in the image list. Right now the image header information
;is only stored with the images. But that HAS to change. We must figure
;out how to store the image header information in the calibrated object 
;files.
 l1=mrdfits(cobj_dir+name1,1,hdr)
 imhdr1=headfits(cobj_dir+name1)
 narr=str_sep(name1,'_cobj')
 imname1=narr(0)+'_c.fit'
 l2=mrdfits(cobj_dir+name2,1,hdr)
 imhdr2=headfits(cobj_dir+name2)
 narr=str_sep(name2,'_cobj')
 imname2=narr(0)+'_c.fit'
 
;Now define the parts of these lists which are within the selected region on
;the sky.

 ral=match.ral
 rah=match.rah
 decl=match.decl
 dech=match.dech

 rac=ral+(rah-ral)/2.0
 decc=decl+(dech-decl)/2.0

 n1=where(l1.ra gt ral and l1.ra lt rah and l1.dec gt decl and l1.dec lt dech)
 n2=where(l2.ra gt ral and l2.ra lt rah and l2.dec gt decl and l2.dec lt dech)

;Check to see whether any detected objects fall with these limits
 if ((size(n1))(0) eq 0) then begin
	print,"This observation has no objects with the limits of this match.."
	nmatch=match
	return
 endif
 if ((size(n2))(0) eq 0) then begin
	print,"This observation has no objects with the limits of this match.."
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

;Now figure out the warps between ra,dec and x,y for each of these....
 convert2xy,l1.ra,l1.dec,xc,yc,rac=rac,decc=decc
 polywarp,l1.x,l1.y,xc,yc,3,kx1,ky1 
 convert2xy,l2.ra,l2.dec,xc,yc,rac=rac,decc=decc
 polywarp,l2.x,l2.y,xc,yc,3,kx2,ky2 

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

 nmatch=create_struct("kx",findgen(nobs,4,4),"ky",findgen(nobs,4,4),"jd",$
	dindgen(nobs),$
	"filter",sindgen(nobs),"exptime",findgen(nobs),$
	"imagename",sindgen(nobs),"airmass",findgen(nobs),$
	"rac",findgen(1),"decc",findgen(1),$
	"ral",findgen(1),"rah",findgen(1),$
	"decl",findgen(1),"dech",findgen(1),$
	"m",findgen(nobs,nobj),$
	"merr",findgen(nobs,nobj),$
	"flags",indgen(nobs,nobj),$
	"ra",dindgen(nobj),$
	"dec",dindgen(nobj))

;Start by filling the relavent buffers with default values. These are used to
;determine whether an object has been observed.
  nmatch.m(*,*)=-1.0
  nmatch.merr(*,*)=-1.0
  nmatch.flags(*,*)=-1.0

;Now start stuffing the new structure
  nmatch.kx(0:nobs-3,*,*,*)=match.kx(*,*,*)
  nmatch.ky(0:nobs-3,*,*,*)=match.ky(*,*,*)
  nmatch.kx(nobs-2,*,*)=kx1
  nmatch.ky(nobs-2,*,*)=ky1
  nmatch.kx(nobs-1,*,*)=kx2
  nmatch.ky(nobs-1,*,*)=ky2
;Now try to stuff the frame specific information. 
  nmatch.jd(0:nobs-3)=match.jd(*)
  nmatch.filter(0:nobs-3)=match.filter(*)
  nmatch.imagename(0:nobs-3)=match.imagename(*)
  nmatch.exptime(0:nobs-3)=match.exptime(*)
  nmatch.airmass(0:nobs-3)=match.airmass(*)
  nmatch.jd(nobs-2)=sxpar(imhdr1,"JD")
  if (!err ne 0) then begin
	time=sxpar(imhdr1,"GMTTIME")
	ts=str_sep(time,' ')
	t=float(ts)
	juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], jd
	nmatch.jd(nobs-2)=jd
	!err=0
  endif
  nmatch.jd(nobs-1)=sxpar(imhdr2,"JD")
  if (!err ne 0) then begin
	time=sxpar(imhdr2,"GMTTIME")
	ts=str_sep(time,' ')
	t=float(ts)
	juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], jd
	nmatch.jd(nobs-1)=jd
	!err=0
  endif
  nmatch.filter(nobs-2)=sxpar(imhdr1,"FILTERS")
  if (!err ne 0) then begin
	  nmatch.filter(nobs-2)='none'
	  !err=0
  endif
  nmatch.filter(nobs-1)=sxpar(imhdr2,"FILTERS")
  if (!err ne 0) then begin
	  nmatch.filter(nobs-1)='none'
	  !err=0
  endif
  nmatch.imagename(nobs-2)=imname1
  nmatch.imagename(nobs-1)=imname1
  nmatch.exptime(nobs-2)=sxpar(imhdr1,"EXPTIME")
  if (!err ne 0) then begin
	  nmatch.exptime(nobs-2)=-1.0
	  !err=0
  endif
  nmatch.exptime(nobs-1)=sxpar(imhdr2,"EXPTIME")
  if (!err ne 0) then begin
	  nmatch.exptime(nobs-1)=-1.0
	  !err=0
  endif
  nmatch.airmass(nobs-2)=sxpar(imhdr1,"AIRMASS")
  if (!err ne 0) then begin
	  nmatch.airmass(nobs-2)=-1.0
	  !err=0
  endif
  nmatch.airmass(nobs-1)=sxpar(imhdr2,"AIRMASS")
  if (!err ne 0) then begin
	  nmatch.airmass(nobs-1)=-1.0
	  !err=0
  endif

; Now stuff the information on how you matched this
  nmatch.rac(0)=match.rac(0)
  nmatch.decc(0)=match.decc(0)
  nmatch.ral(0)=match.ral(0)
  nmatch.decl(0)=match.decl(0)
  nmatch.rah(0)=match.rah(0)
  nmatch.dech(0)=match.dech(0)

; Now stuff the old stuff
  nmatch.m(0:nobs-3,0:template_obj-1)=match.m(*,*)
  nmatch.merr(0:nobs-3,0:template_obj-1)=match.merr(*,*)
  nmatch.flags(0:nobs-3,0:template_obj-1)=match.flags(*,*)
  nmatch.ra(0:template_obj-1)=match.ra
  nmatch.dec(0:template_obj-1)=match.dec

; Now add the matches, be careful about maintaining the average ra,dec....
  if((size(m2))(0) ne 0) then begin
    nmatch.ra(m1)=((match.ra(m1)*(nobs-1)+l1(m2).ra+l2(m2).ra)/nobs)
    nmatch.dec(m1)=((match.dec(m1)*(nobs-1)+l1(m2).dec+l2(m2).dec)/nobs)
    nmatch.m(nobs-2,m1)=l1(m2).m
    nmatch.merr(nobs-2,m1)=l1(m2).merr
    nmatch.flags(nobs-2,m1)=l1(m2).flags
    nmatch.m(nobs-1,m1)=l2(m2).m
    nmatch.merr(nobs-1,m1)=l2(m2).merr
    nmatch.flags(nobs-1,m1)=l2(m2).flags
  endif

;A particular problem is dealing with objects in the template which 
;could not be seen in this image. I have to add code here to switch such
;objects from default -1 to -2 so they can be distinguished....

;Now stuff in objects found ONLY in this image....
  print, ""
  print, "Stuffing misses from image"
  nmatch.ra(template_obj:nobj-1)=l1(miss2).ra
  nmatch.dec(template_obj:nobj-1)=l1(miss2).dec
  nmatch.m(nobs-2,template_obj:nobj-1)=l1(miss2).m
  nmatch.merr(nobs-2,template_obj:nobj-1)=l1(miss2).merr
  nmatch.flags(nobs-2,template_obj:nobj-1)=l1(miss2).flags
  nmatch.m(nobs-1,template_obj:nobj-1)=l2(miss2).m
  nmatch.merr(nobs-1,template_obj:nobj-1)=l2(miss2).merr
  nmatch.flags(nobs-1,template_obj:nobj-1)=l2(miss2).flags

 return
 end






