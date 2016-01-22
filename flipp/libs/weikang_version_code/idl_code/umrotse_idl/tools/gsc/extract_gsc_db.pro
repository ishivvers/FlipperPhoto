pro extract_gsc_db,rac,decc,radius,cat,basename=basename

if n_params() eq 0 then begin
    print,'Syntax - extract_gsc_db, rac, decc, radius, cat, basename = basename'
    return
endif

rotse_setup

if (not keyword_set(basename)) then basename = !gsc_dbname

t=systime(1)

item = create_struct('ra', 0d, 'dec', 0d, 'mag', 0.0)
names = 'ra,dec,mag'
cat = 0
startcat = 0

htmIntersectRadec, double(rac), double(decc), double(radius), $
  !usno_db_leaf_depth, dbid_list

htmIntersectRadec, double(rac), double(decc), double(radius), $
  !usno_leaf_depth, leafid_list

for i=0l,n_elements(dbid_list)-1 do begin
    dbname = basename + '_' + string(strtrim(dbid_list[i],2))
  
    dbopen, dbname, 0
    for j=0l, n_elements(leafid_list)-1 do begin
        cond = 'leaf_id = '+string(leafid_list[j])
        temp_ids = dbfind(cond, count=count, /silent)
        if (count ne 0) then begin
            add_arrval, temp_ids, ids
        endif
    endfor
    
  if (n_elements(ids) gt 0) then begin
     dbext,ids,names,ra_long,dec_long,mag_int

     temp_cat = replicate(item, n_elements(ids))

     temp_cat.ra = double(ra_long) / (3600d * 100d)
     temp_cat.dec = double(dec_long) / (3600d * 100d) - 90d
     temp_cat.mag = float(mag_int) / 100.0

     if (startcat eq 0) then begin
        cat = temp_cat
        startcat = 1
     endif else begin
        concat_structs,temporary(cat),temporary(temp_cat),temp
        cat = temp
     endelse
   endif
   dbclose
   ids = 0

endfor


d2r = !dpi / 180d

if n_elements(cat) gt 0 then begin
   print,'Found ',n_elements(cat),' stars in the triangles'

   gcirc, 0, rac * d2r, decc * d2r, cat.ra * d2r, cat.dec * d2r, dis
   m1 = where(dis lt radius * d2r, count)
   print,'Found ',count, ' stars in the circle'
   if (count gt 0) then begin
      cat = cat[m1]
   endif else begin
      cat = 0
   endelse
endif

print,systime(1)-t

return
end
