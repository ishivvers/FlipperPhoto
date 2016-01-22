function ss_get_fwhm,sobj

;get median fwhm from sobj or cobj file

if n_params() eq 0 then begin
    print,'syntax - fwhm=ss_get_fwhm(sobj)'
    return,''
endif

sob=tag_exist(sobj,'X_IMAGE')

ibit = where(sobj.flags EQ 0,ict)

if (ict gt 0) then begin
    if sob then begin
        gmag = min(sobj[ibit].mag_aper[0])
        usmag = where(sobj[ibit].mag_aper[0] GT gmag AND $ 
                      sobj[ibit].mag_aper[0] LT gmag+3 and $
                      sobj[ibit].x_image gt 700 and sobj[ibit].x_image lt 1300 and $
                      sobj[ibit].y_image gt 700 and sobj[ibit].y_image lt 1300 and $
                      sobj[ibit].fwhm_image lt 10.0, count)
        if (count ge 2) then begin
            new_fwhm = median(sobj[ibit[usmag]].fwhm_image)
        endif else if (count eq 1) then begin
            new_fwhm = sobj[ibit[usmag]].fwhm_image
        endif else begin
            new_fwhm = 0.0
        endelse
    endif else begin
        gmag = min(sobj[ibit].m[0])
        usmag = where(sobj[ibit].m[0] GT gmag AND $ 
                      sobj[ibit].m[0] LT gmag+3 and $
                      sobj[ibit].x gt 700 and sobj[ibit].x lt 1300 and $
                      sobj[ibit].y gt 700 and sobj[ibit].y lt 1300 and $
                      sobj[ibit].fwhm lt 10.0, count)
        if (count ge 2) then begin
            new_fwhm = median(sobj[ibit[usmag]].fwhm)
        endif else if (count eq 1) then begin
            new_fwhm = sobj[ibit[usmag]].fwhm
        endif else begin
            new_fwhm = 0.0
        endelse
    endelse

endif else begin
    new_fwhm = 0.0
endelse

return,new_fwhm

end
