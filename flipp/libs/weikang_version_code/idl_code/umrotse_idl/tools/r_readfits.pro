function r_readfits,fname,_extra

;; rotse_readfits program
;;  will try to read the image filename, and if that isn't there will try the
;;  gzipped version of the file before returning an error.

;; Created  08/26/03 E. Rykoff
;;

the_fname=fname
openr,lun,the_fname,/get_lun,error=err
if (err ne 0) then begin
    ;; now try the gzipped version
    the_fname = fname + '.gz'
    openr,lun,the_fname,/get_lun,error=err
endif

if (err eq 0) then begin
    free_lun,lun
    im=readfits(the_fname,_extra)
endif else begin
    printf, -2, !err_string
    im = -1
endelse

return,im
end
