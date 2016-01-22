pro period_fold,match,index,period,phase,wait=wait
;+
; NAME: PERIOD_FOLD
;
; PURPOSE: To plot magnitude and phase given a period for a set of objects.
;     Also plots the magnitude vs time light curve.
;
; CALLING SEQUENCE: period_fold,match,index,period,wait=wait
;
; INPUTS: match- match structure 
;         index- array of indicies to 'match' for which light curves
;           should be plotted.
;         period - array of periods corresponding to 'index'
;
; OPTIONAL INPUTS: wait - time in seconds to wait between object.
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; NOTES: works with ploterr version in: 
;        /sdss3/products/idlastron/pro/plot/ploterr.pro
;
; EXAMPLE: To look at object 777 in match structure MA with a period
;     of 0.9 days:
;  IDL> period_fold,ma,777,0.9
;
; PROCEDURES CALLED: LCPLOT, PLOTERR 
;
; REVISION HISTORY:
;              Susan Amrose     UM     3/23/99
;-
 On_error,2                                      ;Return to caller

 if N_params() EQ 0 then begin
    print,'Syntax - period_fold,match,index,period,wait=wait' 
    return
 endif

if not keyword_set(wait) then wait=0
!p.multi=[0,0,2]
names=tag_names(match)
ra=where(names eq 'RA')
for i=0,n_elements(index)-1 do begin
 gd=where(match.m(*,index(i)) ne -1.0)
 if gd(0) ne -1 then begin
  phase=fltarr(n_elements(gd))
  t0=match.jd(gd(0))
  for j=0,n_elements(gd)-1 do phase(j)=(((match.jd(gd(j))-t0)/period(i))-floor((match.jd(gd(j))-t0)/period(i)))
  lcplot,match,gd,[index(i)],/err
  if ra(0) ne -1.0 then $
     stg='Ra: '+string(match.ra(index(i)))+' Dec: '+string(match.dec(index(i)))+ $
        ' Period: '+string(period(i)) else $
     stg=' Period: '+string(period(i))
  ploterror,phase,match.m(gd,index(i)),match.merr(gd,index(i)),psym=7,/ynozero,ytitle='Magnitude',xtitle='Phase',title=stg
  wait,wait
 endif else print,'no good obs for index: ',index(i)
endfor 
!p.multi=0

return
end
