pro plot_bat_xrt_opt,output,batfile,xrtfiles,optfile,fname=fname,fd=fd,xrange=xrange,yrange=yrange,gray=gray,starttime=starttime,z=z,color=color,title=title,nonrotsefile=nonrotsefile,specindfile=specindfile,symsize=symsize

if n_params() eq 0 then begin
    print,'syntax- plot_bat_xrt_opt,output,batfile,xrtfiles,optfile,fname=fname,fd=fd,xrange=xrange,yrange=yrange,gray=gray,startreg=startreg,z=z,starttime=starttime,color=color,title=title,nonrotsefile=nonrotsefile,specindfile=specindfile,symsize=symsize  '
    return
endif

if n_elements(z) eq 0 then z=0.0

if n_elements(title) eq 0 then title = ''
if n_elements(symsize) eq 0 then symsize=1.0

;;setupplot

charsize=1.5 ;; use this?
landscape=1
isps=0
if (output eq 'ps' or output eq 'PS') then begin
    isps = 1
    if n_elements(fname) eq 0 then fname='batxrtopt.ps'

    begplot,name=fname,landscape=landscape,color=color
    device,set_font='Helvetica'

endif else if output eq 'x' or output eq 'X' then begin
    ;; x
    setupplot
endif else begin
    print,'Need output to be ps or x'
    return
endelse

testxrange=[100000.0,-1000000.0]
testyrange=[100000.0,-1000000.0]

;; first need to decide on plotting ranges
if n_elements(batfile) eq 0 then batfile = 'NOTHING'
if n_elements(xrtfiles) eq 0 then xrtfiles = 'NOTHING'
if n_elements(optfile) eq 0 then optfile = 'NOTHING'
if n_elements(nonrotsefile) eq 0 then nonrotsefile = 'NOTHING'

allfiles=[batfile,optfile,nonrotsefile,xrtfiles]
found_arr=bytarr(n_elements(allfiles))

for i=0l,n_elements(allfiles)-1 do begin
    test=findfile(allfiles[i],count=ct)
    if (ct eq 1) then begin
        found_arr[i]=1
        readcol,allfiles[i],tmid,terr,rate,raterr,flux,fluxm,fluxp,xfd,xfdm,xfdp,/silent,comment='#'
        check=where(flux ne 0.0)
        mint=0.8*min(tmid[check]-terr[check])/(1.+z)
        maxt=1.2*max(tmid[check]+terr[check])/(1.+z)
        if (mint lt testxrange[0]) then testxrange[0] = mint
        if (maxt gt testxrange[1]) then testxrange[1] = maxt

        if keyword_set(fd) then begin
            minfd=0.5*min(xfd[check]+xfdm[check])
            maxfd=1.2*max(xfd[check]+xfdp[check])
            if (minfd lt testyrange[0]) then testyrange[0] = minfd
            if (maxfd gt testyrange[1]) then testyrange[1] = maxfd
        endif else begin
            minflux=0.5*min(flux[check]+fluxm[check])
            maxflux=1.2*max(flux[check]+fluxp[check])
            if (minflux lt testyrange[0]) then testyrange[0] = minflux
            if (maxflux gt testyrange[1]) then testyrange[1] = maxflux
            
        endelse
    endif
endfor

if n_elements(starttime) eq 1 then testxrange[0]=starttime

;; and the titles
xtitle='Time Since Burst (s)'
if (keyword_set(fd)) then begin
    ytitle='Flux Density (Jy)'
endif else begin
    ytitle='Flux (erg cm!U-2!N s!U-1!N)'
endelse

if n_elements(xrange) ne 2 then xrange=testxrange
if n_elements(yrange) ne 2 then yrange=testyrange

plot,[0],[0],/nodata,xrange=xrange,yrange=yrange,/xlog,/ylog,/xstyle,/ystyle,xtitle=xtitle,ytitle=ytitle,yminor=9;;,title=title

xyouts,0.93,0.9,title,alignment=1.0,/normal
if (z ne 0.0) then begin
    xyouts,0.93,0.86,'z='+string(z,format='(f4.2)'),alignment=1.0,/normal
endif

;; put on the bat part
if (found_arr[0] eq 1) then begin
    plot_bat_rotse_lc,allfiles[0],/over,fd=fd,gray=gray,z=z,color=color,symsize=symsize
endif

;; and the optical part
if (found_arr[1] eq 1) then begin
    plot_opt_rotse_lc,allfiles[1],/over,fd=fd,z=z,color=color
endif

if (found_arr[2] eq 1) then begin
    plot_opt_rotse_lc,allfiles[2],/over,fd=fd,z=z,color=color,/nonrotse
endif

;; and the xrt part
inds=indgen(n_elements(found_arr))
xrtuse=where(found_arr eq 1 and inds ge 3,nxrtuse)
if (nxrtuse gt 0) then begin
    plot_xrt_rotse_lc,allfiles[xrtuse],/over,fd=fd,z=z,color=color,symsize=symsize
endif

;; and the spectral index stuff
if n_elements(specindfile) eq 1 then begin
    plot_specind_box,specindfile,z=z
endif


if (isps) then endplot,landfix=landscape


return
end
