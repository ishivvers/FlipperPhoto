pro xrt_print_orbits,datfile,gtifile

if n_params() eq 0 then begin
    print,'syntax- xrt_print_orbits,datfile,gtifile'
    return
endif

readcol,datfile,year,month,day,hour,minute,second,format='i,i,i,i,i,f',/silent
burstmjd = (julday(month,day,year,hour,minute,second)-2400000.5d)[0]

hdr=headfits(gtifile,exten=1)
gti=mrdfits(gtifile,1)

mjdrefi = sxpar(hdr,'MJDREFI')
utcfinit = sxpar(hdr,'UTCFINIT')

tottime=0d

print,'Start (s)       ','Stop (s)'
for i=0l,n_elements(gti)-1 do begin
    start=(mjdrefi+(gti[i].start + utcfinit)/86400. - burstmjd)*86400.
    stop =(mjdrefi+(gti[i].stop + utcfinit)/86400. - burstmjd)*86400.

    print,start,stop,format='(2f14.2)'

    tottime=tottime+(stop-start)
endfor

print,'total time: ',tottime




return
end
