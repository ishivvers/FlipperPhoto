pro get_usno_dat,file,a2=a2,limmag=limmag

;; reads in the USNO B1.0 text file and outputs a format for use in
;; RPHOT zeropoint calibration

if n_elements(limmag) eq 0 then limmag=99

readlines,file,lines
n=n_elements(lines)
skip=26
ras=dblarr(n-skip)
decs=dblarr(n-skip)
mags=fltarr(n-skip)
for i=skip,n-1 do begin
    sra=strmid(lines[i],14,13)
    sdec=strmid(lines[i],28,13)
    ras[i-skip]=ten(strsplit(sra,' ',/extract))*15.0
    decs[i-skip]=ten(strsplit(sdec,' ',/extract))

    if keyword_set(a2) then begin
        mags[i-skip]=strmid(lines[i],73,6)
    endif else begin
        mags[i-skip]=strmid(lines[i],174,6)
    endelse

endfor
w=where(mags ne 0 and mags lt limmag,nw)
mags=mags[w]
ras=ras[w]
decs=decs[w]

emag=0.01

if keyword_set(a2) then openw,lun,'usnoa2.dat',/get_lun else openw,lun,'usnob.dat',/get_lun
printf,lun,';;R2'
printf,lun,';;        RA         DEC    Rmag   emag'
for i=0,nw-1 do printf,lun,ras[i],decs[i],mags[i],emag,format='(d,d,f,f)'
close,lun
free_lun,lun


end
