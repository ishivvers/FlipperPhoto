pro make_xrt_gti,gtifile,rotsefile,tstart,tstop

if n_params() eq 0 then begin
    print,'syntax- make_xrt_gti,gtifile,rotsefile,tstart,tstop'
    return
endif

gti=mrdfits(gtifile,1)
hdr=headfits(gtifile)
hdr1=headfits(gtifile,exten=1)

readcol,rotsefile,year,month,day,hour,minute,second,format='i,i,i,i,i,f',/silent
burstmjd=(julday(month,day,year,hour,minute,second)-2400000.5d)[0]

mjdrefi=sxpar(hdr,'MJDREFI')
utcfinit=sxpar(hdr,'UTCFINIT')


mjdstart = burstmjd + double(tstart)/86400d
mjdstop = burstmjd + double(tstop)/86400d

scstart = (mjdstart - mjdrefi)*86400d - utcfinit
scstop = (mjdstop - mjdrefi)*86400d - utcfinit

if (gti[0].start gt scstart) then begin
    tstart = tstart + (gti[0].start - scstart)
    print,'First time > than gti start; resetting to ',tstart
    scstart = gti[0].start
endif

if (gti[n_elements(gti)-1].stop lt scstop) then begin
    tstop = tstop + (gti[n_elements(gti)-1].stop - scstop)
    print,'Last time > than gti stop; resetting to ',tstop
    scstop = gti[n_elements(gti)-1].stop
endif


parts=strsplit(gtifile,'_',/extract)
if (long(tstop) ge 10000000l) then begin
    outfile=parts[0] + '_' + string(long(tstart),format='(i9.9)') + '_' + $
      string(long(tstop),format='(i9.9)') + '_gti.fits'
endif else if (long(tstop) ge 100000l) then begin    
    outfile=parts[0] + '_' + string(long(tstart),format='(i7.7)') + '_' + $
      string(long(tstop),format='(i7.7)') + '_gti.fits'
endif else begin
    outfile=parts[0] + '_' + string(long(tstart),format='(i5.5)') + '_' + $
      string(long(tstop),format='(i5.5)') + '_gti.fits'
endelse

newgti=gti[0]
newgti.start = scstart
newgti.stop = scstop


mwrfits,newgti,outfile,hdr1,/create

print,'OUTFILE: ',outfile

return
end
