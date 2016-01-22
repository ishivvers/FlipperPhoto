pro plot_xrt_rotse_lc,datfiles,over=over,fd=fd,z=z,color=color,symsize=symsize

if n_params() eq 0 then begin
    print,'syntax- plot_xrt_rotse_lc,datfiles,over=over,fd=fd,z=z,color=color'
    print,'  default is flux'
    return
endif

if n_elements(z) eq 0 then z = 0.0

psym=6
if keyword_set(color) then psym=3


for i=0,n_elements(datfiles)-1 do begin
    readcol,datfiles[i],tmidtemp,terrtemp,cttemp,cterrtemp,fluxtemp,fluxmtemp,fluxptemp,fdtemp,fdmtemp,fdptemp,format='f,f,f,f,f,f,f,f,f,f',comment='#',/silent
    add_arrval,tmidtemp,tmid
    add_arrval,terrtemp,terr
    add_arrval,cttemp,ct
    add_arrval,cterrtemp,cterr
    add_arrval,fluxtemp,flux
    add_arrval,fluxmtemp,fluxm
    add_arrval,fluxptemp,fluxp
    add_arrval,fdtemp,xfd
    add_arrval,fdmtemp,xfdm
    add_arrval,fdptemp,xfdp
endfor

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

;;yerr=yval*(cterr/ct)

if not keyword_set(over) then begin
    ;; prepare the plot
    
    obs=where(yval gt 0,nobs)
    lims=where(yval eq 0,nlims)
    
    xrange=[min(tmid-terr),max(tmid+terr)]
    yrange=[min(yval_lo[obs]),max(yval_hi[obs])]

    plot,[0],[0],/nodata,xrange=xrange,yrange=yrange,/xlog,/ylog, $
      xtitle='Time Since Burst (s)',ytitle=ytitle

endif else begin
    res1=convert_coord(!p.clip[0],!p.clip[1],/device,/to_data)
    res2=convert_coord(!p.clip[2],!p.clip[3],/device,/to_data)
    xrange=[res1[0],res2[0]]
    yrange=[res1[1],res2[1]]

    obs=where(yval gt 0 and tmid-terr ge xrange[0] and tmid+terr le xrange[1] and $
              yval_lo ge yrange[0] and yval_hi le yrange[1],nobs)
    lims=where(yval eq 0 and tmid-terr ge xrange[0] and tmid+terr le xrange[1] and $
               yval_hi gt yrange[0],nlims)
endelse

if keyword_set(color) then begin
    colbk=!p.color
    !p.color=!magenta
endif

oplot,tmid[obs],yval[obs],psym=psym,symsize=symsize

for i=0l,nobs-1 do begin
    plots,[tmid[obs[i]]-terr[obs[i]],tmid[obs[i]]+terr[obs[i]]], $
      [yval[obs[i]],yval[obs[i]]]
    plots,[tmid[obs[i]],tmid[obs[i]]], $
      [yval_lo[obs[i]],yval_hi[obs[i]]]
endfor

;; and plot the limits
if nlims gt 0 then begin
    if (!d.name ne 'X') then begin
        hsize=300
    endif

    oplot,tmid[lims],yval_hi[lims],psym=psym,symsize=symsize

    arrow,tmid[lims],yval_hi[lims],tmid[lims],0.25*yval_hi[lims], $
      /data,thick=!p.thick,hsize=hsize

endif

if keyword_set(color) then !p.color=colbk



return
end

