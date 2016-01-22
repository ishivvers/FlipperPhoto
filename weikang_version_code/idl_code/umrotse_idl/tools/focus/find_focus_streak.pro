pro find_focus_streak,gfocs,gfwhms,gfwhm_errs,bestfoc,err,chisq,chisq_tol=chisq_tol,mingd=mingd,maxfwhm=maxfwhm,fail=fail,plot=plot

if n_params() eq 0 then begin
    print,'syntax- find_focus_streak,gfocs,gfwhms,gfwhm_errs,bestfoc,err,chisq_tol=chisq_tol,maxfwhm=maxfwhm,fail=fail,plot=plot'
    return
endif

if (n_elements(mingd) eq 0) then mingd = 6
if (n_elements(chisq_tol) eq 0) then chisq_tol = 15.0
if (n_elements(maxfwhm) eq 0) then maxfwhm = 6.0
if (n_elements(slop) eq 0) then slop = 0.1

fail=0
bestfoc=-1.0
err=-1.0
chisq=0.0

if keyword_set(plot) then $
  ploterror,gfocs,gfwhms,gfwhm_errs,psym=1

ok=where(gfwhms gt 0.0,nok)
if (nok lt mingd) then begin
    print,'Not enough good points'
    fail = 1
endif


if (fail eq 0) then begin

    focs = gfocs[ok]
    fwhms = gfwhms[ok]
    fwhm_errs = gfwhm_errs[ok]
    
    minfwhm=min(fwhms,indices)
    if ((minfwhm gt maxfwhm) or (indices[0] eq 0) or $
        (indices[0] eq n_elements(fwhms)-1)) then begin
        print,'best point no good'
        fail = 1
    endif else begin
        j=indices[0]-1
        while (j ge 0) do begin
            if (fwhms[j] gt maxfwhm) then j=-1 else begin
                add_arrval,j,indices
                j=j-1
            endelse
        endwhile
        
        j=indices[0]+1
        while (j le n_elements(fwhms)-1) do begin
            if (fwhms[j] gt maxfwhm) then j=n_elements(fwhms) else begin
                add_arrval,j,indices
                j=j+1
            endelse
        endwhile
        
        if (n_elements(indices) lt mingd) then begin
            print,'Not enough good points to fit'
            fail = 1
        endif else begin
            if (keyword_set(plot)) then $
              oplot,focs[indices],fwhms[indices],psym=7
            fit=svdfit(focs[indices],fwhms[indices],3, $
                       measure_errors=fwhm_errs[indices],chisq=chisq,/double)
            
        endelse
        
    endelse
    
endif

if (fail eq 0) then begin
    xvals=(findgen(100)/100.)*(max(focs)-min(focs))+min(focs)
    yvals=fit[0]+fit[1]*xvals+fit[2]*(xvals^2.)

    if (keyword_set(plot)) then $
      oplot,xvals,yvals

    target_y = min(yvals) * (1. + slop)
    a=fit[2]
    b=fit[1]
    c=fit[0] - target_y
    
    inrad=b^2-4*a*c
    if (inrad lt 0.0) then begin
        print,'negative radical!'
        fail = 1
    endif else begin
        radical = sqrt(inrad)

        xmin=(-b-radical)/(2.*a)
        xmax=(-b+radical)/(2.*a)
    
        bestfoc = (xmax + xmin) / 2.
        err = (xmax - xmin) / 2.0

        if (bestfoc lt 0.0 or bestfoc gt 10.0 or chisq gt chisq_tol) then begin
            print,'bad solution'
            fail=1
            bestfoc=-1.0
            err=-1.0
        endif

    endelse


endif



return
end

