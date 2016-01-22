pro focus_from_filebase,file,hdr_ending,focstr,bestfoc,err,temp,elev,az,slop=slop

if n_params() eq 0 then begin
    print,'syntax- focus_from_filebase,file,hdr_ending,focstr,bestfoc,err,temp,elev,az,slop=slop'
    return
endif

if n_elements(slop) eq 0 then begin
    slop=0.01
endif

elt = create_struct('focus',0.0,'fwhm',0.0)

; First we need to find our files...

filebits = 'image/' + file + '???' + hdr_ending
sobjbits = 'prod/' + file + '*' + 'sobj.fit'

hdrs = findfile(filebits)
sobjs = findfile(sobjbits)

if n_elements(hdrs) ne n_elements(sobjs) then begin
    print,'Mismatch on hdr, sobj'
    return
endif

numfocs = n_elements(hdrs)

err = 0.0
temptotal = 0.0
elevtotal = 0.0
aztotal = 0.0
i=0l

for i=0l,numfocs-1 do begin
    hdr=headfits(hdrs[i])
    sobj=mrdfits(sobjs[i],1)

    if (size(sobj,/type) eq 8) then begin
        h=where((sobj.flags and 4) ne 4, count)
        if (count gt 0) then begin
            satmag = min(sobj[h].mag_aper)
            
            k=where(sobj[h].mag_aper gt satmag + 2.0)
            medfwhm = median(sobj[h[k]].fwhm_image)

            elt.focus = sxpar(hdr,"FOCUS",count=count)
            elt.fwhm = medfwhm
            temptotal = temptotal + sxpar(hdr,"TEMPOUT")
            elevtotal = elevtotal + sxpar(hdr,"ELEV")
            aztotal = aztotal + sxpar(hdr,"AZIMUTH")

            add_arrval, elt, fs

        endif else numfocs = numfocs - 1
    endif else begin
        numfocs = numfocs - 1
    endelse

endfor

focstr = fs

temp = temptotal / numfocs
elev = elevtotal / numfocs
az = aztotal / numfocs




;Finally, finding the best...


plot,focstr.focus,focstr.fwhm,psym=1,/ynozero


h=where(focstr.fwhm lt 6 and focstr.fwhm gt 0)
oplot,focstr[h].focus,focstr[h].fwhm,psym=7
fit=svdfit(focstr[h].focus,focstr[h].fwhm,3)

xvals=findgen(100)/100.+3.
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
print,'file = ', file
print,'Temp = ',temp,' elev = ',elev,'  best focus = ',bestfoc,' +/- ',err


r=get_kbrd(10)


return
end
