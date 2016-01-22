pro simple_ws3,match,vari,icut,good=good,in_cut=in_cut,ival_iter=ival_iter,merror=merror

;PURPOSE: This is the welch/stetson technique for finding variable stars as
;described in their paper 'Robust Variable Star Detection Techniques
;Suitable For Automated Searches: New Results for NGC 1866' found in the
;may 1993 issue of the Astronomical Journal (V.105,n.5).
;
;PARAMETERS:
;-match: the structure to test for variables.  
;-varistruct: The returned variable structure with the following tag names:
;        .VARI: indicies of possible variables in the match structure.
;        .MEANW: The weighted mean magnitude for each object.
;	 .MEAN: The unweighted mean magnitude for each object.
;        .PTS: The number of points used to find mean for each object.      
;        .I:    The I-value of each object.
;        .FlARE: Set to 'Y' if (mag - meanw) for each obs is less than 30% the
;                (mag - meanw) of any two obs. Set to 'N' otherwise.
;        .GREATV: The greatest deviation from the mean magnitude per object.
;        .MERR: The error used to weight each MEANW (nobs,nobj).
;
;-Icut: A given sigma cut, the number of sigmas above the average I value
;       an object's I-value must be to be considered variable.

;
;KEYWORDS: 
;  merror: Set this to a constant error to be used for each object.
;  ival_iter: Set this to the number if iterations used to find the sdev 
;             of the i-value about its mean (used to find I-value cut).
;             Default is 2.
;  in_cut: Set this to a whole number percentage and WS3 will require that 
;          any object be in at least this percentage of observations.
;-good: Set this to result of WS3_GOOD.PRO
;       ws3_good,match,good[,param,/setup]. If it is not set,
;       then the GOOD array will be made in simple_ws3 using defaults.
;
;EXAMPLE: If you wish to find possible variables in 'match' using an Icut
;of 2 sigma:
;IDL>ws3_good,match,good,/setup
;IDL>simple_ws3,match,vari,2,good=good
;
;NOTES: 
;     -If match structure is not in 'pairs', i.e. the number of observations is uneven,
;  then the final observation will be ignored.
;     -To retrieve indicies cut using IN_CUT, do:
; IDL>ind=where(vari.mean eq -1.0)
;     - to get the I-values of just possible variables do:
; IDL>ival=vari.i(vari.vari)
;
;Written by        Susan Amrose     UM         3/8/99  modified from WS3.PRO

stime=systime(1)
if n_params() eq 0 then begin
    print,'syntax-simple_ws3,match,vari,Icut,good=good,merror=merror,ival_iter=ival_iter,in_cut=in_cut
    return
endif


nobs=n_elements(match.m(*,0))
nobj=n_elements(match.m(0,*))

if keyword_set(good) then good=good else ws3_good,match,good,/setup

;** Pair the images

name1=strmid(match.imagename(0),0,6)
name2=strmid(match.imagename(1),0,6)
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

;** perform initial cut if key word is set

if keyword_set(in_cut) then begin $
 print,'Removing objects not found in at least ',in_cut,'% of the images'
 numkeep=ceil(in_cut*nobs/100.0)
 print,'Criteria: object must be found in at least ',numkeep,' images'
 all=-1.0
 for i=long(0),long(nobj-1) do begin
     num2=where(good(*,i) ne 0)
     if n_elements(num2) ge numkeep then all=[temporary(all),i]
 endfor
 if n_elements(all) gt 1 then remove,0,all
 if nobj eq n_elements(all) then print,'No Indicies removed from match' else begin
   print,nobj,' original objects'
   print,n_elements(all),' objects kept'
 endelse
 k=1
endif else all=lindgen(nobj)

;set up arrays     
nall=n_elements(all)
mean1=replicate(-1.0,nobj)
ptsused1=replicate(1,nobj)
merr=replicate(-1.0,nobs,nobj)
meanerr=replicate(-1.0,nobj)
noerrmean=replicate(-1.0,nobj)

if keyword_set(merror) then merr(*,*)=merror

print,''
print,'Calculating mean for each object'
for i=long(0),long(nall-1) do begin
    nomo=where(good(*,all(i)) eq 1)
    if template eq 1 and nomo(0) eq 0 then remove,0,nomo
    if nomo(0) ne -1.0 then begin
      ptsused1(i)=n_elements(nomo)
      mags1=(match.m(nomo,all(i)))
      if not keyword_set(merror) then $
         merr(nomo,all(i))=sqrt(match.merr(nomo,all(i))^2+0.05^2)
      meanerr(all(i))=mean(merr(nomo,all(i)))
      mean1(all(i))=(total(((mags1)/merr(nomo,all(i))^2))/(total((1/merr(nomo,all(i)))^2)))
      noerrmean(all(i))=total(mags1)/ptsused1(all(i))
      if n_elements(mags1) gt 1 then v=moment(mags1,sdev=sdi)
    endif else begin
      ptsused1(all(i))=0
      meanerr(all(i))=-1.0
      mean1(all(i))=-1.0
      noerrmean(all(i))=-1.0
    endelse  
endfor
print,''
print,'Calculating change for both pairs'

n=n_elements(pair1)
nall=n_elements(all)
chg1=fltarr(n,nall)
chg2=fltarr(n,nall)

for j=0,n-1 do begin
     chg1(j,*)=match.m(pair1(j),all)-mean1(all)
     nogd=where(good(pair1(j),all) eq 0)
     if nogd(0) ne -1.0 then chg1(j,nogd)=0.0
     chg2(j,*)=match.m(pair2(j),all)-mean1(all)
     nogd=where(good(pair2(j),all) eq 0)
     if nogd(0) ne -1.0 then chg2(j,nogd)=0.0
endfor

chgarr=fltarr(nall)
greatest=fltarr(nobj)

for k=long(0),long(nall-1) do begin
    chgarr(k)=total(chg1(*,k)*chg2(*,k))
    greatest(k)=max(chg1(*,k)) > max(chg2(*,k))
endfor

print,''
print,'Calculating I'

Iarr=fltarr(nobj)

Iarr(all)=(sqrt(1.0/(n*(n-1.0))))*chgarr(*)


s=moment(iarr(all),sdev=sdevi)
plot,iarr(all),match.m(0,all),psym=3,yrange=[5,15],xrange=[s(0)-(icut+1)*sdevi,s(0)+(icut+1)*sdevi],$
title='I-Value vs Magnitude',xtitle='I-Value (crosses indicate possible variable)',$
ytitle='Magnitude'

;make I value cuts

magbin=create_struct('magbin1',where(noerrmean(all) lt 9.0),$
 'magbin2',where(noerrmean(all) ge 9.0 and noerrmean(all) lt 10.0),$
 'magbin3',where(noerrmean(all) ge 10.0 and noerrmean(all) lt 11.0),$
 'magbin4',where(noerrmean(all) ge 11.0 and noerrmean(all) lt 12.0),$
 'magbin5',where(noerrmean(all) ge 12.0 and noerrmean(all) lt 13.0),$
 'magbin6',where(noerrmean(all) ge 13.0))


print,''
if not keyword_set(ival_iter) then ival_iter=2
possvari=-1.0

names=tag_names(magbin)
b=0

for i=0,5 do begin
 iter=0
 bin=magbin.(i)
 if bin(0) ne -1.0 then begin
  while iter ne ival_iter do begin
    v=moment(Iarr(all(bin)),sdev=sdev2)
    cut=where(Iarr(all(bin))-mean(Iarr(all(bin))) gt sdev2*2)
    if cut(0) ne -1.0 then remove,cut,bin
    iter=iter+1
  endwhile
  cut=where(Iarr(all(magbin.(i)))-mean(iarr(all(bin))) gt Icut*sdev2)
  print,'sdev for ',names(i),' = ',sdev2
  print,'Cut is ',sdev2*Icut
  print,''
  if cut(0) ne -1.0 then possvari=[possvari,magbin.(i)(cut)]
 endif
endfor
remove,0,possvari

print,n_elements(possvari),' possible variables found'

oplot,iarr(all(possvari)),match.m(0,all(possvari)),psym=1

print,''
print,'Finding flares within possible variables'
nvari=n_elements(possvari)
flare=replicate('',nvari)
chgtot=fltarr(2*n,nall)
chgtot(pair1,*)=chg1
chgtot(pair2,*)=chg2
for k=0,nvari-1 do begin
   maxchg=where(abs(chgtot(*,possvari(k))) eq max(abs(chgtot(*,possvari(k)))))
   per=fltarr(n*2)
   for j=0,(2*n)-1 do begin
      per(j)=abs(chgtot(j,possvari(k)))/abs(chgtot(maxchg(0),possvari(k)))
   endfor
   test=where(per ge 0.5)
   if n_elements(test) gt 2 then flare(k)='N' else flare(k)='Y'
   endfor
print,''

print,''
print,'Creating Variables structure..'

vari=create_struct('vari',all(possvari),'meanw',mean1,$
 'mean',noerrmean,'PTS',ptsused1,'I',iarr,$
 'flare',flare,'greatv',greatest)

print,'Total time elapsed: ',(systime(1)-stime),' seconds'

return
end








