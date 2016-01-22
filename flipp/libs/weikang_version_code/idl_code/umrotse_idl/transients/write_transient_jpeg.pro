pro write_transient_jpeg,tstr,tind,mt,sts,fname_base

if n_params() eq 0 then begin
    print,'syntax- write_transient_jpeg,tstr,tind,mt,sts,fname_base'
    return
endif

tct = n_elements(tstr.templates)

if (tct lt 2) then begin
    print,'Insufficient template observations (should not happen)'
    return
endif
tct = 2 ;; only use the first two if there are more (shouldn't be)

cct = n_elements(tstr.check[tind].iname)
if (cct ne 2) then begin
    print,'wrong number of check observations'
    return
endif

objind = tstr.check[tind].objind


box=0.08

;; output the images
for i=0l,cct-1 do begin
    obsind = tstr.check[tind].obsind[i]

    jpegname = fname_base + '_' + string(i,format='(i1)') + '.jpg'

    h=where((mt.m[obsind,*] gt 0) and $
            (mt.ra gt (mt.ra[objind] - box)) and $
            (mt.ra lt (mt.ra[objind] + box)) and $
            (mt.dec gt (mt.dec[objind] - box)) and $
            (mt.dec lt (mt.dec[objind] + box)),count)
    !p.multi = 0

    parts = strsplit(mt.imagename[obsind],'.fit',/extract)
    caption = [parts[0] + ': ' + string(mt.m_lim[obsind],format='(f4.1)'), $
               'FWHM = ' + string(tstr.check[tind].sfwhm[i],format='(f4.1)') + $
               ' Median FWHM = ' + string(tstr.check[tind].mfwhm[i],format='(f4.1)')]
    
    if (count gt 0) then begin
        radec_circle_new,mt,mt.ra[objind],mt.dec[objind],sts=sts,obs=obsind, $
          jpegname=jpegname,/putfname,dim=[400,400],box=box,rarr1=mt.ra[h], $
          darr1=mt.dec[h],/nolabel,errad=8,caption=caption,radius=10,/finding
    endif else begin
        radec_circle_new,mt,mt.ra[objind],mt.dec[objind],sts=sts,obs=obsind, $
          jpegname=jpegname,/putfname,dim=[400,400],box=box,/noabel, $
          errad=8,caption=caption,radius=10,/finding
    endelse
endfor

;; and output the templates
for i=0l,tct-1 do begin
    jpegname = fname_base + '_' + string(i+2,format='(i1)') + '.jpg'
    
    h=where((tstr.templates[i].c.m gt 0) and $
            (tstr.templates[i].c.ra gt (mt.ra[objind] - box)) and $
            (tstr.templates[i].c.ra lt (mt.ra[objind] + box)) and $
            (tstr.templates[i].c.dec gt (mt.dec[objind] - box)) and $
            (tstr.templates[i].c.dec lt (mt.dec[objind] + box)),count)
    !p.multi = 0
    
    dirparts=strsplit(tstr.templates[i].name,'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'\_c\.fit',/extract,/regex)
    caption = parts[0] + ': ' + string(tstr.templates[i].cal.m_lim,format='(f4.1)')
    
    if (count gt 0) then begin
        radec_circle_new,tstr.templates[i].cal,mt.ra[objind],mt.dec[objind], $
          image=tstr.templates[i].im, jpegname=jpegname, /putfname, $
          dim=[400,400],box=box,rarr1=tstr.templates[i].c[h].ra, $
          darr1=tstr.templates[i].c[h].dec,/nolabel,errad=8, $
          caption=caption,radius=10,/finding
    endif else begin
        radec_circle_new,tstr.templates[i].cal,mt.ra[objind],mt.dec[objind], $
          image=tstr.templates[i].im, jpegname=jpegname, /putfname, $
          dim=[400,400],box=box,/nolabel,errad=8,caption=caption,radius=10, $
          /finding
    endelse

endfor


return
end
