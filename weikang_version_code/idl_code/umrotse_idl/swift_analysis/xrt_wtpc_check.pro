pro xrt_wtpc_check,datfile,wtevt,pcevt,xrange=xrange

if n_params() eq 0 then begin
    print,'syntax- xrt_wtpc_check,datfile,wtevt,pcevt,xrange=xrange'
    return
endif

readcol,datfile,year,month,day,hour,minute,second,format='i,i,i,i,i,f',/silent
burstmjd = (julday(month,day,year,hour,minute,second)-2400000.5d)[0]

hdr=headfits(wtevt,exten=1)


mjdrefi = sxpar(hdr,'MJDREFI')
utcfinit = sxpar(hdr,'UTCFINIT')


wtgti=mrdfits(wtevt,2)
pcgti=mrdfits(pcevt,2)


wtstart=(mjdrefi+(wtgti.start+utcfinit)/86400.-burstmjd)*86400.
wtstop=(mjdrefi+(wtgti.stop+utcfinit)/86400.-burstmjd)*86400.
pcstart=(mjdrefi+(pcgti.start+utcfinit)/86400.-burstmjd)*86400.
pcstop=(mjdrefi+(pcgti.stop+utcfinit)/86400.-burstmjd)*86400.

if n_elements(xrange) ne 2 then xrange=[10,1000]

plot,[0],[0],/nodata,xrange=xrange,yrange=[-0.5,0.5],/ystyle

for i=0l,n_elements(wtstart)-1 do begin
;;    if (wtstart[i] gt xrange[0] and wtstop[i] lt xrange[1]) then begin
        plots,wtstart[i],-0.4,color=255L
        plots,wtstop[i],-0.4,color=255L,/continue,thick=10
;;    endif
endfor

for i=0l,n_elements(pcstart)-1 do begin
  ;;  if (pcstart[i] gt xrange[0] and pcstop[i] lt xrange[1]) then begin
    plots,pcstart[i],-0.4,color=255L*256L
    plots,pcstop[i],-0.4,color=255L*256L,/continue,thick=10
 ;;   endif
endfor





return
end
