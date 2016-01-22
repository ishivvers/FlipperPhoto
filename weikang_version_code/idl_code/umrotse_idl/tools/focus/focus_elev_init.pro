pro focus_elev_init,hdrlist,best,elev_arr,hdr_ending

if n_params() eq 0 then begin
    print,'syntax- focus_elev_init,hdrlist,best,elev_arr,hdr_ending'
    return
endif

elt = create_struct('file','','best_focus',0.0,'error',0.0,'temp',0.0,'elev',0.0,'az',0.0)

openr, lun, hdrlist, /get_lun
n=0
name=''
while not eof(lun) do begin
    readf,lun,name,format='(a100)'
    info=str_sep(name," ")
    name = info(0)
    
    if (strpos(name,'001_') ne -1) or (strpos(name,'001.') ne -1) then n=n+1

endwhile

free_lun,lun

parts=str_sep(name,'_')
hdr_ending=''
for i=3,n_elements(parts)-1 do begin
    hdr_ending = hdr_ending + '_' + parts[i]
endfor


best=replicate(elt, n)


openr, lun, hdrlist, /get_lun
i=0
name=''
while not eof(lun) do begin
    readf,lun,name,format='(a100)'
    info=str_sep(name," ")
    name = info(0)

    if (strpos(name,'001_') ne -1) or (strpos(name,'001.') ne -1) then begin

        dirparts = str_sep(name,"/")
        nparts = n_elements(dirparts)

        parts=str_sep(dirparts[nparts-1],'_')
        
        best[i].file = parts[0] + '_' + parts[1] + '_' + strmid(parts[2],0,2)
        
        hdr=headfits(name)
        best[i].elev = sxpar(hdr, 'ELEV')
        best[i].az = sxpar(hdr,'AZIMUTH')
        best[i].temp = sxpar(hdr,'TEMPOUT')

        i=i+1
    endif
endwhile


hist=histogram(best.elev,omin=omin,omax=omax)
h=where(hist ge 3)   ; will need three points for a line

elev_arr = h + omin


return
end
