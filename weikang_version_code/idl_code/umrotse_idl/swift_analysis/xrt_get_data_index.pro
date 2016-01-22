pro xrt_get_data_index,datstr,srcevts,mode,tstart,tstop,index,fail=fail

if n_params() eq 0 then begin
    print,'syntax- xrt_get_data_index,datstr,srcevts,mode,tstart,tstop,index,fail=fail'
    return
endif

fail=0

;; if there's more than one, we need to make a new "fake" element
if n_elements(srcevts) gt 1 then begin

    durations=fltarr(n_elements(datstr))-1.
    
    for i=0l,n_elements(srcevts)-1 do begin
        parts=strsplit(srcevts[i],'-',/extract)
        tstart_evt=long(parts[2])
        tstop_evt=long(parts[3])
        
        use=where(datstr.mode eq mode and $
                  datstr.tstart eq tstart_evt and $
                  datstr.tstop eq tstop_evt,nuse)
        
        if (nuse ne 0) then begin
            gti=mrdfits(srcevts[i],2)
            durations[use]=total(gti.stop-gti.start)
        endif
    endfor

    use=where(durations gt 0,nuse)
    if (nuse eq 0) then begin
        print,'No matching source events found'
        fail = 1
        return
    endif

;;    if (tstart ne min(datstr[use].tstart) or $
;;        tstop ne max(datstr[use].tstop)) then begin
;;        print,'Tstart/tstop mismatch'
;;        fail=1
;;        return
;;    endif

    new_elt=datstr[use[0]]
    ;; gamma, gammalo, gammahi, mode are correct
    ;; set the start and stop times of the new element
    new_elt.tstart = min(datstr[use].tstart)
    new_elt.tstop = max(datstr[use].tstop)
    new_elt.ct=total(datstr[use].ct*durations[use])/total(durations[use])
    ;; probably should weight this, but eh.
    new_elt.cterr=sqrt(total((datstr[use].cterr/datstr[use].ct)^2.))*new_elt.ct

    add_arrval,new_elt,datstr

endif

use=where(datstr.mode eq mode and $
          long(datstr.tstart) eq tstart and $
          long(datstr.tstop) eq tstop,nuse)
if (nuse eq 0) then begin
    print,'No matching element found'
    fail=1
    index=-1
endif else begin
    index=use[0]
endelse


return
end
