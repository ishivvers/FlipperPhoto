pro ivalue,mags,merr,ivalue,mn_iter=mn_iter,robust=robust

;+
; NAME: IVALUE
;	
; PURPOSE: Calculate the Welch/Stetson ivalue of a light curve.  
;	
; CALLING SEQUENCE: ivalue,mags,merr,ivalue,mn_iter=mn_iter,/robust
;	
; INPUTS: mags - array of magnitudes from light curve. Values of -1
;                will be ignored.
;         merr - array of magnitude errors.
;	
; OPTIONAL INPUTS:
;         mn_iter - number of iterations for iterative mean.
;                   The iterative mean reduces the effect of 
;                   single outliers on the mean. 
;                   {def=0 no robust, def=4 robust} 
;         /robust - set this to calculate the robust Ivalue 
;                   of Stetsons 1996 paper rather than the original
;                   ivalue from W/S 1993 paper. The robust version
;                   reduces the effect of outliers. 
; OUTPUTS: 
;         ivalue - the WS ivalue.
;	
; OPTIONAL OUTPUTS:
;	
; NOTES: If Ivalues are too high, check the object errors, they 
;        may be too low. 
;	
; EXAMPLE:  To calculate the ivalue of object 15 in a match structure:
;         
;         IDL> ivalue, match.m(*,15), match.merr(*,15), ival
;	
; PROCEDURES CALLED: ITER_MEAN
;	
; REVISION HISTORY: Susan Amrose    UM     8/15/00	
;-
 On_error,2 
if n_params() eq 0 then begin
  print,'syntax- ivalue,mags,merr,ivalue, [mn_iter=mn_iter,/robust]'
  return
endif

num=n_elements(mags)

if not keyword_set(mn_iter) then mn_iter=0

gd=where(mags ne -1,ngd)
if ngd eq 0 then ivalue=-99 else begin
  pair1=indgen(ngd/2.0)*2.0
  pair2=pair1+1   

  iter_mean,mags(gd),merr(gd),mn,niter=mn_iter
  if not keyword_set(robust) then begin
    con=sqrt(1.0/ ( (ngd/2.0)*((ngd/2.0)-1) ) )

    chg=(mags(gd)-mn)/merr
    ivalue=con*total(chg(gd(pair1))*chg(gd(pair2)))

  endif else begin
    chg=sqrt(ngd/ (ngd-1) )*(mags(gd)-mn)/merr
    kind=(1.0/ngd)*total(abs(chg(gd)))/ $
      sqrt((1.0/ngd)*total(chg(gd)^2))
    chgarr=chg(gd(pair1))*chg(gd(pair2))
    jind=total(chgarr/sqrt(abs(chgarr)))/ngd
    
    ivalue= jind*kind/0.798

  endelse
endelse

return
end




