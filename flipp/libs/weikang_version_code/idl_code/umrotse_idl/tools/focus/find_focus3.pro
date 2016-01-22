pro find_focus3,hdrlist,best,slop=slop

if n_params() eq 0 then begin
    print,'syntax- find_focus3,hdrlist,best,slop=slop'
    return
endif

focus_elev_init,hdrlist,best,elev_arr,hdr_ending



for i=0l,n_elements(best)-1 do begin
    print,i,best[i].file
    focus_from_filebase,best[i].file,hdr_ending,fs,foc,err,temp,elev,az,slop=slop

    best[i].best_focus = foc
    best[i].error = err
    best[i].temp = temp
    best[i].elev = elev
    best[i].az = az

endfor



focus_fixed_elevs,best,elev_arr,ms,mi





return
end
