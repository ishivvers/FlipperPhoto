pro find_this_phase,jds,mags,mag_errs,freq,chisq,fname=fname,knots=knots,plot=plot,wait=wait,maxfreq=maxfreq,nomean=nomean,freq_arr=freq_arr,chisq_arr=chisq_arr

if n_params() eq 0 then begin
    print,'syntax- find_this_phase,jds,mags,mag_errs,freq,chisq,fname=fname,knots=knots,plot=plot,wait=wait,maxfreq=maxfreq,nomean=nomean'
    return
endif

if n_elements(fname) eq 0 then begin
    fname='templc'
endif

if n_elements(knots) eq 0 then begin
    knots = 4
endif

full_filename = fname + '.dat'

write_lightcurve,jds,mags,mag_errs,filename=full_filename,nomean=nomean

if n_elements(maxfreq) eq 0 then begin
    maxfreq = 10.0
endif

find_freq_cmd = 'find_freq ' + fname + ' ' + string(maxfreq) + ' ' + string(knots)
spawn,find_freq_cmd,output

; parse the output. The table starts on line 9 and ends 3 from the bottom
if (n_elements(output) ge 11) then begin
    chisq_arr = fltarr(15)
    freq_arr = fltarr(15)
    for line=8,n_elements(output)-3 do begin
        reads,output[line],num,cs,fr
        chisq_arr[num-1]=cs
        freq_arr[num-1]=fr
    endfor

    freq_a = freq_arr[0]
    chisq_a = chisq_arr[0]
    freq_b = freq_arr[1]
    chisq_b = freq_arr[1]

    tolerance = 0.05 * (2 * freq_a)
    if ((freq_b gt (2 * freq_a - tolerance)) and (freq_b lt (2 * freq_a + tolerance))) then begin
        freq = freq_b
        chisq = chisq_b
    endif else begin
        freq = freq_a
        chisq = chisq_a
    endelse

    if keyword_set(plot) then begin
        phase_and_plot,fname,freq,knots,wait=wait
    endif

endif else begin
    print,'find_freq could not find a period'
    freq = -1.0
    chisq = -1.0
endelse

return
end

