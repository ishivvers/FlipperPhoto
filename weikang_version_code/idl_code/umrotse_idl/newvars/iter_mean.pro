pro iter_mean,mags,merr,MEAN1,MNERR,PTS,niter=niter

; NAME: ITER_MEAN
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
;
; REVISION HISTORY: Susan Amrose    UM     8/15/00

if n_params() eq 0 then begin
  print,'syntax-iter_mean,mags,merr,MEAN1,MNERR,PTS,niter=niter'
  return
endif

if not keyword_set(niter) then niter=4
nomo=where(mags gt 0,pts)
if pts ne 0 then BEGIN
    chg=fltarr(pts)
    w=1/(merr[nomo]^2)
    it=0
    WHILE it LE niter DO BEGIN
        wtot=total(w)
        mean1=total(mags[nomo]*w)/wtot
        chg=(mags[nomo]-mean1)/merr[nomo]
        w=(1.0/(1.0+(chg/2.0)^2))/(merr[nomo]^2)
;        print, mean1, ' ', w
        it=it+1
    ENDWHILE
    mnerr=sqrt(total(w^2*chg^2)/wtot^2)
ENDIF

return
end
