;  extract_usno_db
;
;    This program extracts the stars from a usno database created with
;      make_usno_dbs/build_usno_db2.  It will give all the stars in
;      a square with the given radius, plus extra stars in the triangles
;      extracted.
;
;  10-01: Eli Rykoff
;







pro extract_usno_db,rac,decc,radius,cat,basename=basename

if n_params() eq 0 then begin
    print,'Syntax - extrac_usno_db, rac, decc, radius, cat, basename = basename'
    return
endif

; Run Rotse_setup

rotse_setup

if (not keyword_set(basename)) then basename = !usno_dbname

; Set up the catalogue

t=systime(1)

item = create_struct('ra', 0d, 'dec', 0d, 'rmag', 0.0, 'bmag', 0.0)
names = 'ra,dec,rmag,bmag'
cat = 0
startcat = 0

ext_radius = sqrt(2) * radius

; First find the leaf ids at both levels

htmIntersectRadec, double(rac), double(decc), double(ext_radius), $
                   !usno_db_leaf_depth, dbid_list

htmIntersectRadec, double(rac), double(decc), double(ext_radius), $
                   !usno_leaf_depth, leafid_list

for i=0l,n_elements(dbid_list)-1 do begin
   dbname = basename + '_' + string(strtrim(dbid_list[i],2))
   dbopen, dbname,0
   for j=0l,n_elements(leafid_list)-1 do begin
      cond = 'leaf_id = '+string(leafid_list[j])
      temp_ids = dbfind(cond, count=count, /silent)
      if (count ne 0) then begin
         add_arrval, temp_ids, ids
      endif
   endfor

   if (n_elements(ids) gt 0) then begin
     dbext,ids,names,ra_long,dec_long,rmag_int,bmag_int

     temp_cat = replicate(item, n_elements(ids))

     temp_cat.ra = double(ra_long) / (3600d * 100d)
     temp_cat.dec = double(dec_long) / (3600d * 100d) - 90d
     temp_cat.rmag = float(rmag_int) / 10.0
     temp_cat.bmag = float(bmag_int) / 10.0

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



;if n_elements(cat) gt 0 then begin
;   print,'Found ',n_elements(cat),' stars in the triangles'
;
;   close_match_radec,rac,decc,cat.ra,cat.dec,m1,m2,radius,n_elements(cat),/silent
;   if (m2[0] ne -1) then begin
;       cat = cat[m2]
;   endif else begin
;       cat = 0
;       endelse
;endif

print,systime(1)-t

return
end
