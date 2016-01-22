pro find_badpix,filelist,badpix,writestruct=writestruct,doplots=doplots,writeimage=writeimage,filename=filename
;+
; NAME:	FIND_BADPIX
;
; CALLING SEQUENCE:	find_badpix,basefilename,filelist,badpix
;
; INPUTS:	filelist: a list of raw dark files
;
; OUTPUTS:	badpix: a bad pixel structure generated from the darks
;	
;
; INPUT KEYWORDS:
;		writestruct: Output the badpixel structure in a filename of the
;			form 'date_pixSN_ap10.fit' where SN is the camera serial
;			number from the fits header.
;		writeimage: Output the badpixel structure _and_ flag image in the
;			same file.  Use this _instead_ of writestruct.
;		doplots: plot the cuts as it goes along.
;		filename: Specify a filename to be output (this is necessary for
;			old headers that do not have CAMSN, etc.)
;			
; PROCEDURE:	Calculates the individual pixel rms values, determines a badpixel
;		cutoff, and classifies pixels as:
;			High pixel: Type 1
;			Unstable pixel: Type 2
;		        "strange" pixel: type 4
;		These definitions are made with the set_flags procedure.
;
; REVISION HISTORY:  
;	Eli Rykoff		UM	5/24/00
;					Created
;	Eli Rykoff		UM	6/4/00
;					allowed command-line specified filenames
;	Eli Rykoff		UM	7/25/00
;					Now calculates the gain to put in the header
;
;******************************************************************************
;-


if n_params() eq 0 then begin
   print,'syntax-find_badpix,filelist,badpix,/writestruct,/writeimage,/doplots,filename=filename'
   return 
endif

   print,'Counting dark files...'
   openr,1,filelist
   n=0
   name=''
   while not eof(1) do begin
     readf,1,name,format='(a60)'
     n=n+1
   endwhile
   ntot=n
   close,1
  

  print,'Checking and reading dark files...'
  openr,1,filelist
  n=0
  name=''
  name_array=replicate('',ntot)
  while not eof(1) do begin
    readf,1,name,format='(a60)'
    info=str_sep(name," ")
    name=info(0)
    name_array(n)=name
    nameparts=str_sep(name,"_")
    if(n eq 0) then begin
         nrows=2035
         ncols=2069
         imarray=intarr(ntot,nrows,ncols)
    endif
         imarray(n,*,*)=(readfits(name))(13:2047,2:2070)
    n=n+1
  endwhile
  close,1

; Figure out name of Median Dark...
nameparts=str_sep(name,'_')
basefilename=nameparts(0)+'_'+nameparts(1)+'_'+strmid(nameparts(2),0,2)
 
thefilename=basefilename+'.fit'
print,'Loading Median Dark File: ',thefilename
mediandark=readfits(thefilename,hdr)
if (!err ne 0) then begin
   print,'Cannot find the median dark!  Failing miserably...'
   return
endif
;this needs to be cropped.
mediandarkcrop=mediandark(13:2047,2:2070)        ;this is the post-1998 cropping.  This will change for rotse2,3!


; find the rms of each pixel.

print,'Calculating individual pixel rms values...'
pix_sigma=replicate(-1.0,nrows,ncols)
for i=0,nrows-1 do begin
   for j=0,ncols-1 do begin
      pix_sigma(i,j)=stddev(imarray(*,i,j))
   endfor
   if ((i/20.) mod 10) eq 0 then begin
        print,i/20,'% done...'
   endif
endfor


; Now, to prevent cosmic rays from hurting us, perform a clipped calculation
; for each pixel that initially 1 sigma above the mean.

print,'Calculating clipped pixel rms values...'
approx_pix_sigma_cut=mean(pix_sigma)+stddev(pix_sigma)
pix_sig_over=where(pix_sigma ge approx_pix_sigma_cut)
print,'Calculating clipped sigma for ',n_elements(pix_sig_over),' pixels, with rms above ',approx_pix_sigma_cut
the_x=pix_sig_over mod nrows
the_y=(pix_sig_over - the_x)/nrows
pix_sigma_noclip=pix_sigma
pix_max_excursion=fix(pix_sigma)*0
for i=long(0),n_elements(pix_sig_over)-1 do begin
   the_values=imarray(*,the_x(i),the_y(i)) - mediandarkcrop(the_x(i),the_y(i))
   sig_cut=3*pix_sigma(the_x(i),the_y(i))
   too_far=where((the_values lt -1*sig_cut) or (the_values gt sig_cut))
   if (too_far(0) ne -1) then begin
      worst_value=max(abs(the_values(too_far)))
      pix_max_excursion(the_x(i),the_y(i))=worst_value
      tempsig=stddev(the_values(where(abs(the_values) ne worst_value)))
      pix_sigma(the_x(i),the_y(i))=tempsig
   endif
   ; otherwise, there are no values > 3 sigma, and no need to recalculate!
endfor


; Fit a line on the log slope...this is fit with the clipped rms

plothist,pix_sigma,xout,yout,/noplot
xout=long(xout(1:n_elements(xout)-1))		; Crop off the strange peak at 0
yout=long(yout(1:n_elements(yout)-1))
sigma_mode=xout(where(yout eq max(yout)))
sigma_rms=stddev(pix_sigma)
sigma_mode=long(sigma_mode(0))
sigma_rms=long(sigma_rms(0))

xfit=where((xout gt sigma_mode) and xout le (sigma_mode+sigma_rms))
rmsline=linfit(xout(xfit),alog10(yout(xfit)))

; Now we can generate the list of bad pixels. This is generated from the unclipped rms

pix_sigma_cut=(alog10(1)-rmsline(0))/rmsline(1)
bad_pix_list=where((pix_sigma_noclip ge pix_sigma_cut) or (mediandarkcrop gt 16000))	

; plot the distribution and fit

if keyword_set(doplots) then begin
   plothist,pix_sigma,/ylog,xrange=[0,50],yrange=[1,max(yout)],xtitle='Clipped Pixel RMS'
   x1=xout(xfit(0))
   y1=(10^rmsline(0))*(10^(rmsline(1)*x1))
   x2=pix_sigma_cut
   y2=(10^rmsline(0))*(10^(rmsline(1)*x2))
   plots,x1,y1
   plots,x2,y2,/continue
   print,'Waiting for keypress...'
   r=get_kbrd(10)
endif


; The following fits a line to the high pixel distribution, which can be plotted.
; Again, this is done with the clipped rms values.

mdcmean=mean(mediandarkcrop)
mdcsigma=stddev(mediandarkcrop)
fitlow=mdcmean+5*mdcsigma
fithigh=mdcmean+30*mdcsigma
pixsigfitcut=mean(pix_sigma)+10*stddev(pix_sigma)

fitcut=where((pix_sigma lt pixsigfitcut) and (mediandarkcrop gt fitlow) and (mediandarkcrop lt fithigh))
theline=linfit(mediandarkcrop(fitcut),pix_sigma(fitcut))


; Print some statistics...

print,'For the Median Dark:'
print,'Mean: ',mdcmean,'  stddev:',mdcsigma
print,''
print,'Pixel rms statistics:'
print,'Mean rms: ',mean(pix_sigma),'  stddev: ',stddev(pix_sigma)
print,'Bad pixel sigma cut: ',pix_sigma_cut
print,''
print,'Number of bad pixels: ',n_elements(bad_pix_list)

; Now, we can plot the pix rms vs. median value, if asked to:

if keyword_set(doplots) then begin
   ind=long(randomu(seed,1000000)*(long(nrows)*long(ncols)))
   plot,mediandarkcrop(ind),pix_sigma(ind),psym=3,yrange=[0,500],xrange=[0,10000],xtitle='Pixel Median',ytitle='Pixel RMS'
   plots,0,theline(0)
   plots,10000,theline(1)*10000.+theline(0),/continue
   plots,0,pix_sigma_cut
   plots,10000,pix_sigma_cut,/continue
   print,'Waiting for keypress...'
   r=get_kbrd(10)
endif

; The following stuff is all for clasification

; substract linear component to get high pixel distribution width
; To avoid too much skewing from the unstable outliers

pix_sig_sub=pix_sigma - (theline(1)*mediandarkcrop+theline(0))

highpix_sdev_1=stddev(pix_sig_sub(fitcut))
clipfitcut=where((pix_sig_sub lt 5*highpix_sdev_1) and (mediandarkcrop gt fitlow) and (mediandarkcrop lt fithigh))
highpix_sdev=stddev(pix_sig_sub(clipfitcut))
highpix_min=(pix_sigma_cut-theline(0))/theline(1)

if keyword_set(doplots) then begin
  plot,mediandarkcrop(bad_pix_list),pix_sigma(bad_pix_list),yrange=[0,500],xrange=[0,10000],psym=3
  plot,mediandarkcrop(bad_pix_list),pix_sig_sub,yrange=[-200,200],xrange=[0,10000],psym=3

  plot,mediandarkcrop(bad_pix_list),pix_sigma(bad_pix_list),yrange=[0,500],xrange=[0,10000],psym=3,xtitle='Pixel Median',ytitle='Pixel RMS'
  plots,highpix_min,theline(1)*highpix_min+theline(0)+3*highpix_sdev
  plots,10000,theline(1)*10000.+theline(0)+3*highpix_sdev,/continue
  plots,highpix_min,pix_sigma_cut
  plots,highpix_min,500,/continue
  plots,0,pix_sigma_cut
  plots,10000,pix_sigma_cut,/continue
  print,'Waiting for keypress...'
  r=get_kbrd(10)
endif

; Initialize the badpixel structure and stuff it with the easy junk.

xystruct=create_struct("x",fix(0),"y",fix(0),"type",byte(0),"median",fix(0),"rms",fix(0))
badpix=replicate(xystruct,n_elements(bad_pix_list))

badpix.x=bad_pix_list mod nrows
badpix.y=(bad_pix_list - badpix.x)/nrows
badpix.median=mediandarkcrop(bad_pix_list)

underflow=where(pix_sigma(bad_pix_list) lt 32767)
overflow=where(pix_sigma(bad_pix_list) ge 32767)
badpix(underflow).rms=round((pix_sigma(bad_pix_list))(underflow))
if (overflow(0) ne -1) then begin
  badpix(overflow).rms=32767
endif

; Set the types...
; Any pixel that has a median above highpix_min is a high pixel, type = 'HOTPIX'

the_highpix=where(badpix.median ge highpix_min,hcount)
if (hcount gt 0) then begin
  tmp=make_array(n_elements(the_highpix),/byte,value=set_flags('HOTPIX',type='RFLAGS'))
  badpix(the_highpix).type=tmp
endif

; Any bad pixel that has a median less than highpix_min is an unstable pixel, type = 'NOISYPIX'

the_unstabpix=where((badpix.median lt highpix_min) and (pix_sigma(bad_pix_list) ge pix_sigma_cut),ucount)
if (ucount gt 0) then begin
  tmp=make_array(n_elements(the_unstabpix),/byte,value=set_flags('NOISYPIX',type='RFLAGS'))
  badpix(the_unstabpix).type=tmp
endif

; Any high bad pixel that is also above the line is an unstable pixel, type & 'NOISYPIX'

the_high_unstabpix=where((badpix.median ge highpix_min) and (badpix.rms ge (theline(0)+3*highpix_sdev+theline(1)*badpix.median)),hucount)
if (hucount gt 0) then begin
  tmp=make_array(n_elements(the_high_unstabpix),/byte,value=set_flags('NOISYPIX',type='RFLAGS'))
  badpix(the_high_unstabpix).type=tmp or badpix(the_high_unstabpix).type
endif

; Any pixel that is unstable _before_ the clipped rms calculation has type = 'STRANGEPIX'
; Also, replace the badpix.rms by the maximum excursion from the median

the_strangepix=where((pix_sigma_noclip(bad_pix_list) gt pix_sigma_cut) and (pix_sigma(bad_pix_list) lt pix_sigma_cut) and (badpix.median lt 16000),scount)
if (scount gt 0) then begin
  tmp=make_array(n_elements(the_strangepix),/byte,value=set_flags('STRANGEPIX',type='RFLAGS'))
  badpix(the_strangepix).type=tmp
  badpix(the_strangepix).rms = pix_max_excursion(badpix(the_strangepix).x,badpix(the_strangepix).y)
endif

;Finally, we want to calculate the gain:

bdarray=intarr(2,nrows,ncols)
n=0
; Take last two bias darks
for i=ntot-2,ntot-1 do begin
  nameparts=str_sep(name_array(i),'_')
  biasdarkfname=nameparts(0)+'_drk0000'+'_'+nameparts(2)
  whichfile=findfile(biasdarkfname,count=fcount)
  if (fcount gt 0) then begin
    bdarray(n,*,*)=(readfits(biasdarkfname))(13:2047,2:2070)
    n=n+1
  endif else begin
    print,"Bias dark ",biasdarkfname," is not here.  Gain will not be calculated."
  endelse
endfor
  

if (n eq 2) then begin
  print,"Calculating gain..."
  calc_gain,badpix,imarray(ntot-2,*,*),imarray(ntot-1,*,*), $
      bdarray(0,*,*),bdarray(1,*,*),gain
  print,"Gain = ",gain
endif else begin
  gain = -1
endelse


if (keyword_set(writestruct) or keyword_set(writeimage)) then begin
   if (not keyword_set(filename)) then begin
     ;in here a filename must be generated...and a location to put it (current directory)
      basenameparts=str_sep(basefilename,'_')
      darkhdr=headfits(basefilename+'.fit')
      sxaddpar,darkhdr,'NUMDARK',ntot
      camsn=sxpar(darkhdr,'CAMSN')
      info=strtrim(string(camsn),1)
      camsn=info(0)
      if (camsn eq 'AIXXXX') or (camsn eq '0') then begin	
         bfnsplit=str_sep(basefilename,'_')
         camsn=bfnsplit(2)
      endif
      camtype=strtrim(string(sxpar(darkhdr,'CAMTYPE')),1)
      if (camtype eq 'Apogee-Instruments AP-10') or (camtype eq 'Apogee AP-10') or (camtype eq '0') then cam_t='ap10'
        ; add a line here for the rotseiii camera type
      thefilename=basenameparts(0)+'_'+'pix'+camsn+'_'+cam_t+'.fit'
   endif else begin
      thefilename=filename
   endelse
   print,'Writing File: ',thefilename
   ; add the gain to the header:
   sxaddpar,darkhdr,'GAIN',gain,' Estimated Gain'
endif

if keyword_set(writestruct) then begin
   writefits,thefilename,indgen(5,5),darkhdr
   mwrfits,badpix,thefilename			; the structure goes in ext. 1
endif
    

if keyword_set(writeimage) then begin
    flagimage=replicate(byte(0),nrows,ncols)
    flagimage(badpix.x,badpix.y)=byte(badpix.type)

    writefits,thefilename,flagimage,darkhdr	; the flag image is in ext. 0
    mwrfits,badpix,thefilename			; the structure is in ext. 1
endif


return

end











