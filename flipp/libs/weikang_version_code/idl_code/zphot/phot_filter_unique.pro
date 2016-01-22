FUNCTION phot_filter_unique,filters,reversesort=reversesort

if n_params() eq 0 then begin
  print,'Syntax- phot_filter_unique,filters'
  return,''
endif

;;not blank is also a filter in this procedure
allfilters=strtrim(filters,2)
;;uniq filters
allfilters=allfilters[UNIQ(allfilters, SORT(allfilters))]
;;Tricky, try to sort the filters
;;this can be manuallly updated if you have more filters
knownfilter=['U','B','V','R','CLEAR','clear','I','X','x','']

indfilter=fltarr(n_elements(allfilters))+n_elements(allfilters)
for i=0,n_elements(allfilters)-1 do begin
  indf=where(knownfilter eq allfilters[i], nf)
  if nf ne 0 then indfilter[i]=indf
endfor
indf=sort(indfilter)
allfilters=allfilters[indf]
;print,allfilters

if keyword_set(reversesort) then begin
  ind=reverse(indgen(n_elements(allfilters)))
  allfilters=allfilters[ind]
endif

return,allfilters

end
