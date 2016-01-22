pro plot_opt_rotse_lc,datfile,over=over,fd=fd,z=z,color=color,nonrotse=nonrotse

if n_params() eq 0 then begin
    print,'syntax- plot_opt_rotse_lc,datfile,over=over,fd=fd,color=color,nonrotse=nonrotse'
    print,'  default is flux'
    return
endif

if n_elements(z) eq 0 then z=0.0


readcol,datfile,tmid,terr,mag,emag,oflux,ofluxm,ofluxp,ofd,ofdm,ofdp,format='f,f,f,f,f,f,f,f,f,f',/silent,comment='#'

tmid=tmid/(z+1.0)
terr=terr/(z+1.0)

if keyword_set(fd) then begin
    yval=ofd
    yval_lo=ofd+ofdm
    yval_hi=ofd+ofdp
    ytitle='Flux Density (Jy)'
endif else begin
    yval=oflux
    yval_lo=oflux+ofluxm
    yval_hi=oflux+ofluxp
    ytitle='Flux (erg/cm^2/s)'
endelse

if not keyword_set(over) then begin
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

    obs=where(yval gt 0 and (tmid-terr) ge xrange[0] and (tmid+terr) le xrange[1] and $
              yval_lo ge yrange[0] and yval_hi le yrange[1],nobs)
    lims=where(yval eq 0 and (tmid-terr) ge xrange[0] and (tmid+terr) le xrange[1] and $
               yval_hi ge yrange[0],nlims)

endelse

a=findgen(17)*(!pi*2/16.)

if keyword_set(nonrotse) then begin
    usersym,cos(a),sin(a)
endif else begin
    usersym,cos(a),sin(a),/fill
endelse

if keyword_set(color) then begin
    colbk=!p.color
    !p.color=!red
endif

oplot,tmid[obs],yval[obs],psym=8

for i=0l,nobs-1 do begin
    plots,[tmid[obs[i]]-terr[obs[i]],tmid[obs[i]]+terr[obs[i]]], $
      [yval[obs[i]],yval[obs[i]]]
    plots,[tmid[obs[i]],tmid[obs[i]]], $
      [yval_lo[obs[i]],yval_hi[obs[i]]]
endfor

;; and plot the limits -- this will need to be changed
if nlims gt 0 then begin
    if (!d.name ne 'X') then hsize=300

    oplot,tmid[lims],yval_hi[lims],psym=8
    
    arrow,tmid[lims],yval_hi[lims],tmid[lims],0.25*yval_hi[lims], $
      /data,thick=!p.thick,hsize=hsize
endif

if keyword_set(color) then !p.color=colbk



return
end
