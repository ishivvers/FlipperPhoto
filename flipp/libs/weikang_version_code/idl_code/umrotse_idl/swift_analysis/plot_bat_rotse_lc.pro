pro plot_bat_rotse_lc,datfile,over=over,fd=fd,gray=gray,z=z,color=color,symsize=symsize

if n_params() eq 0 then begin
    print,'syntax- plot_bat_rotse_lc,datfile,over=over,fd=fd,gray=gray,z=z,color=color,symsize=symsize'
    print,'  default is flux'
    return
endif

if n_elements(z) eq 0 then z=0.0

psym=5
if keyword_set(color) then psym=3

readcol,datfile,tmid,terr,rate,raterr,flux,fluxm,fluxp,xfd,xfdm,xfdp,/silent,comment='#'

tmid=tmid/(1.+z)
terr=terr/(1.+z)

if keyword_set(fd) then begin
    yval = xfd
    yval_lo = xfd + xfdm
    yval_hi = xfd + xfdp
    ytitle='Flux Density (Jy)'
endif else begin
    yval = flux
    yval_lo = flux + fluxm
    yval_hi = flux + fluxp
    ytitle='Flux (erg/cm^2/s)'
endelse

yerr=yval*(raterr/rate)

if not keyword_set(over) then begin
    ;; prepare the plot

    obs=where(yval gt 0,nobs)
    lims=where(yval eq 0,nlims)
    nfirstobs=0

    xrange=[min(tmid-terr),max(tmid+terr)]
    yrange=[min(yval_lo[obs]),max(yval_hi[obs])]

    plot,[0],[0],/nodata,xrange=xrange,yrange=yrange,/ylog,xtitle='Time Since Burst (s)',ytitle=ytitle

endif else begin
    res1=convert_coord(!p.clip[0],!p.clip[1],/device,/to_data)
    res2=convert_coord(!p.clip[2],!p.clip[3],/device,/to_data)
    xrange=[res1[0],res2[0]]
    yrange=[res1[1],res2[1]]

    obs=where(yval gt 0 and tmid-terr ge xrange[0] and tmid+terr le xrange[1] and $
              yval_lo ge yrange[0] and yval_hi le yrange[1],nobs)
    lims=where(yval eq 0 and tmid-terr ge xrange[0] and tmid+terr le xrange[1] and $
               yval_hi ge yrange[0],nlims)

    firstobs=where(yval gt 0 and tmid-terr lt xrange[0]*1.1 and $
                   tmid+terr gt xrange[0]*1.1 and yval_lo ge yrange[0] and $
                   yval_hi le yrange[1],nfirstobs)

endelse


if (nobs gt 0) then begin

    if keyword_set(gray) then begin
 
        if nfirstobs eq 1 then begin
            xstart=xrange[0]*1.02
            ystarthi=yval_hi[firstobs]
            ystartlo=yval_lo[firstobs]
        endif else begin
            xstart=tmid[obs[0]]-terr[obs[0]]
            ystarthi=yval_hi[obs[0]]
            ystartlo=yval_lo[obs[0]]
        endelse


        poly_x=[xstart,tmid[obs],tmid[obs[nobs-1]]+terr[obs[nobs-1]],tmid[obs[nobs-1]]+terr[obs[nobs-1]],reverse(tmid[obs]),tmid[obs[0]]-terr[obs[0]],xstart]
        poly_y=[ystarthi,yval_hi[obs],yval_hi[obs[nobs-1]],yval_lo[obs[nobs-1]],reverse(yval_lo[obs]),ystartlo,ystartlo,ystarthi]
        
        if (!d.name eq 'X') then begin
            col=50l+50l*256l+50l*256l*256l
        endif else begin
            col = 220L
        endelse
        
        polyfill,poly_x,poly_y,/data,color=col
        
        ;; use the ctrate errors for the points

        if keyword_set(color) then begin
            colbk=!p.color
            !p.color = !blue
        endif
        oploterror,tmid[obs],yval[obs],terr[obs],yerr[obs],psym=psym,/nohat,symsize=symsize

        if nfirstobs eq 1 then begin
            ;; get in the first observation...
            ;; we need to check if the first data point is off the left of the
            ;; plot.  If it is, then put the vertical line at the xrange?
            if tmid[firstobs] lt xrange[0] then begin
                tmidtoplot = xrange[0]*1.1 ;; maybe modify
            endif else begin
                tmidtoplot = tmid[0]
            endelse
            
;;            oploterror,[tmidtoplot],[yval[firstobs]],[terr[firstobs]],[yerr[firstobs]],psym=psym,/nohat
            plots,tmidtoplot,yval[firstobs],psym=psym
            plots,[xrange[0]*1.01,tmid[firstobs]+terr[firstobs]],[yval[firstobs],yval[firstobs]]
            plots,[tmidtoplot,tmidtoplot],[yval[firstobs]-yerr[firstobs],yval[firstobs]+yerr[firstobs]]

        endif


        if keyword_set(color) then !p.color=colbk
        
    endif else begin
        ;; use the asymmetric y errors for the points
        
        if keyword_set(color) then begin
            colbk=!p.color
            !p.color=!blue
        endif

        oplot,tmid[obs],yval[obs],psym=psym,symsize=symsize
        for i=0l,nobs-1 do begin
            plots,[tmid[obs[i]]-terr[obs[i]],tmid[obs[i]]+terr[obs[i]]], $
              [yval[obs[i]],yval[obs[i]]]
            plots,[tmid[obs[i]],tmid[obs[i]]], $
                  [yval_lo[obs[i]],yval_hi[obs[i]]]
        endfor

        ;; and the first obs
        if nfirstobs eq 1 then begin
            if tmid[firstobs] lt xrange[0] then begin
                tmidtoplot = xrange[0]*1.1
            endif else begin
                tmidtoplot = tmid[0]
            endelse


            plots,tmidtoplot,yval[firstobs],psym=psym
            plots,[xrange[0]*1.01,tmid[firstobs]+terr[firstobs]],[yval[firstobs],yval[firstobs]]
            plots,[tmidtoplot,tmidtoplot],[yval[firstobs]-yerr[firstobs],yval[firstobs]+yerr[firstobs]]
        endif


        if keyword_set(color) then !p.color = colbk

    endelse

endif

;; and plot the limits
if nlims gt 0 then begin
    if (!d.name ne 'X') then begin
        hsize=300
    endif

    if keyword_set(color) then begin
        colbk=!p.color
        !p.color=!blue
    endif

    oplot,tmid[lims],yval_hi[lims],psym=psym,symsize=symsize

    arrow,tmid[lims],yval_hi[lims],tmid[lims],0.25*yval_hi[lims], $
      /data,thick=!p.thick,hsize=hsize

    if keyword_set(color) then !p.color=colbk

endif

;; and replot the y axis
axis,xrange[0],yrange[0],yax=0,/ylog,yminor=9,/ystyle,ytickname=[' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ']


return
end

