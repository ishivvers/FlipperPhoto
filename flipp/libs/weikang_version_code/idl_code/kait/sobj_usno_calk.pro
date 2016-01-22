pro sobj_usno_calk,shdr,sobj,cat,cal,stats,fail=fail,readusno=readusno,pixscale=pixscale,searchrad=searchrad

;+
; NAME:	ROTSE_III_USNO_CAL
;
; CALLING SEQUENCE:	sobj_usno_cal, shdr, sobj, cat, cal, stats
;
; INPUTS:
;		shdr: header from image file (must contain ra, dec)
;		cat: usno catalog for nominal region 
;		sobj: object structure from image derived from Sextractor
;
; OUTPUTS:	cal: calibrated sobj structure
;		stats: statistics of the calibration
;
; INPUT KEYWORDS:
;		fail: Returns failure/success flag
;			
; PROCEDURE:	Matches and transforms two object structures
;		Structures must contain the following elements:
;		CAT: ra, dec, rmag, bmag
;		SOBJ: x_image, y_image, mag_aper
;
;******************************************************************************
;-

 if N_params() eq 0 then begin
	print,'Syntax: sobj_usno_calk,shdr,sobj,cat,cal,stats,fail=fail,readusno=readusno,pixscale=pixscale,searchrad=searchrad'
	return
 endif

 set_plot,'x'

 fail=0
 ebox=3.0

 if n_elements(searchrad) eq 0 then searchrad=1.5

 if not keyword_set(pixscale) then begin
   if (sxpar(shdr,'PIXSCALE') ne 0) then begin
     pixscale=sxpar(shdr,'PIXSCALE')
   endif else begin
     pixscale=0.7965 ; this is for kait
   endelse
endif

 naxis1=sxpar(shdr,'NAXIS1')
 naxis2=sxpar(shdr,'NAXIS2')

 extast,shdr,astr
 ;print,shdr
 ;print,astr
 xc=naxis1/2.0
 yc=naxis2/2.0
 xy2ad,xc,yc,astr,rac,decc
 print,xc,yc,rac,decc

 if keyword_set(readusno) then begin
     radius=pixscale*naxis1/2.0/3600.0
     radius=radius*searchrad
     ;print,pixscale,naxis1,radius
     print,'Extracting usno catalog with ridius of ',radius,' degree'
     print,'around center of Ra Dec : ',rac,decc
     ;;this using 15 mag catalog, but not deep enough, change to use 17 mag catalog
     extract_usno_db,rac,decc,radius,cat,basename='usno18'
 endif

 ad2xy,cat.ra,cat.dec,astr,xx,yy
 
 ind=where(xx gt 0 and xx lt naxis1 and yy gt 0 and yy lt naxis2, nf)
 if (nf lt 2) then begin
     print,'No catalog objects.'
     fail = 1
     return
 endif
 cat=cat[ind]
 ad2xy,cat.ra,cat.dec,astr,xx,yy
 usecat=indgen(nf)

;Now create a local copy of the image positions for use here
  xima=double(sobj.x_image-1.0)
  yima=double(sobj.y_image-1.0)

  nobj=N_elements(sobj)
  ncat=N_elements(cat)

  ;; Now, resort (to violence)
  magsort=sort(sobj.mag_aper[0])
  sobjm=sobj(magsort)
  xim=sobjm.x_image-1.0
  yim=sobjm.y_image-1.0

  ;; don't want to use the saturated guys...
  usesobj=where((sobjm.flags and 4) ne 4,nnotsat)
  if (nnotsat eq 0) then begin
      print,'all the stars are saturated.  Using all stars'
      usesobj = indgen(n_elements(sobjm))
  endif

  close_match,xim[usesobj],yim[usesobj],xx[usecat],yy[usecat],m1,m2,ebox,1,miss1
  
  if (n_elements(m1) lt 3) then begin
      print,'After saturation cuts, too few stars matched'
     fail = 1
      return
  endif

  ;; and also cut on magnitude
  rmag=cat[usecat[m2]].rmag
  magdiff=median(rmag-sobjm[usesobj[m1]].mag_aper[0])
  
  maxmag = max(cat.rmag) - magdiff + 1.0
  h=where(sobjm[usesobj].mag_aper[0] lt maxmag,ngd)
print,'Now check how much a discarded, total : ', n_elements(usesobj), n_elements(h)
  if (ngd eq 0) then begin
      print,'all the stars are apparently too dim????'
  endif else begin
      usesobj=usesobj[h]
      close_match,xim[usesobj],yim[usesobj],xx[usecat],yy[usecat],m1,m2,ebox,1,miss1
  endelse

  if (m1(0) eq -1) then begin
     print,'No matches found after transformation!'
     match_okay=0
     fail = 1
     return
  endif

  rmag=cat[usecat[m2]].rmag
  magdiff=median(rmag-sobjm[usesobj[m1]].mag_aper[0])
  mnew=sobjm[usesobj[m1]].mag_aper[0]+magdiff
  magdiff=rmag-mnew
  
  dist=sqrt((xim[usesobj[m1]]-xx[usecat[m2]])^2. + $
            (yim[usesobj[m1]]-yy[usecat[m2]])^2.)
  sdev = stddev(dist)
  print,'Distance Measure: ',sdev
  maxdist=sdev*9.
  
  maxmagdist=3.00
  
  n=where(dist gt maxdist or abs(magdiff) gt maxmagdist,nfound)
  info=size(n)
  print,"Removing from the fit:",info[1]
  
  if (nfound gt 0) then begin
      if (nfound ge n_elements(m1)-2) or (nfound gt n_elements(m2)-2) then begin
          print,'Removing ALL from match...no good matches'
          match_okay=0
          fail=1
          return
      endif else begin
          remove,n,m1,m2
      endelse
  endif

  cobj=create_struct("ra",0d,"dec",0d,$
                     "x",0.0,"y",0.0,"m",0.0,"merr",0.0,"fwhm", 0.0, "flags",0B,"rflags",0B)

  cal=replicate(cobj,nobj)

;Now start stuffing the structure, first things which don't change
  cal.x=xim
  cal.y=yim
  cal.flags=sobjm.flags
  cal.fwhm = sobjm.fwhm_image
;Now convert x,y to ra,dec and stuff these
  xy2rd,xim,yim,astr,r,d
  cal.ra=r
  cal.dec=d
  cal[m1].rflags = set_flags3('USNOCAT', old=cal[m1].rflags, type='RFLAGS')


 ;Now apply a photometric 'calibration'
  m1bak=m1
  m2bak=m2

  goodobj=where(sobjm[m1].mag_aper[0] gt 0 and sobjm[m1].mag_aper[0] lt 25 $
                and cat[m2].rmag gt 12 and cat[m2].bmag gt 11 and $
                ((sobjm[m1].flags and 4) ne 4), ngood)

  if (ngood ge 3) then begin   ;; updated for coming median
      m1=m1[goodobj]
      m2=m2[goodobj]
  endif else begin
      print,'Fewer than 3 good objects?!?'
      fail = 1
      return
  endelse
 
 ; old calculation...
 rmag_all=cat[m2].rmag
 magdiff = median(rmag_all - sobjm[m1].mag_aper[0])
 mnew = sobjm.mag_aper[0] + magdiff

 cal.merr = sobjm.magerr_aper[0]

 magdiff_matrix = magdiff

cal.m = sobjm.mag_aper[0] + magdiff_matrix

;Now we're done. 
;Return stats structure 
  stats=create_struct("nmatch",0,"offset_x",0.0,"offset_y",0.0,$
                      "pos_sigma",0.0,"ra_low",0.0,"ra_high",0.0,$
                      "dec_low",0.0,"dec_high",0.0,"zp_offset",magdiff_matrix,$
                      "zp_sigma",0.0,"m_lim",0.0,"fname",'', 'fwhm', 0.0, 'rac', rac, 'decc', decc )
  stats.nmatch=n_elements(m1)
  stats.offset_x=0.0
  stats.offset_y=0.0
  poserr=moment(sqrt((xim(m1)-xx(m2))^2+(yim(m1)-yy(m2))^2))
  stats.pos_sigma=poserr(0)
  stats.ra_low=min(cal.ra)
  stats.ra_high=max(cal.ra)
  stats.dec_low=min(cal.dec)
  stats.dec_high=max(cal.dec)


  ibit = where(sobjm.flags EQ 0,ict)
  if (ict gt 0) then begin
      gmag = min(sobjm[ibit].mag_aper[0])
      usmag = where(sobjm[ibit].mag_aper[0] GT gmag AND sobjm[ibit].mag_aper[0] LT gmag+8 and $
        sobjm[ibit].x_image gt naxis1*0.1 and sobjm[ibit].x_image lt naxis1*0.9 and $
        sobjm[ibit].y_image gt naxis1*0.1 and sobjm[ibit].y_image lt naxis1*0.9 and $
        sobjm[ibit].fwhm_image lt 10.0, count)
      if (count ge 2) then begin
          new_fwhm = median(sobjm[ibit[usmag]].fwhm_image)
      endif else if (count eq 1) then begin
          new_fwhm = sobjm[ibit[usmag]].fwhm_image
      endif else begin
          new_fwhm = median(sobjm.fwhm_image)
      endelse
  endif else begin
      new_fwhm = median(sobjm.fwhm_image)
  endelse

  stats.fwhm = new_fwhm

  moff = cat[m2].rmag - cal[m1].m
  mom=moment(moff)
  _in = where(abs(moff) lt 3.*mom[1],n_in)
  if (n_in gt 3) then begin
      stats.zp_sigma = sqrt((moment(moff[_in]))[1])
  endif else begin
      stats.zp_sigma = 100.0
  endelse

  h=where(cal.m lt 25 AND cal.m GT 5, n)
  stats.m_lim=cal(h((n*0.9))).m
  print,'Limiting magnitude: '+string(stats.m_lim,format='(f6.2)')

 return
 end
