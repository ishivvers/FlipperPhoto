pro xrt_check_rate,evtfile,gtifile,norb=norb

if n_params() eq 0 then begin
    print,'syntax- xrt_check_rate,evtfile,gtifile,norb=norb'
    return
end

evt=mrdfits(evtfile,1)
gti=mrdfits(evtfile,2)
orbgti=mrdfits(gtifile,1)

totorb=n_elements(orbgti)
if n_elements(norb) eq 0 then norb = 1000
if (norb gt totorb) then norb=totorb


for i=0l,norb-1 do begin
    in=where(evt.time ge orbgti[i].start and evt.time lt orbgti[i].stop,nin)
    gtin=where(gti.start ge orbgti[i].start and gti.stop le orbgti[i].stop,ngtin)

    if (ngtin eq 0) then begin
        print,'orbit: ',i,' rate: ',0.0
    endif else begin
        totcts=nin
        tottime=total(gti[gtin].stop - gti[gtin].start)

        print,'orbit: ',i,' rate: ',totcts/tottime
    endelse


endfor






return
end
