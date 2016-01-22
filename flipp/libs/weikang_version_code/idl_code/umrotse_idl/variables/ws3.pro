pro ws3,match,varistruct,Icut,prime_struct,all,magbin,chg1,chg2,good_arr=good_arr,$
merror=merror,sim=sim,noincl_ind=noincl_ind,$
ival_iter=ival_iter,in_cut=in_cut,$
sdv_cut=sdv_cut,rmobs=rmobs,iter=iter,cuts=cuts,magbin_cut=magbin_cut,$
isdev_iter=isdev_iter,get_conf=get_conf

;+
; NAME: WS3
;
; PURPOSE: This is the welch/stetson technique for finding variable stars as
;described in their paper 'Robust Variable Star Detection Techniques
;Suitable For Automated Searches: New Results for NGC 1866' found in the
;may 1993 issue of the Astronomical Journal (V.105,n.5).
;
; CALLING SEQUENCE: WS3,match,varistruct,Icut,good_arr=good_arr,
;merror=merror,sim=sim,noincl_ind=noincl_ind,ival_iter=ival_iter,
;in_cut=in_cut,sdv_cut=sdv_cut,rmobs=rmobs,iter=iter,cuts=cuts,
;magbin_cut=magbin_cut,isdev_iter=isdev_iter,/get_conf
;
; INPUTS: match- the structure to test for variables.
;         Icut- A given sigma cut, the number of sigmas above the average I value
;               an object's I-value must be to be considered variable.
;
; OPTIONAL INPUTS:
;  good_arr- Set this to the output of WS3_GOOD.PRO. It will be called 
;            automatically in program if this is not set. 
;  merror- Set this to a constant error to be used for each object.
;  /sim- Set this if the match structure contains only .m and .jd (simulation)
;  noincl_ind- Set this to an array of indicies to be EXCLUDED from the sdev
;              calculations used to find the I-value cut, but included in
;              set of objects searched for variables using the I-value cut 
;              established from the remaining indicies.
;  ival_iter- Set this to the number if iterations used to find the points to 
;             fit to an I-value curve. One iteration removes all objects
;             over one standard deviation from the mean. Default is 3.
;  in_cut- Set this to a whole number percentage (ie 50) and WS3 will require that 
;          any object be in at least this percentage of observations.
;  /sdv_cut- Set this to consider both positive and negative deviations from 
;           the mean I-value as possible variables. This in essence turns 
;           WS3 into a standard deviation cut.
;  rmobs- Set this to an array of observation indicies to be removed entirly.
;  iter- Set this to the number of times ws3 should remove all objects found to 
;        be blends or flares and recalculate I-cuts and possible variables. 
;        If this is set to a two element array, the second element is taken 
;        to be an ICUT to use for all iterations passed 0. The original icut 
;        input will be used for the first iteration. 
;   cuts- Set this to parameter structure output of CUTS.PRO to change cuts.
;   magbin_cut- Set this to an array of magbins (starting with 1) to exclude 
;               entirely from I-cuts and consideration for variability.
;   isdev_cut-Set this to the number if iterations used to find the sdev 
;             of the i-value about its mean (used to find I-value cut).
;             Default is 2.  
;   /get_conf- Set this to find the confidence value for all poss variables.       
; OUTPUTS: varistruct- The returned variable structure with the following tag names:
;        .VARI: indicies of possible variables.
;        .MEANW: The weighted mean magnitude for each obj.
;	 .MEAN: The unweighted mean magnitude for each obj.
;        .MED: Median magnitude for each object (unweighted).
;        .PTS: The number of points used to find mean.
;        .I:    The I-value of each object.
;        .IMED: I-Value calulated from median instead of meanw.
;        .SDEV: standard deviation from mean for each object.
;        .GREATV: The greatest deviation from the mean magnitude per object.
;        .FLAGS: Flags per object:
;	    1: Object is a blend problem
;	    2: Object reported as blend problem BUT is a possible LONG TERM
;              VARIABLE
;	    4: Object is a flare
;	    8: Object was not considered in ws3 (i.e. was removed using IN_CUT
;	        or MAGBIN_CUT)
;	    16: Object was not used when calculating I-value cuts (i.e. sdev
;	            of I-value) but cuts were applied to object (it can be a
;	            possible variable).
; (The following tags appear ONLY if NOINCL_IND or RMOBS keyword is set)
;         .NOINCL_IND:Indicies cut, if any (using NOINCL_IND).   
;         .RMOBS: Observations removed from structure, if any (using RMOBS)
;
; OPTIONAL OUTPUTS:
;
; NOTES: -Match structure must include paired images 
;        -For a simpler, faster version, see SIMPLE_WS3.PRO (does not
;         have all the features of WS3.PRO)
;
; EXAMPLE: If you wish to find possible variables in 'match' using an Icut
;of 10 sigma:
;IDL> ws3_good,match,good,/setup
;IDL>ws,match,varistruct,10,good_arr=good
;
; PROCEDURES CALLED: UNIQ_RANDOMU, BUDDY(CLOSE_MATCH (BINARY_SEARCH),
;    ONE_SEARCH (BINARY_SEARCH2)), GET_CONF3
;
; REVISION HISTORY:
;         Susan Amrose     UM         7/98
;         Susan Amrose     UM       8/27/98 added calibration to image
;         Susan Amrose     UM       8/31/98 Added tags 'close'
;                                            and 'flare'
;         Susan Amrose     UM       9/15/98 removed 'close' tag and added
;                                           'flags' tag
;         Susan Amrose     UM       1/21/99 added noincl_ind and 
;                                           ival_iter keywords
;         Susan Amrose     UM       1/29/99 added in_cut and sdv_cut 
;         Susan Amrose     UM       3/1/99  added rmob and use of 'good_arr'
;-

stime=systime(1)
if n_params() eq 0 then begin
    print,'syntax-ws3,match,varistruct,Icut,good_arr=good_arr,merror=merror,/sim,noincl_ind=noincl_ind,ival_iter=ival_iter,in_cut=in_cut,/sdv_cut,rmobs=rmobs,magbin_cut=magbin_cut,/get_conf'
    return
endif

nobs=n_elements(match.m(*,0))
nobj=n_elements(match.m(0,*))
flags=bytarr(nobj)

if keyword_set(good_arr) then good_arr=good_arr else ws3_good,match,good_arr,/setup

;**Get iter cuts 
if not keyword_set(iter) then iter=0
if not keyword_set(cuts) then $
  cuts=create_struct('niter',iter,'nsdev_cut',2.0, $
       'flare_frac',0.5,'icut_in',icut,'icut_f',icut,'bcut',9)
if n_elements(iter) eq 2 then cuts.icut_f=iter(1)

;** Set some defaults from simulated match structures

if keyword_set(sim) then begin
 merror=1.0
 name1=''
 name2=''
endif else begin
  name1=strmid(match.imagename(0),0,6)
  name2=strmid(match.imagename(1),0,6)
endelse

;** Pair the images

if name1 eq 'unknow' and name2 ne 'unknow' then begin
  print,'Template Detected'
  if floor((nobs-1)/2) ne (nobs-1)/2.0 then begin
     nobs=nobs-2
     print,'Last observataion dumped'
  endif
  template=1
endif else begin
  if floor(nobs/2) ne nobs/2.0 then begin
     nobs=nobs-1
     print,'Last observation dumped'
  endif     
  template=0
endelse
pair1=[template,template+2+indgen((nobs-2)/2)*2]
pair2=pair1+1

;** rmobs if keyword is called
gdobs=indgen(nobs)
if keyword_set(rmobs) then begin
  obs_rm=rmobs
  one_search,rmobs,pair1,p11,p12 
  if p12(0) ne -1.0 then begin 
        one_search,rmobs,pair2(p12),m1,m2,no1
        if no1(0) ne -1.0 then obs_rm=[obs_rm,pair2(p12(no1))]
	remove,p12,pair1
	remove,p12,pair2
  endif
  one_search,rmobs,pair2,p21,p22
  if p22(0) ne -1.0 then begin
        one_search,rmobs,pair1(p22),m1,m2,no1
        if no1(0) ne -1.0 then obs_rm=[obs_rm,pair1(p22(no1))] 
	remove,p22,pair1
	remove,p22,pair2
  endif
  print,'Observations ',rmobs,' requested to be removed'
  print,'Total obs removed: ',obs_rm,' due to pairing'
  print,''
  if n_elements(obs_rm) ne n_elements(gdobs) then remove,obs_rm,gdobs
endif

nobs=n_elements(gdobs)

;** perform initial cut if keyword IN_CUT is set

if keyword_set(in_cut) then begin 
 print,'Removing objects not found in at least ',in_cut,'% of the images'
 numkeep=ceil(in_cut*nobs/100.0)
 print,'Criteria: object must be found in at least ',numkeep,' images'
 all=-1.0
 for i=long(0),long(nobj-1) do begin
     num2=where(good_arr(gdobs,i) ne 0)
     if n_elements(num2) ge numkeep then all=[temporary(all),i]
 endfor
 if n_elements(all) gt 1 then remove,0,all
 if nobj eq n_elements(all) then print,'No Indicies removed from match' else begin
   print,nobj,' original objects'
   print,n_elements(all),' objects kept'
 endelse
 k=1
 in=indgen(nobj)
 if all(0) ne -1.0 and n_elements(all) ne nobj then remove,all,in
 flags(in)=flags(in)+8 
endif else all=lindgen(nobj)
nall=n_elements(all)


;set up arrays     
mean1=replicate(-1.0,nobj)
ptsused1=replicate(-1,nobj)
merr=replicate(-1.0,nobs,nobj)
meanerr=replicate(-1.0,nobj)
noerrmean=replicate(-1.0,nobj)
med=replicate(-1.0,nobj)
sd=replicate(-1.0,nobj)

if keyword_set(merror) then merr(*,*)=merror

print,''
print,'Calculating mean for each object'
for i=long(0),long(nall-1) do begin
    nomo=where(good_arr(gdobs,all(i)) eq 1)
    if template eq 1 and nomo(0) eq 0 then remove,0,nomo
    if nomo(0) ne -1.0 then begin
      nomo=gdobs(nomo)
      ptsused1(all(i))=n_elements(nomo)
      mags1=(match.m(nomo,all(i)))
      if not keyword_set(merror) then $
         merr(nomo,all(i))=sqrt(match.merr(nomo,all(i))^2+0.05^2)
      meanerr(all(i))=mean(merr(nomo,i))
      mean1(all(i))=(total(((mags1)/merr(nomo,all(i))^2))/(total((1/merr(nomo,all(i)))^2)))
      noerrmean(all(i))=total(mags1)/ptsused1(all(i))
      if n_elements(mags1) gt 1 then begin
         med(all(i))=median(mags1)
         v=moment(mags1,sdev=sdi)
         sd(all(i))=sdi
      endif else begin
         med(all(i))=mags1
         sd(all(i))=0.0
      endelse
    endif else begin
      ptsused1(all(i))=0
      meanerr(all(i))=-1.0
      mean1(all(i))=-1.0
      noerrmean(all(i))=-1.0
      med(all(i))=-1.0
      sd(all(i))=-1.0
    endelse  
endfor
print,''
print,'Calculating change for both pairs'

n=n_elements(pair1)
chg1=fltarr(n,nall)
chg2=fltarr(n,nall)
chg1med=fltarr(n,nall)
chg2med=fltarr(n,nall)

for j=0,n-1 do begin
     chg1(j,*)=match.m(pair1(j),all)-mean1(all)
     chg1med(j,*)=match.m(pair1(j),all)-med(all)
     nogd=where(good_arr(pair1(j),all) eq 0)
     if nogd(0) ne -1.0 then begin
        chg1(j,nogd)=0.0
        chg1med(j,nogd)=0.0
     endif
     chg2(j,*)=match.m(pair2(j),all)-mean1(all)
     chg2med(j,*)=match.m(pair2(j),all)-med(all)
     nogd=where(good_arr(pair2(j),all) eq 0)
     if nogd(0) ne -1.0 then begin
        chg2(j,nogd)=0.0
        chg2med(j,nogd)=0.0
     endif
endfor

chgarr=fltarr(nall)
chgarrmed=fltarr(nall)
greatest=fltarr(nobj)

for k=long(0),long(nall-1) do begin
    chgarr(k)=total(chg1(*,k)*chg2(*,k))
    chgarrmed(k)=total(chg1med(*,k)*chg2med(*,k))
    greatest(all(k))=max(chg1(*,k)) > max(chg2(*,k))
endfor

print,''
print,'Calculating I'

Iarr=fltarr(nobj)
Iarrmed=fltarr(nobj)
Iarr(all)=(sqrt(1.0/(n*(n-1.0))))*chgarr(*)
Iarrmed(all)=(sqrt(1.0/(n*(n-1.0))))*chgarrmed(*)


it=0
WHILE IT LE ITER(0) DO BEGIN
PRINT,'ITERATION ',IT,' OF ',iter(0)
if it eq 0 then icut=cuts.icut_in else icut=cuts.icut_f

;**** make iter cuts

Iarrcut=Iarr
Iarrcutmed=Iarrmed
meancut=noerrmean
allcut=all

noind=-1.0
if it gt 0 then noind=where((varistruct.flags and 1) ne 0 or (varistruct.flags and 4) ne 0)
if keyword_set(noincl_ind) then begin
   if noind(0) ne -1.0 then noind=[noind,noincl_ind] else noind=noincl_ind
endif

if noind(0) ne -1.0 then begin 
   remove,noind,Iarrcut
   remove,noind,Iarrcutmed
   remove,noind,meancut
   one_search,noind,allcut,nall1,nall2
   if nall2(0) ne -1.0 then remove,nall2,allcut   
   flags(noind)=flags(noind)+16
   print,n_elements(noind),' indicies removed from I-values before making cuts'
endif

s=moment(iarrcut,sdev=sdevi)
plot,noerrmean(all),iarr(all),psym=3,xrange=[8,15],$
yrange=[.25*(s(0)-(icut+1)*sdevi),s(0)+(icut+1)*sdevi],$
title='I-Value vs Magnitude',ytitle='I-Value (crosses indicate possible variable)',$
xtitle='Mean Magnitude'

;establish I value cuts

magbin=create_struct('magbin9',where(noerrmean(all) lt 9.0),$
 'magbin9_10',where(noerrmean(all) ge 9.0 and noerrmean(all) lt 10.0),$
 'magbin10_11',where(noerrmean(all) ge 10.0 and noerrmean(all) lt 11.0),$
 'magbin11_11_25',where(noerrmean(all) ge 11.0 and noerrmean(all) lt 11.25),$
 'magbin11_25_11_5',where(noerrmean(all) ge 11.25 and noerrmean(all) lt 11.5),$
 'magbin11_5_11_75',where(noerrmean(all) ge 11.5 and noerrmean(all) lt 11.75),$
 'magbin11_75_12',where(noerrmean(all) ge 11.75 and noerrmean(all) lt 12.0),$
 'magbin12_12_25',where(noerrmean(all) ge 12.0 and noerrmean(all) lt 12.25),$
 'magbin12_25_12_5',where(noerrmean(all) ge 12.25 and noerrmean(all) lt 12.5),$
 'magbin12_5_12_75',where(noerrmean(all) ge 12.5 and noerrmean(all) lt 12.75),$
 'magbin12_75_13',where(noerrmean(all) ge 12.75 and noerrmean(all) lt 13.0),$
 'magbin13_13_125',where(noerrmean(all) ge 13.0 and noerrmean(all) lt 13.125),$
 'magbin13_125_13_25',where(noerrmean(all) ge 13.125 and noerrmean(all) lt 13.25),$
 'magbin13_25_13_375',where(noerrmean(all) ge 13.25 and noerrmean(all) lt 13.375),$
 'magbin13_375_13_5',where(noerrmean(all) ge 13.375 and noerrmean(all) lt 13.5),$
 'magbin13_5_13_625',where(noerrmean(all) ge 13.5 and noerrmean(all) lt 13.625),$
 'magbin13_625_13_75',where(noerrmean(all) ge 13.625 and noerrmean(all) lt 13.75),$
 'magbin13_75_13_875',where(noerrmean(all) ge 13.75 and noerrmean(all) lt 13.875),$
 'magbin13_875_14',where(noerrmean(all) ge 13.875 and noerrmean(all) lt 14.0),$
 'magbin14_14_125',where(noerrmean(all) ge 14.0 and noerrmean(all) lt 14.125),$
 'magbin14_125_14_25',where(noerrmean(all) ge 14.125 and noerrmean(all) lt 14.25),$
 'magbin14_25_14_375',where(noerrmean(all) ge 14.25 and noerrmean(all) lt 14.375),$
 'magbin14_375_14_5',where(noerrmean(all) ge 14.375 and noerrmean(all) lt 14.5),$
 'magbin14_5_14_625',where(noerrmean(all) ge 14.5 and noerrmean(all) lt 14.625),$
 'magbin14_625_14_75',where(noerrmean(all) ge 14.625 and noerrmean(all) lt 14.75),$
 'magbin14_75_14_875',where(noerrmean(all) ge 14.75 and noerrmean(all) lt 14.875),$
 'magbin14_875_14',where(noerrmean(all) ge 14.875 and noerrmean(all) lt 15.0),$
 'magbin15',where(noerrmean(all) ge 15.0))

magbin_c=create_struct('magbin9',where(meancut(allcut) lt 9.0),$
 'magbin9_10',where(meancut(allcut) ge 9.0 and meancut(allcut) lt 10.0),$
 'magbin10_11',where(meancut(allcut) ge 10.0 and meancut(allcut) lt 11.0),$
 'magbin11_11_25',where(meancut(allcut) ge 11.0 and meancut(allcut) lt 11.25),$
 'magbin11_25_11_5',where(meancut(allcut) ge 11.25 and meancut(allcut) lt 11.5),$
 'magbin11_5_11_75',where(meancut(allcut) ge 11.5 and meancut(allcut) lt 11.75),$
 'magbin11_75_12',where(meancut(allcut) ge 11.75 and meancut(allcut) lt 12.0),$
 'magbin12_12_25',where(meancut(allcut) ge 12.0 and meancut(allcut) lt 12.25),$
 'magbin12_25_12_5',where(meancut(allcut) ge 12.25 and meancut(allcut) lt 12.5),$
 'magbin12_5_12_75',where(meancut(allcut) ge 12.5 and meancut(allcut) lt 12.75),$
 'magbin12_75_13',where(meancut(allcut) ge 12.75 and meancut(allcut) lt 13.0),$
 'magbin13_13_125',where(meancut(allcut) ge 13.0 and meancut(allcut) lt 13.125),$
 'magbin13_125_13_25',where(meancut(allcut) ge 13.125 and meancut(allcut) lt 13.25),$
 'magbin13_25_13_375',where(meancut(allcut) ge 13.25 and meancut(allcut) lt 13.375),$
 'magbin13_375_13_5',where(meancut(allcut) ge 13.375 and meancut(allcut) lt 13.5),$
 'magbin13_5_13_625',where(meancut(allcut) ge 13.5 and meancut(allcut) lt 13.625),$
 'magbin13_625_13_75',where(meancut(allcut) ge 13.625 and meancut(allcut) lt 13.75),$
 'magbin13_75_13_875',where(meancut(allcut) ge 13.75 and meancut(allcut) lt 13.875),$
 'magbin13_875_14',where(meancut(allcut) ge 13.875 and meancut(allcut) lt 14.0),$
 'magbin14_14_125',where(meancut(allcut) ge 14.0 and meancut(allcut) lt 14.125),$
 'magbin14_125_14_25',where(meancut(allcut) ge 14.125 and meancut(allcut) lt 14.25),$
 'magbin14_25_14_375',where(meancut(allcut) ge 14.25 and meancut(allcut) lt 14.375),$
 'magbin14_375_14_5',where(meancut(allcut) ge 14.375 and meancut(allcut) lt 14.5),$
 'magbin14_5_14_625',where(meancut(allcut) ge 14.5 and meancut(allcut) lt 14.625),$
 'magbin14_625_14_75',where(meancut(allcut) ge 14.625 and meancut(allcut) lt 14.75),$
 'magbin14_75_14_875',where(meancut(allcut) ge 14.75 and meancut(allcut) lt 14.875),$
 'magbin14_875_14',where(meancut(allcut) ge 14.875 and meancut(allcut) lt 15.0),$
 'magbin15',where(meancut(allcut) ge 15.0))

names=tag_names(magbin)

if keyword_set(magbin_cut) then begin
	for i=0,n_elements(magbin_cut)-1 do begin
           flags(all(magbin.((magbin_cut(i)-1)*2)))= $
              flags(all(magbin.((magbin_cut(i)-1)*2)))+8
	   magbin.((magbin_cut(i)-1)*2)=-1.0
           magbin.((magbin_cut(i)-1)*2+1)=-1.0
           magbin_c.((magbin_cut(i)-1)*2)=-1.0
           magbin_c.((magbin_cut(i)-1)*2+1)=-1.0
        endfor
        print,''
        print,names((magbin_cut-1)*2),' removed from consideration'
endif

;***Get standard deviation of iarrcut for each magbin.
print,''
if not keyword_set(ival_iter) then ival_iter=3
if not keyword_set(isdev_iter) then isdev_iter=3

possvari=-1.0
bcut=cuts.bcut
sdv=fltarr(27)
v0=fltarr(bcut)
fit=-1.0
for i=0,26 do begin
 iv_iter=0
 bin=magbin_c.(i)
 if bin(0) ne -1.0 then begin
  while iv_iter ne ival_iter do begin
    if n_elements(bin) ge 2 then begin
      v=moment(Iarrcut(allcut(bin)),sdev=sdev2)
      cut=where(abs(Iarrcut(allcut(bin))-median(Iarrcut(allcut(bin)))) gt sdev2)
    endif else begin
      if i ne 0 then sdev2=sdv(i-1) else sdev2=0.0
      cut=-1.0
    endelse
    if cut(0) ne -1.0 then remove,cut,bin
    iv_iter=iv_iter+1
  endwhile
  if i lt bcut then v0(i)=v(0)
  fit=[fit,bin]

  bin=magbin_c.(i)
  iv_iter=0
  while iv_iter ne isdev_iter do begin
    if n_elements(bin) ge 2 then begin
      v=moment(Iarrcut(allcut(bin)),sdev=sdev2)
      cut=where(abs(Iarrcut(allcut(bin))-median(Iarrcut(allcut(bin)))) gt 2*sdev2)
    endif else begin
      if i ne 0 then sdev2=sdv(i-1) else sdev2=0.0
      cut=-1.0
    endelse
    if cut(0) ne -1.0 then remove,cut,bin
    iv_iter=iv_iter+1
  endwhile
  sdv(i)=sdev2
 endif
endfor
if n_elements(fit) gt 1 then remove,0,fit

;*** Fit exponential part of I value curve 

keep=where(meancut(allcut(fit)) gt 12.0 and meancut(allcut(fit)) lt 14.5)
uniq_randomu,100,0,n_elements(fit),ind
l=linfit(meancut(allcut(fit(keep))),alog(iarrcut(allcut(fit(keep)))))
const=mean(Iarrcut(allcut(fit(keep(ind))))/(exp(l(1)*meancut(allcut(fit(keep(ind)))))))
oplot,meancut(allcut(fit)),const*exp(l(1)*meancut(allcut(fit)))

;*** Fit Icut sigma line

mags=[9,10,11,11.25,11.5,11.75,12,12.25,12.5,12.75, $
  13,13.125,13.25,13.375,13.5,13.625,13.75,13.875,14, $
  14.125,14.25,14.375,14.5,14.625,14.75,14.875,15]
three_sig=[icut*sdv(0:bcut-1)+v0(0:bcut-1), $
  (const*exp(l(1)*mags(bcut:*)))+(icut*sdv(bcut:*))]

pre_12=poly_fit(mags(1:bcut),three_sig(1:bcut),2)
n=2
while (pre_12(2) < 0) ne 0 and n lt bcut-1 do begin
   three_sig(0:n)=replicate(three_sig(n+1),n+1)
   pre_12=poly_fit(mags(1:bcut),three_sig(1:bcut),2) 
   n=n+1
endwhile
if (pre_12(2) < 0) ne 0 then pre_12=poly_fit(mags(1:bcut),three_sig(1:bcut),1)   
oplot,mags(0:bcut),pre_12(0)+pre_12(1)*mags(0:bcut)+pre_12(2)*mags(0:bcut)^2
post_12=linfit(mags(bcut:23),alog(three_sig(bcut:23)))
con=mean(three_sig(bcut:23)/exp(post_12(1)*mags(bcut:23)))
add=(pre_12(0)+pre_12(1)*mags(bcut)+pre_12(2)*mags(bcut)^2)- $
  (con*exp(post_12(1)*mags(bcut)))

oplot,mags(bcut:*),con*exp(post_12(1)*mags(bcut:*)+add)

;*** Now find high sigma I-values

possvari=-1.0
for b=0,9 do $
 for elem=0,n_elements(magbin.(b))-1 do $
   if magbin.(b)(0) ne -1.0 then $
   if iarr(all(magbin.(b)(elem))) gt $
   pre_12(0)+pre_12(1)*noerrmean(all(magbin.(b)(elem)))+ $
   pre_12(2)*noerrmean(all(magbin.(b)(elem)))^2 then $
   possvari=[possvari,magbin.(b)(elem)]   

for b=10,26 do $
 for elem=0,n_elements(magbin.(b))-1 do $
   if magbin.(b)(0) ne -1.0 then $
   if iarr(all(magbin.(b)(elem))) gt $
   con*exp(post_12(1)*noerrmean(all(magbin.(b)(elem))))+add then $
   possvari=[possvari,magbin.(b)(elem)]

if n_elements(possvari) gt 1 then remove,0,possvari

print,n_elements(possvari),' possible variables found'

oplot,noerrmean(all(possvari)),iarr(all(possvari)),psym=1

print,''
print,'Flagging blended objects'
nvari=n_elements(possvari)

;**Check for deblend problems

buddy,match,all(possvari),good_arr,bud,/silent
one=where(abs(bud.nsdev) gt cuts.nsdev_cut and (flags(all(possvari)) and 1) eq 0)
if one(0) ne -1.0 then flags(all(possvari(one)))=flags(all(possvari(one)))+1
posslg=where(bud.posslg(one) eq 'Y' and (flags(all(possvari(one))) and 2) eq 0)
if posslg(0) ne -1.0 then flags(all(possvari(one(posslg))))= $
    flags(all(possvari(one(posslg))))+2

print,'Flagging flares'
chgtot=fltarr(2*n,nall)
chgtot(pair1,*)=chg1med
chgtot(pair2,*)=chg2med
for k=0,nvari-1 do begin
   maxchg=where(abs(chgtot(*,possvari(k))) eq max(abs(chgtot(*,possvari(k)))))
   per=fltarr(n*2)
   for j=0,(2*n)-1 do begin
      per(j)=abs(chgtot(j,possvari(k)))/abs(chgtot(maxchg(0),possvari(k)))
   endfor
   test=where(per ge cuts.flare_frac)
   if n_elements(test) le 2 then if (flags(all(possvari(k))) and 4) eq 0 then $
            flags(all(possvari(k)))=flags(all(possvari(k)))+4 
endfor
print,''
print,'Removing blends and flares from variable array'
bd=where((flags(all(possvari)) and 1) ne 0 and (flags(all(possvari)) and 2) eq 0 $
  or (flags(all(possvari)) and 4) ne 0)
if bd(0) ne -1.0 and n_elements(bd) ne n_elements(possvari) then remove,bd,possvari 
print,''
print,n_elements(possvari),' possible variables remaining'
print,''
print,'Creating Variables structure..'

if not keyword_set(noincl_ind) then no_ind=-1.0 else no_ind=noincl_ind
if not keyword_set(rmobs) then rmobs1=-1.0 else rmobs1=rmobs
if keyword_set(noincl_ind) or keyword_set(rmobs) then $
varistruct=create_struct('vari',all(possvari),'meanw',mean1,$
 'mean',noerrmean,'median',med,'PTS',ptsused1,'I',iarr,'Imed',iarrmed,$
 'sdev',sd,'greatv',greatest,'flags',flags,'conf',fltarr(n_elements(possvari)), $
 'noincl_ind',no_ind,'rmobs',rmobs1) else $
varistruct=create_struct('vari',all(possvari),'meanw',mean1,$
 'mean',noerrmean,'median',med,'PTS',ptsused1,'I',iarr,'Imed',iarrmed,$
 'sdev',sd,'greatv',greatest,'flags',flags,'conf',fltarr(n_elements(possvari)))

it=it+1
ENDWHILE

if keyword_set(get_conf) then begin
     get_conf3,match,varistruct,good_arr,magbin,chg1,chg2,prime_struct,$
       conf,in_cut=in_cut,/conf1
     varistruct.conf(*)=conf
endif
print,'Total time elapsed: ',(systime(1)-stime),' seconds'

return
end








