pro focus_find_best,focstr,best,mingd=mingd,useratio=useratio
;+
; NAME: focus_find_best
;
; CALLING SEQUENCE: focus_find_best,focstr,best,mingd=mingd,useratio=useratio
;
; INPUTS:            focstr:  focus info structure
;                    best:    structure of best focus values
;
; OUTPUTS:           best:    structure of best focus values
;
; INPUT KEYWORDS:    mingd:   minimum good points to fit
;                    useratio: use count ratio and not FWHM
;
; PROCEDURE:   This program plots the fwhm as a function of focus, fits a
;  parabola, and queries the user as to whether or not it is a good fit. 
;  This program is used by gen_focus_model.
;
; REVISION HISTORY:
;    Eli Rykoff    UM    10/21/03 - First official version
;
;===========================================================================
;-
if n_params() eq 0 then begin
    print,'syntax- focus_find_best,focstr,best,mingd=mingd,useratio=useratio'
    return
endif

if n_elements(mingd) eq 0 then begin
    mingd = 5
endif

ratio_cut = 2.0
fwhm_cut = 6.0
slop = 0.1

for i=0l,n_elements(best)-1 do begin
    fail = 0
    manual = 0

    print,'----'
    print,'Focus Sequence = ', best[i].file

    first=best[i].first
    last=best[i].last
    fwhms=focstr[first:last].fwhm
    ratios=focstr[first:last].ratio
    foci=focstr[first:last].focus

    if n_elements(foci) lt 3 then begin
        fail = 1
        print,'Not enough frames to fit'
    endif

    if (fail eq 0) then begin
        if not keyword_set(useratio) then begin
            ;; use fwhm for fit
            plot,foci,fwhms,psym=1,/ynozero
            
            minfwhm = min(fwhms, indices)
            if ((minfwhm gt fwhm_cut) or (indices[0] eq 0) or $
                (indices[0] eq n_elements(fwhms)-1)) then begin
                print,'Best point no good!'
                fail = 1
            endif else begin
                j = indices[0]-1
                while (j gt 0 and fwhms[j] lt fwhm_cut) do begin
                    add_arrval, j, indices
                    j=j-1
                endwhile
                j=indices[0]+1
                while (j lt n_elements(fwhms)-1 and fwhms[j] lt fwhm_cut) do begin
                    add_arrval, j, indices
                    j=j+1
                endwhile
                
                if (n_elements(indices) lt mingd) then begin
                    print,'Not enough good points to fit'
                    ans = ' '
                    read,ans,prompt='Press return or [m]:'
                    if ans eq 'm' then manual = 1
                    fail = 1
                endif else begin
                    oplot,foci[indices],fwhms[indices],psym=7
                    fit=svdfit(foci[indices],fwhms[indices],3,chisq=chisq,/double)
                endelse
            endelse
        endif else begin
            ;; use ratio
            plot,foci,ratios,psym=1,/ynozero
            
            minratio=min(ratios, indices)
            if (minratio gt ratio_cut) then begin
                print,'Best point is no good!'
                fail = 1
            endif else begin
                ;; step left from the minimum
                j=indices[0]-1
                while (j gt 0 and ratios[j] lt ratio_cut) do begin
                    add_arrval,j,indices
                    j=j-1
                endwhile
                j=indices[0]+1
                while (j lt n_elements(ratios)-1 and ratios[j] lt ratio_cut) do begin
                    add_arrval,j,indices
                    j=j+1
                endwhile
                if (n_elements(indices) lt mingd) then begin
                    print,'Not enough good points to fit'
                    fail = 1
                endif else begin
                    oplot,foci[indices],ratios[indices],psym=7
                    fit=svdfit(foci[indices],ratios[indices],3,chisq=chisq)
                endelse
            endelse
        endelse
    endif

        if (fail ne 1) then begin
            xvals = (findgen(100)/100.)*(max(foci)-min(foci)) + min(foci)

            yvals = fit[0] + fit[1]*xvals + fit[2]*(xvals^2)
            oplot,xvals,yvals

            target_y = min(yvals) * (1. + slop)
            a=fit[2]
            b=fit[1]
            c=fit[0] - target_y
            
            radical = sqrt(b^2 - 4*a*c)
            xmin=(-b-radical)/(2.*a)
            xmax=(-b+radical)/(2.*a)
            
            bestfoc = (xmax + xmin) / 2.
            err = (xmax - xmin) / 2.0

            print,'Temp = '+string(best[i].temp,format='(f6.2)') + $ 
                  '  Elev = '+string(best[i].elevation,format='(f6.2)')
            print,'Best Focus = ' + string(bestfoc,format='(f6.3)') + ' +/-'+ $
                  string(err,format='(f6.3)')
            
            if (err lt 0.0) then begin
                print,'Bad fit detected!'
                fail = 1
            endif
        endif
        
        if ((fail eq 0) or manual) then begin
            ans = ' '
            answered = 0
            while (not answered) do begin
                read,ans, $
                     prompt = ' Should this fit be used? [y/n/m]: [y]'
                if (ans eq '' or ans eq 'y' or ans eq 'Y') then begin
                    print,'Using focus sequence: ',best[i].file
                    answered = 1
                endif else if (ans eq 'n' or ans eq 'N') then begin
                    print,'Discarding focus sequence: ', best[i].file
                    answered = 1
                    fail = 1
                endif else if (ans eq 'm' or ans eq 'M') then begin
                    read,ans, $
                         prompt = ' Enter the best focus: '
                    best[i].best_focus = float(ans)
                 ;;   read,ans, $
                 ;;        prompt = ' Enter the error: '
                 ;;   best[i].error = float(ans)
                    best[i].error = 0.02

                    answered = 1
                    if ((best[i].best_focus lt 0) or (best[i].error lt 0)) then begin 
                        fail = 1
                        print,'not using'
                    endif
                endif
            endwhile
        endif

        if (fail eq 0) then begin
            best[i].best_focus = bestfoc
            best[i].error = err
        endif else begin
            best[i].best_focus = -1.0
            best[i].error = -1.0
        endelse

    endfor


    return
end
