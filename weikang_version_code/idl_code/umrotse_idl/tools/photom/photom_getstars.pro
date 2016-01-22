pro photom_getstars,ucat,ra,dec,radius,compindex

if n_params() eq 0 then begin
    print,'syntax- photom_getstars,ucat,ra,dec,radius,compindex'
    return
endif

compindex=-1

usno1m = 0
if tag_exist(ucat,'VMAG') then usno1m = 1

if usno1m then begin
    gdstars = where(ucat.vmag gt 13.5 and ucat.rmag gt 0 and ucat.rmag lt 17.0, ngood)
endif else begin
    gdstars = where(ucat.rmag gt 13.0 and ucat.rmag lt 15.0, ngood)
endelse

if ngood eq 0 then begin
    print,'We have a problem: too few stars???'
    return
endif

gcirc,1,ra/15.,dec,ucat[gdstars].ra/15.,ucat[gdstars].dec,sep

sort=sort(sep)

compstars = where(sep lt radius*3600.,ncomp)

if ncomp eq 0 then begin
    print,'Problem: no close stars????'
    return
endif

compindex = gdstars[compstars]

return
end
