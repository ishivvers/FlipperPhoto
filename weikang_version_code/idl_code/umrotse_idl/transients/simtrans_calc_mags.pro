pro simtrans_calc_mags,times,pk,mags,alpha=alpha

if n_params() eq 0 then begin
    print,'syntax- simtrans_calc_mags,times,pk,mags,alpha=alpha'
    return
endif

if n_elements(alpha) eq 0 then alpha = 1.0

pkp=pk-2.5*alpha*alog10(60.)

mags = 2.5 * alpha * alog10(times) + pkp


return
end
