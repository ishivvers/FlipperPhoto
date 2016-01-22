pro xrt_read_datfile,filename,datstr,fail=fail

if n_params() eq 0 then begin
    print,'syntax- xrt_read_datfile,filename,datstr,fail=fail'
    return
endif

fail=0


openr,lun,filename,/get_lun,error=err
if (err ne 0) then begin
    print,'could not open ',filename,' for reading.'
    fail=1
    return
endif

line=''
datefound=0
while ((datefound eq 0) and (not eof(lun))) do begin
    readf,lun,line,format='(a200)'
    parts=strsplit(line,' ',/extract)
    if (parts[0] eq 'date') then begin
        burstmjd=(julday(fix(parts[2]),fix(parts[3]),fix(parts[1]), $
                         fix(parts[4]),fix(parts[5]),float(parts[6]))-2400000.5d)[0]
        datefound = 1
    endif
endwhile

if (datefound eq 0) then begin
    print,'date not found'
    fail=1
    return
endif



;; now look for the mode in question
while (not eof(lun)) do begin
    readf,lun,line,format='(a200)'
    parts=strsplit(line,' ',/extract)
    if ((parts[0] eq 'pc') or (parts[0] eq 'wt') or (parts[0] eq 'bat') or (parts[0] eq 'pu')) then begin
        if (n_elements(parts) lt 3) then begin
            print,'mode line illegal: ',line
            fail=1
            return
        endif


        elt=create_struct('burstmjd',0d, $
                          'mode','', $
                          'tstart',0.0, $
                          'tstop',0.0, $
                          'ct',0.0, $
                          'cterr',0.0, $
                          'gamma',0.0, $
                          'gammalo',0.0, $
                          'gammahi',0.0, $
                          'norm',0.0, $
                          'normlo',0.0, $
                          'normhi',0.0, $
                          'epeak',-1.0, $
                          'epeaklo',0.0, $
                          'epeakhi',0.0,$
                          'alpha',0.0, $
                          'alphalo',0.0,$
                          'alphahi',0.0,$                  
                          'beta',0.0, $
                          'betalo',0.0,$
                          'betahi',0.0,$
                          'e_p',0.0,$
                          'enlo',0.0, $
                          'enhi',0.0, $
                          'xgamma',0.0)



        elt.burstmjd = burstmjd
        elt.mode = parts[0]
        elt.tstart = float(parts[1])
        elt.tstop = float(parts[2])
        
        foundall = 0
        foundall_grbm = 0
        i=0
;;        while (foundall lt 7 and i lt 5) do begin
;;        for i=0l,2 do begin
;;        for i=0l,4 do begin
        while ((foundall lt 7) and (foundall_grbm lt 63) and i lt 10) do begin
            readf,lun,line,format='(a200)'
            parts=strsplit(line,' ',/extract)
            if (parts[0] eq 'ct') then begin
                if n_elements(parts) lt 3 then begin
                    print,'ct line illegal: ',line
                    fail=1
                    return
                endif
                elt.ct = float(parts[1])
                elt.cterr=float(parts[2])
                foundall=(foundall or 1)
                foundall_grbm=(foundall_grbm or 1)
            endif else if (parts[0] eq 'gamma') then begin
                if n_elements(parts) eq 3 then begin
                    elt.gamma=float(parts[1])
                    elt.gammalo=elt.gamma-float(parts[2])
                    elt.gammahi=elt.gamma+float(parts[2])
                endif else if (n_elements(parts) eq 4) then begin
                    elt.gamma=float(parts[1])
                    elt.gammalo=float(parts[2])
                    elt.gammahi=float(parts[3])
                endif else begin
                    print,'gamma line illegal: ',line
                    fail=1
                    return
                endelse
                
                foundall = (foundall or 2)
            endif else if (parts[0] eq 'norm') then begin
                if n_elements(parts) eq 3 then begin
                    elt.norm=float(parts[1])
                    elt.normlo=elt.norm-float(parts[2])
                    elt.normhi=elt.norm+float(parts[2])
                endif else if (n_elements(parts) eq 4) then begin
                    elt.norm = float(parts[1])
                    elt.normlo = float(parts[2])
                    elt.normhi = float(parts[3])
                endif else begin
                    print,'norm line illegal: ',line
                    fail=1
                    return
                endelse
                foundall = (foundall or 4)
                foundall_grbm = (foundall_grbm or 2)
            endif else if (parts[0] eq 'alpha') then begin
                if n_elements(parts) lt 4 then begin
                    print,'alpha line illegal: ',line
                    fail=1
                    return
                endif
                elt.alpha = float(parts[1])
                elt.alphalo = float(parts[2])
                elt.alphahi = float(parts[3])
                foundall_grbm=(foundall_grbm or 4)
            endif else if (parts[0] eq 'beta') then begin
                if n_elements(parts) lt 4 then begin
                    print,'beta line illegal: ',line
                    fail=1
                    return
                endif
                elt.beta = float(parts[1])
                elt.betalo = float(parts[2])
                elt.betahi = float(parts[3])
                foundall_grbm=(foundall_grbm or 8)
            endif else if (parts[0] eq 'epeak') then begin
                if n_elements(parts) lt 4 then begin
                    print,'epeak line illegal: ',line
                    fail=1
                    return
                endif
                elt.epeak = float(parts[1])
                elt.epeaklo = float(parts[2])
                elt.epeakhi = float(parts[3])
                foundall_grbm=(foundall_grbm or 16)
            endif else if (parts[0] eq 'e_p') then begin
                if n_elements(parts) lt 2 then begin
                    print,'e_p line illegal: ',line
                    fail=1
                    return
                endif
                elt.e_p = float(parts[1])
                foundall_grbm=(foundall_grbm or 32)
            endif else if (parts[0] eq 'en') then begin
                if n_elements(parts) eq 3 then begin
                    print,'energy!'
                    elt.enlo = float(parts[1])
                    elt.enhi = float(parts[2])
                endif else begin
                    print,'en line illegal: ',line
                    fail=1
                    return
                endelse
            endif else if (parts[0] eq 'xgamma') then begin
                if n_elements(parts) eq 2 then begin
                    elt.xgamma=float(parts[1])
                endif else begin
                    print,'xgamma line illegal: ',line
                    fail=1
                    return
                endelse
            endif else begin
                print,'unexpected line: ',line
                fail=1
                return
            endelse
;;        endfor
            i=i+1
        endwhile
        if (foundall ne 7) and (foundall_grbm ne 63) then begin
            print,'mode lines incomplete'
            fail =1
            return
        endif

        ;; if we have an energy, we need to convert
        ;; DON'T CONVERT
;;        if (elt.enlo gt 0 and elt.enhi gt 0) then begin
;;            if (elt.enlo eq elt.enhi) then begin
;;                print,'not implemented yet: enlo=enhi'
;;                fail=1
;;                return
;;            endif else begin
;;                beta=1.-elt.gamma
;;                betap1=beta+1.
;;                conv=(betap1/1.6d3)*(1./(elt.enhi^betap1-elt.enlo^betap1))
;;                elt.norm=elt.norm*conv
;;                elt.normlo=elt.normlo*conv
;;                elt.normhi=elt.normhi*conv
        ;;           endelse
        ;;endif  endif
;;        help,elt,/str
        add_arrval,elt,tempdatstr

    endif
endwhile

free_lun,lun

datstr=tempdatstr




return
end
