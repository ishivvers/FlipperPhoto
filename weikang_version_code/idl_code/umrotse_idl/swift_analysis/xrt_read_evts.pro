pro xrt_read_evts,srcevts,evt,gti,orbgti,mode,tstart,tstop,gtifile=gtifile,fail=fail

if n_params() eq 0 then begin
    print,'syntax- xrt_read_evts,srcevts,evt,gti,orbgti,mode,tstart,tstop,gtifile=gtifile,fail=fail'
    return
endif

fail=0

readgti=1
if n_elements(gtifile) ne 0 then begin
    orbgti=mrdfits(gtifile,1)
    readgti=0
endif

;; need to sort the evtfiles
tstarts=lonarr(n_elements(srcevts))
tstops=tstarts
for i=0l,n_elements(srcevts)-1 do begin
    parts=strsplit(srcevts[i],'-',/extract)
    tstarts[i]=long(parts[2])
    tstops[i]=long(parts[3])
    mode=parts[0]
endfor

st=sort(tstarts)

srcevts=srcevts[st]
tstarts=tstarts[st]
tstops=tstops[st]

tstart=1e20
tstop=-1e20

readone=0
for i=0l,n_elements(srcevts)-1 do begin
 
    one_evt=mrdfits(srcevts[i],1)
    if (n_elements(one_evt) gt 1) then begin
        readone=1

        if (tstarts[i] lt tstart) then tstart=tstarts[i]
        if (tstops[i] gt tstop) then tstop=tstops[i]
        
        add_arrval,one_evt,tempevt

        one_gti=mrdfits(srcevts[i],2)
        add_arrval,one_gti,tempgti

        if (readgti) then begin
            hdr=headfits(srcevts[i],exten=1)
            infiles=sxpar(hdr,'FILIN*')
            test=findfile(strmid(infiles[0],0,13)+'*clgti.fits',count=ct)
            if (ct eq 0) then begin
                print,'No gtifile found'
            endif else begin
                one_orbgti=mrdfits(test[0],1)
                add_arrval,one_orbgti,temporbgti
            endelse
;;            help,one_orbgti
        endif

    endif 
endfor

if (not readone) then begin
    print,'could not read any evts'
    fail=1
    return
endif

evt=tempevt
gti=tempgti
if (readgti and n_elements(temporbgti) gt 0) then orbgti=temporbgti


return
end
