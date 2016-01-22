pro plot_bat_lc,output,lcfile,rotsefile,xrange=xrange,title=title,_extra=e

if n_params() eq 0 then begin
    print,'syntax- plot_bat_lc,output,lcfile,rotsefile,xrange=xrange,title=title'
    return
endif

setupplot

isps = 0


if output eq 'ps' or output eq 'PS' then begin
    isps = 1
    
    begplot,name='batcounts.ps',/landscape
endif else if output eq 'x' or output eq 'X' then begin
    ;; x stuff

endif else begin
    print,'Need output to be ps or x'
    return
endelse




hdr=headfits(lcfile)
lc=mrdfits(lcfile,1)

readcol,rotsefile,year,month,day,hour,minute,second,format='i,i,i,i,i,f'
burstmjd=(julday(month,day,year,hour,minute,second)-2400000.5d)[0]

mjdrefi=sxpar(hdr,'MJDREFI')
utcfinit=sxpar(hdr,'UTCFINIT')

mjd=mjdrefi + (lc.time+utcfinit)/86400.
tstarts=(mjd-burstmjd)*86400.
tstops=shift(tstarts,-1)
tstops[n_elements(tstops)-1] = tstops[n_elements(tstops)-2]+1
tmid=(tstops+tstarts)/2.
terr=(tstops-tstarts)/2.

ploterror,tmid,lc.rate,terr,lc.error,xrange=xrange,psym=1,title=title,_extra=e

if (isps) then endplot

return
end
