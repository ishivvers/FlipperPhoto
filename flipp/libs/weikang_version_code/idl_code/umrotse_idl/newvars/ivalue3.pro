FUNCTION ivalue3,mags,merr,mn_iter=mn_iter,norobust=norobust
;+
; NAME: IVALUE3
;	
; PURPOSE: Calculate the Welch/Stetson ivalue of a light curve.  
;	
; CALLING SEQUENCE: ivalue3,ms,mrs,ivalue,mn_iter=mn_iter,/norobust
;	
; INPUTS: mags - array of magnitudes from light curve. Negative values
;                will be ignored.
;         merr - array of magnitude errors.
;	
; OPTIONAL INPUTS:
;         mn_iter - number of iterations for iterative mean.
;                   The iterative mean reduces the effect of 
;                   single outliers on the mean. 
;                   {def=0 no robust, def=4 robust} 
;         /norobust - set this to *not* calculate the robust Ivalue 
;                   of Stetsons 1996 paper.  Rather, use the original
;                   ivalue from W/S 1993 paper. The robust version
;                   reduces the effect of outliers. 
; OUTPUTS: 
;         ivalue - array of WS ivalues.
;	
; OPTIONAL OUTPUTS:
;	
; NOTES: If Ivalues are too high, check the object errors, they 
;           may be too low. 
;        Current program does not distinguish between non-detection because
;           source was too dim (mag=-1) and non-detection because source was
;           out of the FOV (mag=-2)
;           
; EXAMPLE:  To calculate the ivalue of object 15 in a match structure:
;         
;         IDL> ivalue, match.m(*,15), match.merr(*,15), ival
;	
; PROCEDURES CALLED: ITER_MEAN
;	
; REVISION HISTORY:  Don Smith   UM   3/4/02 -- Adapted from S. Ambrose code
;-
ii=-999.9
On_error,2 
if n_params() eq 0 then begin
  print,'syntax- ivalue3,mags,merr,ivalue, [mn_iter=mn_iter,/norobust]'
ENDIF ELSE BEGIN 

    ngood = n_elements(mags)
    IF NOT keyword_set(mn_iter) THEN mn_iter=0    
    pair1=indgen(ngood/2.0)*2.0
    pair2=pair1+1
        
    iter_mean,mags,merr,mn,niter=mn_iter
    IF keyword_set(norobust) THEN BEGIN
        con=sqrt(1.0/ ( (ngood/2.0)*((ngood/2.0)-1) ) )
        chg=(mags-mn)/merr
        ii=con*total(chg[pair1]*chg[pair2])
    ENDIF ELSE BEGIN
        chg=sqrt(ngood/ (ngood-1) )*(mags-mn)/merr
        kind=(1.0/ngood)*total(abs(chg))/ $
          sqrt((1.0/ngood)*total(chg^2))
        chgarr=chg[pair1]*chg[pair2]
        zer = where(abs(chgarr) EQ 0, nz)
        IF nz GT 0 THEN chgarr[zer] = 0.000000001
        jind=total(chgarr/sqrt(abs(chgarr)))/ngood
        
        ii= jind*kind/0.798
    ENDELSE
ENDELSE 
return, ii
END
