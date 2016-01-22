pro find_new_objects,templatedir,mt,nconsec,obj,maxtime=maxtime,magcut=magcut,appendobs=appendobs,above_m_lim=above_m_lim,matchrad=matchrad,mintime=mintime

if n_params() eq 0 then begin
    print,'syntax- find_new_objects,templatedir,mt,nconsec,obj,maxtime=maxtime,magcut=magcut,appendobs=appendobs,above_m_lim=above_m_lim,matchrad=matchrad,mintime=mintime'
    return
endif

if n_elements(maxtime) eq 0 then maxtime = 12./24.
if n_elements(magcut) eq 0 then magcut = 18.0
if n_elements(above_m_lim) eq 0 then above_m_lim = 0.25
if n_elements(appendobs) eq 0 then appendobs = indgen(mt.nobs)
if n_elements(matchrad) eq 0 then matchrad = 5d * 0.0009d
if n_elements(mintime) eq 0 then mintime = 10. ;; minutes

;; default: no objects
obj = -1

;; load in the history...if there is none, then no objects pass the cut
parts=strsplit(mt.imagename[0],'_',/extract)
histname = templatedir + '/history/' + parts[1] + '_' + strmid(parts[2],0,2) + '_history.fit'

hstr = mrdfits(histname,1,hhdr,status = status)
if (status ne 0) then begin
    print,'Could not find history file: ',histname
    print,'Cannot look for transients.'
    return
endif

hra_low = sxpar(hhdr,'RA_LOW')
hra_high = sxpar(hhdr,'RA_HIGH')
hdec_low = sxpar(hhdr,'DEC_LOW')
hdec_high = sxpar(hhdr,'DEC_HIGH')
hm_lim = sxpar(hhdr,'M_LIM')

;; only consider objects that are in range
allobj = lindgen(mt.nobj)
allobs = lindgen(mt.nobs)
inrange = where((mt.ra[allobj] gt hra_low) and $
                (mt.ra[allobj] lt hra_high) and $
                (mt.dec[allobj] gt hdec_low) and $
                (mt.dec[allobj] lt hdec_high) and $
                (mt.mavg[allobj] lt (hm_lim - above_m_lim)),ninrange)

if (ninrange eq 0) then begin
    print,'No objects in range'
    return
endif

close_match_radec,mt.ra[inrange],mt.dec[inrange],hstr.ra,hstr.dec, $
  m1,m2,matchrad,1,miss;,/silent

if (miss[0] eq -1) then begin
    print,'No misses'
    return
endif

misses = inrange[miss]

newobj_arr = bytarr(mt.nobj)

for i=0l,n_elements(misses)-1 do begin
    obj = misses[i]

    gdobs = where((mt.m[allobs,obj] gt 0.0) and (mt.m[allobs,obj] lt 30.0),ngd)

    if (ngd ge nconsec) then begin
        ;; check if it's already been output
        if (check_flags3('CROPJPG',type='RFLAGS',mt.rflags[0,obj]) eq 0) then begin

            ;; this trick finds if they're consecutive
            if min(gdobs eq (indgen(ngd) + min(gdobs))) then begin
                match,appendobs,gdobs,suba,subb,count=count
                if (count gt 0) then begin
                    ;; we have the requisite # of consecutive observations
                    delta_t = max(mt.jd[gdobs]) - min(mt.jd[gdobs])
                    bright = min(mt.m[gdobs,obj])
                    if (delta_t lt maxtime) and (bright lt magcut) and $
                      (delta_t gt mintime*60./86400.) then $
                      newobj_arr[obj] = 1
                endif
            endif
        endif
    endif
endfor

obj = where(newobj_arr eq 1,nobj)
if (nobj eq 0) then obj = -1


return
end
