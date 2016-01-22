pro check_true_nondetection,tstr,mt,appendobs,gdobj,nsig=nsig,satlev=satlev,dmag=dmag,fwhmratio=fwhmratio,count=count

if n_params() lt 3 then begin
    print,'syntax- check_true_nondetection,tstr,mt,appendobs,gdobj,nsig=nsig,satlev=satlev,dmag=dmag,fwhmratio=fwhmratio,count=count'
    return
endif

;;if n_elements(nsig) eq 0 then nsig = 5.0
if n_elements(nsig) eq 0 then nsig = 20.0
if n_elements(satlev) eq 0 then satlev = 30000.0
if n_elements(dmag) eq 0 then dmag = 1.0
if n_elements(fwhmratio) eq 0 then fwhmratio = 2.0


gdobj_arr = bytarr(n_elements(tstr.check)) + 1b
tct = n_elements(tstr.templates)
if (tct lt 2) then begin
    print,'Not enough templates'
    gdobj=-1
    count=0
    return
endif

;; if > 2 then set to 2
tct = 2

print,n_elements(tstr.check)

for i=0l,n_elements(tstr.check)-1 do begin
    obj = tstr.check[i].objind

    ;; look for any fwhm anomolies

    box=0.3
    nobs=n_elements(tstr.check[i].obsind)
    sfwhm=fltarr(nobs)+1.0
    mfwhm=fltarr(nobs)+1.0
    deblend = 0
    for j=0l,nobs-1 do begin
        c=mrdfits(tstr.check[i].cname[j],1)
        close_match_radec,mt.ra[obj],mt.dec[obj],c.ra,c.dec,m1,m2,0.0009d,1,/silent

        if (not tag_exist(c,'fwhm')) then m2[0] = -1 ;; don't check

        if (m2[0] ne -1) then begin

            if (c[m2].x gt 10 and c[m2].x lt 2038 and c[m2].y gt 10 and c[m2].y lt 2038 and c[m2].flags eq 0) then begin
                ;; needs to be in range, and not a deblend
                nb=where(c.ra gt mt.ra[obj]-box and $
                         c.ra lt mt.ra[obj]+box and $
                         c.dec gt mt.dec[obj]-box and $
                         c.dec lt mt.dec[obj]+box, nct);; and $
;;                         c.flags eq 0,nct)
                if (c[m2].flags eq 2) then deblend = 1
                if (nct gt 5) then begin

                    mfwhm[j] = median(c[nb].fwhm)
                    sfwhm[j] = c[m2].fwhm

                    tstr.check[i].sfwhm[j] = sfwhm[j]
                    tstr.check[i].mfwhm[j] = mfwhm[j]
                endif
            endif

            if (tstr.check[i].sfwhm[j] eq 0.0) then tstr.check[i].sfwhm[j] = c[m2].fwhm

        endif

    endfor
    

    if (((sfwhm[0] / mfwhm[0]) gt fwhmratio) and $
        ((sfwhm[1] / mfwhm[1]) gt fwhmratio) and $
        (not deblend)) then begin
        ;; this is bad
        print,'fwhms', sfwhm[0],mfwhm[0],sfwhm[1],mfwhm[1]
        gdobj_arr[i] = 0
    endif else begin
        ;; or, if that's okay, check the images

        if (tct eq 0) then begin
            ;; no template images, should it pass?
            gdobj_arr[i] = 0
            
        endif else begin
            sig11 = fltarr(tct)
            ismatch=intarr(2)
            for j=0l,tct-1 do begin
                astr_struct_new,1.85,astr
                kx=tstr.templates[j].cal.kx
                ky=tstr.templates[j].cal.ky
                astr.crval=[double(tstr.templates[j].cal.rac),double(tstr.templates[j].cal.decc)]
                rd2xy,mt.ra[obj],mt.dec[obj],astr,xc,yc
                kmap,xc,yc,xx,yy,kx,ky
                xx=xx[0]
                yy=yy[0]
                
                if (xx - 5 gt 0 and xx + 5 lt 2045 and yy - 5 gt 0 and yy + 5 lt 2048) then begin
                    skyxmin = xx - 50
                    skyxmax = xx + 50
                    skyymin = yy - 50
                    skyymax = yy + 50
                    
                    if (skyxmin lt 0) then skyxmin = 0
                    if (skyxmax gt 2044) then skyxmax = 2044
                    if (skyymin lt 0) then skyymin = 0
                    if (skyymax gt 2048) then skyymax = 2048
                    
                    sky,tstr.templates[j].im[skyxmin:skyxmax,skyymin:skyymax],mn,std
                    
                    box11=tstr.templates[j].im[xx-1:xx+1,yy-1:yy+1]
                    
                    sig11[j] = (median(box11) - mn) / std

                    neighb=where((tstr.templates[j].c.x gt xx-150) and $
                                 (tstr.templates[j].c.x lt xx+150) and $
                                 (tstr.templates[j].c.y gt yy-150) and $
                                 (tstr.templates[j].c.y lt yy+150) and $
                                 (tstr.templates[j].c.flags eq 0) and $
                                 (tstr.templates[j].c.m lt 16.0),nneighb)

                    if (nneighb gt 3) then begin
                        xvals = [xx, tstr.templates[j].c[neighb].x]
                        yvals = [yy, tstr.templates[j].c[neighb].y]

                        aper,tstr.templates[j].im,xvals,yvals,mags,magerrs,sky,skyerr,0.3333,2.5,[2.5,10],[-10000.,64000.0],/silent
                        
                        testmag = mags[0]
                        othermags = mags[1:n_elements(mags)-1]

                        tocomp=where(othermags lt 21.0,ntocomp)

                        if (ntocomp gt 3) then begin

                            compmags = tstr.templates[j].c[neighb[tocomp]].m
                            
                            offset = median(tstr.templates[j].c[neighb[tocomp]].m - othermags[tocomp])

                            ourmag = testmag + offset

                            print,'magcompare:', ourmag,mt.mavg[obj]
                        endif else begin
                            ourmag = 100.0
                        endelse

                    endif else begin
                        ourmag = mt.mavg[obj]
                    endelse

                    if ((max(box11) gt satlev) or $
                        ((ourmag gt mt.mavg[obj] - dmag) and $
                         (ourmag lt mt.mavg[obj] + dmag))) then $
                      ismatch[j] = 1

                    if (ismatch[j] eq 0) then begin
                        close_match_radec,mt.ra[obj],mt.dec[obj],tstr.templates[j].c.ra,tstr.templates[j].c.dec,m1,m2,0.0009d*2,1,/silent
                        if (m2 ne -1) then begin
;;                            if ((tstr.templates[j].c[m2].m gt mt.mavg[obj] - dmag) and $
;;                                (tstr.templates[j].c[m2].m lt mt.mavg[obj] + dmag)) then $
                            ismatch[j] = 1
                        endif
                    endif

                endif else begin
                    ;; we're off the edge, that counts as a match
                    ismatch[j] = 1
                endelse
            endfor

            ;; only guys that fail on both templates get rejected
            if (ismatch[0] and ismatch[1]) then gdobj_arr[i] = 0
            if ((sig11[0] gt nsig) and (sig11[1] gt nsig)) then gdobj_arr[i] = 0

        endelse
    endelse
endfor

temp=where(gdobj_arr eq 1,tcnt)
if (tcnt eq 0) then begin
    gdobj = -1
    count = 0
endif else begin
    ;; return the match indices
    gdobj = tstr.check[temp].objind
    count = tcnt
  
    ;; and crop the tstr (this one works)
    tstr_orig = tstr
    
    tstr=create_struct('templates',tstr_orig.templates, $
                       'check',tstr_orig.check[temp])

endelse



return
end
