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
num=n_elements(mags)
chg=fltarr(num)
nomo=where(mags gt 0,pts)
if pts ne 0 then begin
  w=1/(merr^2)
  it=0
  WHILE it LE niter DO BEGIN
    wtot=total(w)
    mean1=total(mags*w)/wtot
    chg(nomo)=(mags(nomo)-mean1)/merr
    mnerr=sqrt(total(w^2*chg(nomo)^2)/wtot^2)
    
    w=w*(1.0/(1.0+(abs(chg(nomo))/2.0)^2))
    it=it+1
  ENDWHILE
endif

return
end
