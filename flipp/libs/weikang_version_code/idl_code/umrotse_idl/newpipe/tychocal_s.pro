pro tychocal_s, imhdr, sobjhdr, tcat, sobj, badpix, bpexptime,cal, stats, keep=keep, skip=skip, $
	iter=iter, kx=kx, ky=ky, hdr=hdr, subr=subr, rskip=rskip, $
	fail=fail, ebox=ebox, nusefrac=nusefrac, plots=plots, $
	rac=rac,decc=decc
;+
; NAME:	TYCHOCAL_S
;
; CALLING SEQUENCE:	tychocal_s, imhdr, sobjhdr, tcal, sobj, cal, stats, badpix
;
; INPUTS:	imhdr: header from the image in question
;		sobjhdr: header from the sobj file in question
;		tcat: tycho catalog 
;		sobj: object structure from image derived from Sextractor
;		badpix: bad pixel structure
;		bpexptime: exposure time for bad pixel struct.
;
; OUTPUTS:	cal: calibrated sobj structure
;		stats: statistics of the calibration
;
; INPUT KEYWORDS:
;		keep: how many objects to match
;		skip: how many of the brightest to skip
;		iter: how many iterations of the fit to do
;		kx:   return of transform x coefficients
;		ky:   return of transform y coefficients
;		hdr:  pass this to get times etc. in the output structure
;		subr: the fraction of the image to match to the catalog
;		rskip: number of brightest rotse objects to skip
;		fail: return 1 here if it doesn't match
;		ebox: size (in pixels) for final match requirement
;		plots: set this if you want diagnostic plots
;		rac: image ra center
;		decc: image dec center
;			
; PROCEDURE:	Matches and transforms two object structures
;		Structures must contain the following elements:
;		TCAT: ra, dec, bmag, vmag, varflag
;		SOBJ: x_image, y_image, mag_best, fwhm_image
;
; REVISION HISTORY:  
;	Tim McKay		UM		10/23/98
;	Tim McKay		UM		11/19/98	
;	Tim McKay		UM		05/17/99
;		Made changes to the cuts in iteration to attempt to 
;		improve the rate of convergence
;    	Eli Rykoff		UM		02/23/00
;		Minor fixes
;	Eli Rykoff		UM		05/30/00
;		Matches objects to a bad pixel structure, and estimates
;		a systematic error. Outputs kx,ky,rac,decc to tychocal_list
;	Eli Rykoff		UM		06/28/00
;		Estimates a systematic error for saturated objects
;******************************************************************************
;-

 if N_params() eq 0 then begin
        print,"Syntax - tychocal_s, imhdr, sobjhdr, tcat, sobj, badpix, bpexptime, cal, stats, keep=keep, skip=skip, iter=iter, kx=kx, ky=ky, hdr=hdr, subr=subr, rskip=rskip, fail=fail, ebox=ebox, nusefrac=nusefrac, plots=plots"
        return
 endif

  fail=0

  if not keyword_set(skip) then begin
	skip=0
  end
  if not keyword_set(rskip) then begin
	rskip=0
  end
  if not keyword_set(keep) then begin
	keep=30
  end
  if not keyword_set(iter) then begin
	iter=8
  end
  if not keyword_set(subr) then begin
	subr=0.5
  end
  if not keyword_set(ebox) then begin
	ebox=1.0
  end
  if not keyword_set(nusefrac) then begin
	nusefrac=0.2
  end
  if not keyword_set(plots) then begin
	plots=0.0
  endif

;Perform a swindle for frames without the ra and dec in the header....
  if keyword_set(rac) then begin
	sxaddpar,imhdr,'mountra',rac+2.0
	sxaddpar,imhdr,'mountdec',decc+2.0
	sxaddpar,imhdr,'offstra',-2.0
	sxaddpar,imhdr,'offstdec',-2.0
  endif
  
  tychocal_limits,imhdr,ralow,rahigh,declow,dechigh,$
		boxedge=10.0,rac=rac,decc=decc

;Check for reasonable return
  if (ralow eq rahigh) then begin
	print,"Failed to find valid limits for catalog search, aborting"
	return
  endif

  if (ralow lt rahigh) then begin
	c=where(tcat.ra gt ralow and tcat.ra lt rahigh and $
		tcat.dec gt declow and tcat.dec lt dechigh)
	help,c
  endif

  if (ralow gt rahigh) then begin
	c=where(tcat.ra gt ralow or tcat.ra lt rahigh and $
		tcat.dec gt declow and tcat.dec lt dechigh)
	help,c
  endif

;Extract the part we want...
 tn=tcat(c)

;Now sort them by magnitude
 sort=sort(tn.vmag)
 tn=tn(sort)

;Now sort our list the same way
  sort=sort(sobj.mag_aper)
  sobj=sobj(sort)
  nobj=N_elements(sobj)
  ncat=N_elements(tn)

;Now project the catalog ra and dec to (x,y) coordinates
  convert2xy,tn.ra,tn.dec,xc,yc,rac=rac,decc=decc

;Now create a local copy of the image positions for use here
  xim=sobj.x_image-1.0
  yim=sobj.y_image-1.0

;First match the images to one another
;As a first step, extract the central 30% of each list. This requires that
;the positions should be correct to about 10% of the width!
  sxmin=min(xim)
  sxmax=max(xim)
  symin=min(yim)
  symax=max(yim)
  sxrange=sxmax-sxmin
  syrange=symax-symin
  ssub=where(xim gt (sxmin+(1-subr)*0.5*sxrange) and $
	xim lt (sxmin+(1+subr)*0.5*sxrange) and $
	yim gt (symin+(1-subr)*0.5*syrange) and $
	yim lt (symin+(1+subr)*0.5*syrange))
  cxmin=min(xc)
  cxmax=max(xc)
  cymin=min(yc)
  cymax=max(yc)
  cxrange=cxmax-cxmin
  cyrange=cymax-cymin
  csub=where(xc gt (cxmin+(1-subr)*0.5*cxrange) and $
	xc lt (cxmin+(1+subr)*0.5*cxrange) and $
	yc gt (cymin+(1-subr)*0.5*cyrange) and $
	yc lt (cymin+(1+subr)*0.5*cyrange))

  if (n_elements(csub) lt 30) then begin
	print,'Too few Tycho objects found in subregion:',n_elements(csub)
	fail=1
	return
  endif
  if (n_elements(ssub) lt 30) then begin
	print,'Too few ROTSE objects found in subregion:',n_elements(ssub)
	fail=1
	return
  endif

  print,''
  print,'Limits for subr cuts...'
  print,(sxmin+(1-subr)*0.5*sxrange),(sxmin+(1+subr)*0.5*sxrange)
  print,(cxmin+(1-subr)*0.5*cxrange),(cxmin+(1+subr)*0.5*cxrange)
;Now do it!
  triangle_match,xim(ssub(rskip:rskip+keep-1)),$
	yim(ssub(rskip:rskip+keep-1)),$
	xc(csub(skip:skip+keep-1)),yc(csub(skip:skip+keep-1)),$
	0.005,1,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky

;If it fails to find a match then ...
  if n_elements(kx) le 1 then begin
    print,'returning from tychocal without finding match'
    fail=1
    return
  endif

  magdiff=median(tn(m2).vmag-sobj(m1).mag_aper)
  mnew=sobj(m1).mag_aper+magdiff
  print,"Magdiff=",magdiff
  print,tn(m2).vmag-mnew
  n=where(abs(tn(m2).vmag-mnew) gt 1,nfound) 
  info=size(n)
  print,"Removing from the fit:",info(1)
  if (nfound gt 0) then begin
	  remove,n,m1,m2
  endif

;Assuming this works, now transform image 2 to image 1 coordinates
;  print,""
;  print,"Transforming list two to list one coordinates"
  kx(1,1)=0.0
  ky(1,1)=0.0
  kmap,xc,yc,xx,yy,kx,ky

;Now close match the two, only deal with the brightest fifth of the objects
;  print, ""
;  print, "Close matching the two lists"
  nuse=nobj*nusefrac-1
  if (nuse eq 0) then begin
	nuse=nobj
  endif
  if (nuse gt ncat-1) then begin
	nuse=ncat-1
  endif
  close_match,xim(0:nuse),yim(0:nuse),$
	xx(0:nuse),yy(0:nuse),m1,m2,0.5,1,miss1
  if (plots eq 1.0) then begin
     rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky
  endif

  if (n_elements(m1) lt 5) then begin
     print,'returning from tychocal without finding match'
     fail=1
     return
  endif 

  magdiff=median(tcat(m2).vmag-sobj(m1).mag_aper)
  mnew=sobj(m1).mag_aper+magdiff
  n=where(abs(tcat(m2).vmag-mnew) gt 1,nfound) 
  info=size(n)
  print,"Removing from the fit:",info(1)
  if (nfound gt 0) then begin
	  remove,n,m1,m2
  endif
;Now iterate "iter" times on the solution

  for i=1,iter do begin 
	if (n_elements(m1) lt 17) then begin
	    print,'Not enough elements for polywarp:',n_elements(m1)
	    fail=1
	    return
	endif
	print, "Looping over solution:",i,"   of:",iter
	polywarp,xim(m1),yim(m1),xc(m2),yc(m2),3,kx,ky
	kmap,xc,yc,xx,yy,kx,ky
	if (i lt iter) then begin
	  print, "Close matching to 0.5 ebox"
  	  close_match,xim(0:nuse),yim(0:nuse),$
		xx(0:nuse),yy(0:nuse),m1,m2,0.5*ebox,1,miss1
  	  ;bmv=tn(m2).bmag-tn(m2).vmag
  	  ;rmag=tn(m2).vmag-(-0.5+bmv/1.875)
  	  ;magdiff=median(rmag-sobj(m1).mag_aper)
	  ;mnew=sobj(m1).mag_aper+magdiff
	  ;dist=sqrt((xim(m1)-xx(m2))^2 + (yim(m1)-yy(m2))^2)
	  ;mom=moment(dist)
	  ;maxdist=mom(0)+sqrt(mom(1))
	  ;maxmag=9.5+magdiff
	  ;minmag=14.0+magdiff
	  ;n=where(dist gt maxdist or rmag lt maxmag or rmag gt minmag,nfound) 
  	  ;info=size(n)
  	  ;print,"Removing from the fit:",info(1)
	  ;if (nfound gt 0) then begin
	;	  remove,n,m1,m2
	 ; endif

	endif else begin
	  print, 'Final close match to ',+string(ebox)+' pixels'
  	  close_match,xim,yim,xx,yy,m1,m2,ebox,1,miss1
	endelse 
	if (plots eq 1.0) then begin
  	   rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky
	endif
 end

 cobj=create_struct("ra",0.0,"dec",0.0,$
	"x",0.0,"y",0.0,"m",0.0,"merr",0.0,"flags",byte(0),'msys200',byte(0),'rflags',byte(0))

 cal=replicate(cobj,nobj)

;Now start stuffing the structure, first things which don't change
 cal.x=xim
 cal.y=yim
 cal.flags=sobj.flags
;Now convert x,y to ra,dec and stuff these
 kmap_inv,xim,yim,xp,yp,kx,ky
 convert2rd,xp,yp,r,d,rac=rac,decc=decc
 cal.ra=r
 cal.dec=d

;Now perform the photometric calibration (this is the tricky bit...)
;What's used here now is a primitive first version. Soon this will have 
;to call a calibration routine which will do much more sophisticated
;field by field fitting....

magzp=sxpar(sobjhdr,'SEXMGZPT')

;First, eliminate the objects which have no magnitude measured
  goodobj=where(sobj(m1).mag_aper gt 0 and sobj(m1).mag_aper lt magzp $
	and tn(m2).vmag gt 9)
  m1=m1(goodobj)  
  m2=m2(goodobj)

  bmv=tn(m2).bmag-tn(m2).vmag
  rmag=tn(m2).vmag-(-0.5+bmv/1.875)
  magdiff=median(rmag-sobj(m1).mag_aper)
  mnew=sobj.mag_aper+magdiff
  cal.m=mnew
  cal.merr=sobj.magerr_aper

;Next, we need to calculate which objects have hot pixels on them...
;This is currently hard-wired to a 2.5 pixel aperture.


objpixrms=replicate(0.0,n_elements(cal))
the_rflags=cal.rflags
print,'Matching objects to bad pixels...'
compare_badpix,badpix,cal.x,cal.y,2.5,the_rflags,objpixrms,/check_sat
cal.rflags=the_rflags

do_msys=where((sobj.mag_aper lt magzp) and (objpixrms gt 0),mcount) 

numobj=n_elements(cal)
counts_above_background=fltarr(numobj,/nozero)
msys=replicate(0.01,numobj)			; there is a default 1% systematic error
msys200=replicate(0,numobj)
exptime=sxpar(imhdr,'EXPTIME')
pixrms_scale=sqrt(float(bpexptime)/float(exptime))

print,'Scaling bad pixel rms by :',pixrms_scale

if (mcount gt 0) then begin
   counts_above_background(do_msys)=10.0^((magzp - sobj(do_msys).mag_aper)/2.5)
   msys(do_msys)=sqrt(msys(do_msys)^2+((1.086*(objpixrms(do_msys)/counts_above_background(do_msys)))/pixrms_scale)^2)
endif

; Estimate a systematic error for saturated objects.
  
n=n_elements(cal.m)
m_lim=cal(n*0.9).m
sat_mag=m_lim - 5
sat_obj=where((cal.m lt sat_mag) and (cal.flags and 4) eq 4,scount)
if (scount gt 0) then begin
   msys(sat_obj)=sqrt(msys(sat_obj)^2+(0.2*(sat_mag - cal(sat_obj).m))^2)
endif

msys200=round(200*msys)
overflow=where(msys200 gt 254,ocount)
if (ocount gt 0) then msys200(overflow)=255
cal.msys200=byte(msys200)

; Finally check for bad pixels on poorly measured objects
very_bad=where((sobj.mag_aper ge magzp) and (objpixrms gt 0),vbcount)
if (vbcount gt 0) then cal(very_bad).msys200=255

;Now we're done. 
;Return stats structure 
  stats=create_struct("nmatch",0,"offset_x",0.0,"offset_y",0.0,$
		"pos_sigma",0.0,"ra_low",0.0,"ra_high",0.0,$
		"dec_low",0.0,"dec_high",0.0,"zp_offset",0.0,$
		"zp_sigma",0.0,"m_lim",0.0,"sat_mag",0.0,"rac",rac,"decc",decc,$
		"kx",kx,"ky",ky,"nobj_badpix",0)
  stats.nmatch=n_elements(m1)
  stats.offset_x=kx(0,0)
  stats.offset_y=ky(0,0)
  poserr=moment(sqrt((xim(m1)-xx(m2))^2+(yim(m1)-yy(m2))^2))
  stats.pos_sigma=poserr(0)
  stats.ra_low=min(cal.ra)
  stats.ra_high=max(cal.ra)
  stats.dec_low=min(cal.dec)
  stats.dec_high=max(cal.dec)
  stats.zp_offset=magdiff
  nobj_badpix=where(objpixrms gt 0,bpcount)
  stats.nobj_badpix=bpcount
  
  moff=rmag-sobj(m1).mag_aper
  mom=moment(moff)
  _in=where(abs(moff-magdiff) lt 3.0*mom(1))
  if ((size(_in))(0) ne 0) then begin
     stats.zp_sigma=sqrt((moment(moff(_in)))(1))
  endif else begin
     stats.zp_sigma=99.0
  endelse
  print,'Calculated the new stats.zp_sigma',stats.zp_sigma

  stats.m_lim=m_lim
  stats.sat_mag=sat_mag

  return
  end









