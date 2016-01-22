pro zphot_dat_res_to_snpy,datafile

if n_params() eq 0 then begin
  print,'Syntax- zphot_dat_res_to_snpy,datafile'
  return
endif

zphot_dat_res_format,datafile,photst
ind=where(photst.emag le 10.0,fb)
if fb le 0 then begin
  print,'No good data, doing nothing'
  return
endif

ind=sort(photst.TIME)
photst=photst[ind]
nimages=n_elements(photst)
;;get all the filters
allfilters=photst.filter
allfilters=strtrim(allfilters,2)
;;uniq filters
allfilters=allfilters[UNIQ(allfilters, SORT(allfilters))]
filternumber=n_elements(allfilters)
;print,'Filters found in all the data :'
;print,allfilters

print,'SN20XXXX  zzzzz   ra      dec'
for i=0,filternumber-1 do begin
  ind=where(photst.filter eq allfilters[i],nf)
  if nf gt 0 then begin
    print,'filter',' ',allfilters[i]
    for j=0,nf-1 do begin
      print,photst[ind[j]].TIME,photst[ind[j]].MAG,photst[ind[j]].EMAG,format='(f15.5,f9.3,f9.3)'
    endfor
  endif
endfor


;if keyword_set(save_data) then begin
;    openw,lun,save_data,/get_lun
;    printf,lun,';; '+xtitle+'    etburst       mag        -emag       +emag      limmag  filter   imagename'
;    for i=0,n_elements(x)-1 do begin
;        printf,lun,x[i],ex[i],mag[i],memag[i],pemag[i],limmag[i],' '+filters[i]+' ',imnames[i],format='(f16.6,f12.5,f12.5,f12.5,f12.5,f12.5,a0,a0)'
;    endfor
;    close,lun
;    free_lun,lun
;endif


end
