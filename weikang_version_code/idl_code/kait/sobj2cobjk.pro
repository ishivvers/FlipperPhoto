pro sobj2cobjk,sobjfile,pixscale=pixscale,tel=tel

if n_params() eq 0 then begin
  print,'syntax- sobj2cobjk,sobjfile,pixscale=pixscale'
  print,'tel options : KAIT, LOT, SP104 (104cm Sampur. Tel), Nickel'
  return
endif

;make image names st
image_name_trans,sobjfile,imagest
;calibrate the sobjlist
print,'Beginning sobjfile '+imagest.sobj

;read in the head from cimage
chdr=headfits(imagest.cimg)
;read in the sobj structure from sobj file
sobj=mrdfits(imagest.sobj,1,/silent)

if not keyword_set(tel) then begin
  tel='KAIT'
  pixscale=0.7965
endif

if tel eq 'LOT' then pixscale=0.86136  ; this is for LOT
if tel eq 'SP104' then pixscale=0.75743  ; this is for SP104
if tel eq 'Nickel' then pixscale=0.37000  ; this is for Nickel

;try to get kait parameters if not given in the key word
shdr=chdr
if n_elements(pixscale) eq 0 and n_elements(tel) eq 0 then begin
  if (sxpar(shdr,'PIXSCALE') ne 0) then begin
    pixscale=sxpar(shdr,'PIXSCALE')
  endif else begin
    pixscale=0.7965   ; this is for kait, FLI MicroLine 512 CCD
  endelse
endif

sobj_usno_calk,chdr,sobj,ucat,ucal,ustat,fail=fail,/readusno

if (not fail) then begin
  write_cobjk, imagest, ustat, ucal, chdr, pixscale=pixscale,tel=tel
  print, 'Sobjfile '+imagest.sobj+' finished.'
  return
endif


end
