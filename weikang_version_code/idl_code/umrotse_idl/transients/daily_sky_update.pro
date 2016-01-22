pro daily_sky_update,matchdir=matchdir,templatedir=templatedir, $
                     simtransdir=simtransdir,output=output, $
                     simtrans_nstruct=simtrans_nstruct, simtrans_ntrans=simtrans_ntrans
                     

;;if n_params() eq 0 then begin
    ;; *************
;;    print,'syntax- daily_sky_update,matchdir=matchdir,simtrans_nstruct=simtrans_nstruct,simtrans_ntrans=simtrans_ntrans,templatedir=templatedir'
;;    return
;;endif

if n_elements(matchdir) eq 0 then matchdir = '/rotse/data/rotse3/match'
if n_elements(templatedir) eq 0 then templatedir = '/rotse/data/pipeline/templates'
if n_elements(simtransdir) eq 0 then simtransdir = '/rotse/data/pipeline/simtrans'

if n_elements(simtrans_nstruct) eq 0 then simtrans_nstruct = 5
if n_elements(simtrans_ntrans) eq 0 then simtrans_ntrans = 20

;; we need the recently updated matchfiles
allmatchlong=findfile('-lt ' + matchdir + '/*match.fit',count=nallmatch)

if (nallmatch eq 0) then begin
    print,'Could not find any match structures'
    return
endif

spawn,'date',dateres
parts=strsplit(dateres,' ',/extract)
monstr=parts[1]
day=long(parts[2])
timestr=parts[3]
year=long(parts[5])

date_to_jd,monstr,day,year,timestr,nowjd,fail=fail
;;nowjd = systime(/julian)

if (fail) then begin
    print,'could not get current date'
    return
endif

usematch = bytarr(nallmatch)
allmatchnames=strarr(nallmatch)

for i=0l,nallmatch-1 do begin
    parts=strsplit(allmatchlong[i],' ',/extract)
    allmatchnames[i] = parts[n_elements(parts)-1]
    monstr = parts[5]
    day=long(parts[6])
    yearortime=parts[7]
    date_to_jd,monstr,day,year,yearortime,fjd,fail=fail
    
    if ((nowjd - fjd) lt 1.0) then begin
        usematch[i] = 1
    endif
endfor

use=where(usematch eq 1, uct)

if (uct eq 0) then begin
    print,'No match structures updated recently.'
    return
endif

;; and compile the list of matchfiles
matchfiles = allmatchnames[use]

;; for each of these matchfiles, we want to update the templates and update
;; the history (when available)

matchfortransarr=bytarr(n_elements(matchfiles))

elt=create_struct('matchname','', $
                  'addcount',0l, $
                  'addfile',strarr(10), $
                  'mlims',fltarr(10), $
                  'times',fltarr(10))

addfiles=replicate(elt,n_elements(matchfiles))


for i=0l,n_elements(matchfiles)-1 do begin
    addfiles[i].matchname = matchfiles[i]

    ;;mt=mrdfits(matchfiles[i],1)

    ;; work with the templates
    mt=mrdfits(matchfiles[i],1)
    st=mrdfits(matchfiles[i],2)

    parts=strsplit(st[n_elements(st)-1].fname,'_',/extract)
    lastdate = parts[0]

    useim=bytarr(n_elements(st))
    for j=long(n_elements(st)-1),0,-1 do begin
        ;; start at the end; kick out when we have a non-match
        parts=strsplit(st[j].fname,'_',/extract)
        if (parts[0] eq lastdate) then useim[j] = 1 else j = 0l
    endfor

    use=where(useim eq 1,uct)
    addfiles[i].addcount = uct
    if (uct gt 0) then begin
  ;;      update_template_images,templatedir,st[use].fname
        if uct gt 10 then umax = 10-1 else umax = uct-1
        addfiles[i].addfile[0:umax] = st[use[0:umax]].fname
;;        addfiles[i].mlims[0:umax] = st[use[0:umax]].m_lim
        addfiles[i].mlims[0:umax] = mt.m_lim[use[0:umax]]
        addfiles[i].times[0:umax] = float((st[use[0:umax]].mjd - st[use[0]].mjd)*24.*60.)
    endif

    if (uct ge 4) then matchfortransarr[i] = 1

endfor

;; now we need to select the match structures for simtrans
h=where(matchfortransarr eq 1,hct)
if (hct gt 0) then begin
    matchfortrans = matchfiles[h]

    ;; we want to record the number of match structures here...
    dirparts=strsplit(addfiles[0].addfile[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    numfname = simtransdir + '/match_count_'+parts[0]+'.txt'
    openw,lun,numfname,/get_lun
    for i=0l,n_elements(matchfortrans)-1 do begin
;;        printf,lun,matchfortrans[i],addfiles[h[i]].addcount
        line = matchfortrans[i] + ' '
        for k=0l,addfiles[h[i]].addcount-1 do begin
            line = line + string(addfiles[h[i]].times[k],format='(f6.2)') + $
              ' ' + string(addfiles[h[i]].mlims[k],format='(f6.2)') + ' '
        endfor
;;        print,lun,matchfortrans[i],
        printf,lun,line
    endfor
    free_lun,lun
endif else begin
    print,'no structures have >= 4 new observations'
    return
endelse

usesimtrans=bytarr(n_elements(matchfortrans))

if (n_elements(matchfortrans) le simtrans_nstruct) then begin
    ;; do them all
    usesimtrans[*] = 1
endif else begin
    seed = long(systime(/seconds))
    repeat begin
        val=long((randomu(seed,1) * n_elements(matchfortrans)))
        usesimtrans[val] = 1        
        h=where(usesimtrans eq 1,hct)
    endrep until (hct eq simtrans_nstruct)
endelse

use=where(usesimtrans eq 1,uct)
if (uct eq 0) then begin
    print,'no match files for simtrans'
    return
endif

simmatch = matchfortrans[use]


;; do the simulated transients
;;for i=0l,n_elements(simmatch)-1 do begin
;;    simtrans_generate,simtransdir,simmatch[i],simtrans_ntrans,output=output,templatedir=templatedir
;;endfor
print,'Simulated transients turned off.'

;; now we can update the templates and history

for i=0l,n_elements(addfiles)-1 do begin
    update_template_images,templatedir,addfiles[i].addfile[0:addfiles[i].addcount-1]   
endfor

;; and do history update here
for i=0l,n_elements(matchfiles)-1 do begin
    update_sky_history,templatedir,matchfiles[i]
endfor
 

return
end
