pro rotse_photometry_table,infile,outfile,telname,timesig=timesig,magsig=magsig, $
                           nodeluxe=nodeluxe

if n_params() eq 0 then begin
    print,'syntax- rotse_photometry_table,infile,outfile,telname,timesig=timesig,magsig=magsig,nodeluxe=nodeluxe'
    return
endif

if n_elements(timesig) eq 0 then timesig = 1
if n_elements(magsig) eq 0 then magsig = 2


;; see if it's an rphot file...
rphotfile=0
readcol,infile,tburst,etburst,mag,maglo,maghi,limmag, $
  format='f,f,f,f,f,f',/silent,comment=';'
  
if n_elements(tburst) eq 0 then begin
    print,'Could not find: ',infile
    return
endif

if (tburst[0] ne 0) then begin
    rphotfile=1
endif else begin
    print,'Not an rphot file...trying lightcurve file...'
    readcol,infile,obs,tel,st,en,det,mag,magerr, $
      format='a,i,f,f,i,f,f',/silent
    
    if st[0] eq 0 then begin
        print,'Not a valid file format.'
        return
    endif

    use=where(tel eq tel[0] and obs eq 'obs')
    st=st[use]
    en=en[use]
    det=det[use]
    mag=mag[use]
    magerr=magerr[use]
endelse

;; now prepare the numbers

if (rphotfile) then begin
    tstart=tburst-etburst
    tend=tburst+etburst

    ;; mag is okay
    
    usememag = 1
    memag = mag-maglo
    pemag = maghi-mag

    ;; and the lims
    lims=fltarr(n_elements(tstart))-1
    uselim=where(finite(mag) eq 0 or finite(maglo) eq 0 or finite(maghi) eq 0,ninf)
    if (ninf gt 0) then begin
        lims[uselim] = limmag[uselim]
    endif
endif else begin
    tstart=st
    tend=en
    
    usememag = 0
    emag=magerr
    
    ;; and the lims
    lims=fltarr(n_elements(tstart))-1
    uselim=where(det eq 0,nlim)
    if (nlim gt 0) then begin
        lims[uselim] = mag[uselim]
    endif

endelse

openw,lun,outfile,/get_lun

ncol=3
colcode='lcrrc'

if (not keyword_set(nodeluxe)) then begin
    ;; standard deluxetable
    printf,lun,'\begin{deluxetable}{'+colcode+'}'
    printf,lun,'\tablewidth{0pt}'
    printf,lun,'\tablecaption{Optical Photometry for GRB~??????\label{tab:photometry}}'
    printf,lun,'\tabletypesize{\scriptsize}'
    printf,lun,'\tablehead{'
    printf,lun,'  \colhead{Telescope} &'
    printf,lun,'  \colhead{Filter} &'
    printf,lun,'  \colhead{$t_{\mathrm{start}}$ (s)} &'
    printf,lun,'  \colhead{$t_{\mathrm{end}}$ (s)} &'
    printf,lun,'  \colhead{Magnitude}'
    printf,lun,'}'
    printf,lun,'\startdata'
endif else begin
    ;; non deluxetable
    printf,lun,'\begin{table}[htp] \centering'
    printf,lun,'\begin{tabular}{'+colcode+'}'
    printf,lun,'\hline'
    printf,lun,'Telescope & Filter & $t_{\mathrm{start}}$ (s) & $t_{\mathrm{end}}$ (s) & Magnitude\\'
    printf,lun,'\hline'
endelse


for i=0l,n_elements(tstart)-1 do begin
;;    print,tstart[i],tend[i],mag[i],lims[i]
    line = telname + ' & '
    line = line + 'None & '

    fstr='(f12.'+string(timesig,format='(i1)')+')'
    line = line + string(tstart[i],format=fstr) + ' & ' + $
      string(tend[i],format=fstr) + ' & '
    
    fstr='(f'+string(magsig+3,format='(i1)')+'.'+string(magsig,format='(i1)')+')'
    if (lims[i] gt 0) then begin
        ;; this is a limit
        line = line + '$<'+string(lims[i],format=fstr) +'$'
    endif else if (usememag) then begin
        ;; asymetric
        line = line + '$'+string(mag[i],format=fstr) + $ 
          '^{+' + string(pemag[i],format=fstr) + '}' + $
          '_{-' + string(memag[i],format=fstr) + '}$'
    endif else begin
        ;; symetric
        line = line + '$'+string(mag[i],format=fstr) + $
          '\pm'+string(emag[i],format=fstr)+'$'
    endelse

    line = line + '\\'
   
    printf,lun,line

endfor

if (not keyword_set(nodeluxe)) then begin
    ;; standard deluxetable
    printf,lun,'\enddata'
    printf,lun,'\tablecomments{All times are in seconds since the burst time, XX:XX:XX UT (see \S~\ref{sec:observations})}'

    printf,lun,'\end{deluxetable}'

endif else begin
    ;; non deluxetable
    printf,lun,'\hline'
    printf,lun,'\end{tabular}'
    printf,lun,'\caption[Photometry for GRB~??????]{ROTSE-III optical photometry for GRB~XXXXXX.  All times are in seconds since the burst time, XX:XX:XX UT.\label{tab:label}}'
    printf,lun,'\end{table}'
endelse



free_lun,lun

return
end


