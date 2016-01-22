pro rotse_iii_usno_cal,shdr,sobj,cat,cal,stats,keep=keep,fail=fail,plots=plots,readusno=readusno,skip=skip,iter=iter,x1=x1,y1=y1,x2=x2,y2=y2,order=order,subr=subr,rac=rac,decc=decc,fov=fov,nbin=nbin

;+
; NAME:	ROTSE_III_USNO_CAL
;
; CALLING SEQUENCE:	rotse_iii_usno_cal, shdr, sobj, cat, cal, stats
;
; INPUTS:
;		shdr: header from sobj file (must contain ra, dec)
;		cat: usno catalog for nominal region 
;		sobj: object structure from image derived from Sextractor
;
; OUTPUTS:	cal: calibrated sobj structure
;		stats: statistics of the calibration
;
; INPUT KEYWORDS:
;		skip: how many bright objects to skip over in initial match 
;		keep: how many objects from each list to try in initial match
;		fail: Returns failure/success flag
;		plots: Display diagnostic plots if set
;               subr: a single or array of subregions to try
;			
; PROCEDURE:	Matches and transforms two object structures
;		Structures must contain the following elements:
;		CAT: ra, dec, rmag, bmag
;		SOBJ: x_image, y_image, mag_aper
;
; REVISION HISTORY:  
;	Tim Mckay		UM		01/18/01
;		Began, based on ROTSE I tychocal_s routines
;       Eli Rykoff	UM 11/29/01: Fixed sorting problem, now the corners
;                                    should calibrate
;       Eli Rykoff      UM 05/01/02: Merged various mods.  Still needs
;       checking!
;       Eli Rykoff      UM 09/03/02: Changed to 5x5 binning and weighting
;       Eli Rykoff         03/02/04: Fixed gaussfit, median problems
;       S. Yost         UM 03/03/05: calculate FWHM here from sobj,
;       put in cal struct
;******************************************************************************
;-

 if N_params() eq 0 then begin
	print,'Syntax: rotse_iii_usno_cal,shdr,sobj,cat,cal,stats,keep=keep,fail=fail,plots=plots,readusno=readusno,skip=skip,subr=subr,rac=rac,decc=decc,fov=fov,nbin=nbin'
	return
 endif

 set_plot,'x'

 fail=0
 ;;ebox=3.0  ;old
 ebox=1.0

 if not keyword_set(keep) then keep=30
 if not keyword_set(plots) then plots=0.0
 if not keyword_set(iter) then iter=15   ;; this is now a maximum number of iterations
 if not keyword_set(skip) then skip=0
 if not keyword_set(fov) then fov=1.85
 if not keyword_set(nbin) then nbin=1

 if not keyword_set(subr) then subr=0.5

 if n_elements(order) eq 0 then order=3

 if n_elements(rac) eq 0 then begin
     if (sxpar(shdr,'PC001001') eq 1.0) then begin
         ;; not previously calibrated
         rac=sxpar(shdr,'MOUNTRA')
         decc=sxpar(shdr,'MOUNTDEC')
     endif else begin
         rac=sxpar(shdr,'CRVAL1')
         decc=sxpar(shdr,'CRVAL2')
     endelse
 endif

 naxis1=sxpar(shdr,'NAXIS1')
 naxis2=sxpar(shdr,'NAXIS2')


;Now sort them by magnitude
; magsort=sort(sobj.mag_aper[0])
; sobj=sobj(sort)
 areasort=reverse(sort(sobj.isoarea_image))
 sobj=sobj(areasort)


 if keyword_set(readusno) then begin
   ;;rotse_iii_usnoread,rac,decc,2.0,ucat
     extract_usno_db,rac,decc,2.0,ucat
 endif

 rotse_iii_usno_crop,rac,decc,ucat,cat,xcenter=0,ycenter=0,fov=fov

 ncat = n_elements(cat)
 if (ncat lt 2) then begin
     print,'No catalog objects.'
     fail = 1
     return
 endif

;Now create a local copy of the image positions for use here
  xima=double(sobj.x_image-1.0)
  yima=double(sobj.y_image-1.0)

  nobj=N_elements(sobj)
  ncat=N_elements(cat)

;Now project the catalog ra and dec to (x,y) coordinates
  astr_struct_new,1.85,astr

  ; not sure about this...
  ;; this next part was certainly wrong.
;;  if (fov ne 1.85) then begin
;;      pixscale = double(fov) / 501d  ;;??
;;      astr.cdelt = [pixscale, pixscale]
;;  endif

  astr.crval=[double(rac),double(decc)]
  rd2xy,cat.ra,cat.dec,astr,xc,yc

  match_okay = 0
;;  for subloop=0l,n_elements(subr)-1 do begin
  subloop=0
  while (not match_okay and subloop lt n_elements(subr)) do begin
      
      if (not match_okay) then begin
          print,'trying subregion: ',string(subr[subloop])
          this_match_okay = 1
          ;;do subregions
          sxmin = min(xima)
          sxmax = max(xima)
          symin = min(yima)
          symax = max(yima)
          sxrange = sxmax - sxmin
          syrange = symax - symin
          ssub=where(xima gt (sxmin+(1-subr[subloop])*0.5*sxrange) and $
                     xima lt (sxmin+(1+subr[subloop])*0.5*sxrange) and $
                     yima gt (symin+(1-subr[subloop])*0.5*syrange) and $
                     yima lt (symin+(1+subr[subloop])*0.5*syrange))
          

;;          cxmin=-1024.
;;          cxmax=1024.
;;          cymin=-1024.
;;          cymax=1024.
          cxmin = -1*naxis1/2
          cxmax = -1 * cxmin
          cymin = -1*naxis2/2
          cymax = -1 * cymin
          cxrange=cxmax-cxmin
          cyrange=cymax-cymin
          csub=where(xc gt (cxmin+(1-subr[subloop])*0.5*cxrange) and $
                     xc lt (cxmin+(1+subr[subloop])*0.5*cxrange) and $
                     yc gt (cymin+(1-subr[subloop])*0.5*cyrange) and $
                     yc lt (cymin+(1+subr[subloop])*0.5*cyrange))


          ;; check one

          if (n_elements(csub) lt 31) then begin
              print,'Too few catalog objects ('+string(n_elements(csub))+') in subregion size '+string(subr[subloop])
              this_match_okay = 0
          endif
          if (n_elements(ssub) lt 31) then begin
              print,'Too few ROTSE objects ('+string(n_elements(ssub))+') in subregion size '+string(subr[subloop])
              this_match_okay = 0
          endif
          
          if (this_match_okay) then begin
              srange = indgen(keep)+skip
              match_xim=xima[ssub[srange]]
              match_yim=yima[ssub[srange]]
              crange = indgen(keep)+skip
              match_xc =xc[csub[crange]]
              match_yc =yc[csub[crange]]
 
              xmin=min([match_xim,match_xc])
              xmax=max([match_xim,match_xc])
              ymin=min([match_yim,match_yc])
              ymax=max([match_yim,match_yc])

              triangle_match,match_xim, match_yim, match_xc, match_yc, $
                             0.002,1,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky

              ;; should that be 0.002?

              ;;If it fails to find a match then ...
              if n_elements(kx) le 1 then begin
                  print,'Failed to find a match at subregion ',string(subr[subloop])
                  this_match_okay = 0
              endif else begin
                  ;; we have a good match!
                  match_okay = 1
              endelse
          endif
      endif
;;  endfor
      subloop=subloop+1
      subloop_jump:
  endwhile

  if (not match_okay) then begin
      print,'Returning after failing completely.'
      fail=1
      return
  endif


  kx(1,1)=0.0
  ky(1,1)=0.0
  kmap,xc,yc,xx,yy,kx,ky
  
  ;; crop this to the real image, with margins

;;  usecat=where(xx gt -100 and xx lt 2150 and yy gt -100 and yy lt 2150,ngd)
  usecat=where(xx gt -100 and xx lt (naxis1+100) and yy gt -100 and yy lt (naxis2+100),ngd)
  if (ngd eq 0) then begin
      print,'odd.  no usno stars in range?'
      fail=1
      return
  endif

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
;;      fail=1
;;      return
      match_okay=0
      goto,subloop_jump
  endif

  ;; and also cut on magnitude
  rmag=cat[usecat[m2]].rmag
  magdiff=median(rmag-sobjm[usesobj[m1]].mag_aper[0])
  
  maxmag = max(cat.rmag) - magdiff + 0.5
  h=where(sobjm[usesobj].mag_aper[0] lt maxmag,ngd)
  if (ngd eq 0) then begin
      print,'all the stars are apparently too dim????'
  endif else begin
      usesobj=usesobj[h]
      close_match,xim[usesobj],yim[usesobj],xx[usecat],yy[usecat],m1,m2,ebox,1,miss1
  endelse

  if (m1(0) eq -1) then begin
     print,'No matches found after transformation!'
     match_okay=0
     goto,subloop_jump
  ;;   fail=1
  ;;   return
  endif

  if (plots eq 1.0) then begin
     nm=n_elements(m1)
     print,'Number of matches = '+ntostr(nm)
     rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky
  endif


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;  This is where we iterate to find a better solution
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  xrange=max(xim)-min(xim)
  medx=median(xim)
  yrange=max(yim)-min(yim)
  medy=median(yim)

  last_nmatch = -1
  i = 1
  while (i le iter) do begin
;;  for i=1,iter do begin 
    ;;  if (n_elements(m1) lt 17) then begin
      if (n_elements(m1) lt (order * order * 2)) then begin
          print,'Not enough elements for polywarp:',n_elements(m1)
          match_okay=0
          goto,subloop_jump
;;          fail=1
;;          return
      endif
      if (plots eq 1) then print, "Looping over solution:",i,"   of:",iter
      if (i lt iter) then begin
          if (order eq 3) then begin
              polywarp_rotse_iii,xim[usesobj[m1]],yim[usesobj[m1]],xc[usecat[m2]],yc[usecat[m2]],order,kx,ky 
          endif else begin
              polywarp,xim[usesobj[m1]],yim[usesobj[m1]],xc[usecat[m2]],yc[usecat[m2]],order,kx,ky 
          endelse
          kmap,xc,yc,xx,yy,kx,ky
          if (plots eq 1) then print, "Close matching to ebox"
          close_match,xim[usesobj],yim[usesobj],xx[usecat],yy[usecat],m1,m2,ebox,1,miss1

     
          rmag=cat[usecat[m2]].rmag
          magdiff=median(rmag-sobjm[usesobj[m1]].mag_aper[0])
          mnew=sobjm[usesobj[m1]].mag_aper[0]+magdiff
          magdiff=rmag-mnew
   
          dist=sqrt((xim[usesobj[m1]]-xx[usecat[m2]])^2. + $
                    (yim[usesobj[m1]]-yy[usecat[m2]])^2.)
          sdev = stddev(dist)
          print,'Distance Measure: ',sdev
          maxdist=sdev*3.
          
          plothist,magdiff,bin=0.1,xrange=[-3,3],xh,yh,/noplot
          test=check_gaussfit(xh,yh)
          if (test eq 0) then begin
              print,'We have a serious failure.  Giving up.'
              match_okay=0
              goto,subloop_jump
;;              fail = 1
;;              return
          endif

          r=gaussfit(xh,yh,a,nterms=3)
          mmon=moment(magdiff)
          maxmagdist=a[2]
          
          n=where(dist gt maxdist or abs(magdiff) gt maxmagdist,nfound)
          info=size(n)
          print,"Removing from the fit:",info[1]
          
          if (nfound gt 0) then begin
              if (nfound eq n_elements(m1)) or (nfound eq n_elements(m2)) then begin
                  print,'Removing ALL from match...no good matches'
;;                  fail = 1
;;                  return
                  match_okay=0
                  goto,subloop_jump
              endif else begin
                  remove,n,m1,m2
              endelse
          endif

          if (n_elements(m1) eq last_nmatch) then begin
              i = iter - 1
          endif else begin
              last_nmatch = n_elements(m1)
          endelse

      endif else begin
          if (order eq 3) then begin
              polywarp_rotse_iii,xim[usesobj[m1]],yim[usesobj[m1]],xc[usecat[m2]],yc[usecat[m2]],order,kx,ky
          endif else begin
              polywarp,xim[usesobj[m1]],yim[usesobj[m1]],xc[usecat[m2]],yc[usecat[m2]],order,kx,ky
          endelse
          kmap,xc,yc,xx,yy,kx,ky
          if (plots eq 1) then $
            print, 'Final close match to ',+string(ebox)+' pixels'
          close_match,xim,yim,xx[usecat],yy[usecat],m1,m2,ebox,1,miss1   ;; perhaps change
          m2=usecat[m2]
          dist=sqrt((xim[m1]-xx[m2])^2 + (yim[m1]-yy[m2])^2)
          sdev = stddev(dist)
          print,'Distance Measure: ',sdev

      endelse 
      if (plots eq 1.0) then begin
          rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky
      endif
      ;;endfor
      i = i + 1
  endwhile
  

  cobj=create_struct("ra",0d,"dec",0d,$
                     "x",0.0,"y",0.0,"m",0.0,"merr",0.0,"fwhm", 0.0, "flags",0B,"rflags",0B)

  cal=replicate(cobj,nobj)

;Now start stuffing the structure, first things which don't change
  cal.x=xim
  cal.y=yim
  cal.flags=sobjm.flags
  cal.fwhm = sobjm.fwhm_image
;Now convert x,y to ra,dec and stuff these
  kmap_inv,xim,yim,xp,yp,kx,ky
  xy2rd,xp,yp,astr,r,d
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

 ;;xbinsize=(max(cal[m2].x)+10.)/(nbin)
 ;;ybinsize=(max(cal[m2].y)+10.)/(nbin)
 xbinsize=2050./nbin
 ybinsize=2050./nbin

 magdiff_matrix = fltarr(nbin,nbin)
 for i=0l,nbin-1 do begin
     for j=0l,nbin-1 do begin
         sub=where(cal[m1].x gt i * xbinsize and cal[m1].x lt (i+1)*xbinsize and $
                   cal[m1].y gt j * ybinsize and cal[m1].y lt (j+1)*ybinsize,nsub)
         if (nsub gt 3) then begin
             m1sub = m1[sub]
             m2sub = m2[sub]
             
             rmag=cat[m2sub].rmag
             
      ;;       weights = 1./(sobj[m1sub].magerr_aper[0]^2.)
      ;;      wtot = total(weights)
             ;;       magdiff_matrix[i,j] = total((weights/wtot)*(rmag -
             ;;       sobj[m1sub].mag_aper[0]))
             magdiff_matrix[i,j] = median(rmag - sobjm[m1sub].mag_aper[0])

         endif else begin
             magdiff_matrix[i,j] = -99
         endelse
     endfor
 endfor

 ; and check for -99's
 h=where(magdiff_matrix eq -99,badcnt)
 if (badcnt gt 0) then begin
     k=where(magdiff_matrix gt -99,gdcnt)
     if (gdcnt gt nbin) then begin
         magdiff_matrix[h] = mean(magdiff_matrix[k])
     endif else begin
         print,'Very bad, using the whole image'
         rmag = cat[m2].rmag
         magdiff_matrix[*,*] = median(rmag - sobjm[m1].mag_aper[0])
     endelse
 endif


 for i=0l,nbin-1 do begin
     for j=0l,nbin-1 do begin
         sub=where(cal.x ge i*xbinsize and cal.x le (i+1)*xbinsize and $
                   cal.y ge j*ybinsize and cal.y le (j+1)*ybinsize, nsub)
         if (nsub gt 0) then begin
             cal[sub].m = sobjm[sub].mag_aper[0] + magdiff_matrix[i,j]
         endif
     endfor
 endfor

 cal.merr = sobjm.magerr_aper[0]

 print,magdiff_matrix


;Now we're done. 
;Return stats structure 
  stats=create_struct("nmatch",0,"offset_x",0.0,"offset_y",0.0,$
                      "pos_sigma",0.0,"ra_low",0.0,"ra_high",0.0,$
                      "dec_low",0.0,"dec_high",0.0,"zp_offset",magdiff_matrix,$
                      "zp_sigma",0.0,"m_lim",0.0,"fname",'', 'fwhm', 0.0)
  stats.nmatch=n_elements(m1)
  stats.offset_x=kx(0,0)
  stats.offset_y=ky(0,0)
  poserr=moment(sqrt((xim(m1)-xx(m2))^2+(yim(m1)-yy(m2))^2))
  stats.pos_sigma=poserr(0)
  stats.ra_low=min(cal.ra)
  stats.ra_high=max(cal.ra)
  stats.dec_low=min(cal.dec)
  stats.dec_high=max(cal.dec)


  ibit = where(sobjm.flags EQ 0,ict)
  if (ict gt 0) then begin
      gmag = min(sobjm[ibit].mag_aper[0])
      usmag = where(sobjm[ibit].mag_aper[0] GT gmag AND sobjm[ibit].mag_aper[0] LT gmag+3 and $
        sobjm[ibit].x_image gt 700 and sobjm[ibit].x_image lt 1300 and $
        sobjm[ibit].y_image gt 700 and sobjm[ibit].y_image lt 1300 and $
        sobjm[ibit].fwhm_image lt 10.0, count)
      if (count ge 2) then begin
          new_fwhm = median(sobjm[ibit[usmag]].fwhm_image)
      endif else if (count eq 1) then begin
          new_fwhm = sobjm[ibit[usmag]].fwhm_image
      endif else begin
          new_fwhm = 0.0
      endelse
  endif else begin
      new_fwhm = 0.0
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
